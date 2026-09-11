import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';
import 'package:zogolive/pages/football_detail_page.dart';

class MatchesPage extends G5BaseViewController {
  const MatchesPage({Key? key}) : super(key: key);

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends G5BaseViewState<MatchesPage> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<String> dates = [];
  List<String> days = [];
  List<int> timestamps = [];
  int selectedDateIndex = 2; // 默认选中今天 (索引2)

  List<G5MatchItem> matches = [];
  int _page = 1;
  final int _size = 10;

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    _generateDateData();
    // 使用 WidgetsBinding 确保在第一帧渲染完成后再触发下拉刷新动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshController.callRefresh();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _generateDateData() {
    final now = DateTime.now();
    for (int i = -2; i <= 2; i++) {
      final targetDate = now.add(Duration(days: i));

      // 生成日期字符串 MM-DD
      final month = targetDate.month.toString().padLeft(2, '0');
      final day = targetDate.day.toString().padLeft(2, '0');
      dates.add('$month-$day');

      // 生成时间戳 (秒)
      timestamps.add(targetDate.millisecondsSinceEpoch ~/ 1000);

      // 生成星期
      if (i == 0) {
        days.add('今天');
      } else if (i == 1) {
        days.add('明天');
      } else if (i == -1) {
        days.add('昨天');
      } else {
        const weekdayMap = {
          1: '周一',
          2: '周二',
          3: '周三',
          4: '周四',
          5: '周五',
          6: '周六',
          7: '周日'
        };
        days.add(weekdayMap[targetDate.weekday] ?? '');
      }
    }
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _page = 1;
    } else {
      _page++;
    }

    final currentTimestamp = timestamps[selectedDateIndex];

    final params = {
      "tab": 0,
      "page": _page,
      "size": _size,
      "timestamp": currentTimestamp,
      "competition_ids": []
    };

    final response = await G5NetworkManager().post(
      '/api/v1/football/matches',
      data: params,
    );

    if (response.isSuccess) {
      final data = G5MatchData.fromJson(response.data);
      final newItems = data.results ?? [];
      print("请求成功---match");
      setState(() {
        if (isRefresh) {
          matches = newItems;
        } else {
          matches.addAll(newItems);
        }
      });

      if (isRefresh) {
        print("请求成功---match-2");
        _refreshController.finishRefresh(IndicatorResult.success);
        _refreshController.resetFooter();
      } else {
        _refreshController.finishLoad(
          newItems.length < _size
              ? IndicatorResult.noMore
              : IndicatorResult.success,
        );
      }
    } else {
      if (isRefresh) {
        _refreshController.finishRefresh(IndicatorResult.fail);
      } else {
        _refreshController.finishLoad(IndicatorResult.fail);
      }
      // 可以添加错误提示 Toast
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: G5Colors.accentEmerald.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: G5Colors.accentEmerald.withOpacity(0.3)),
            ),
            child: const Icon(Icons.emoji_events,
                color: G5Colors.accentEmerald, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '极球·赛事',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '焦点战术对决',
                style: TextStyle(fontSize: 10, color: G5Colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today,
              color: G5Colors.accentEmerald, size: 20),
          onPressed: () {
            _showCalendarDialog(context);
          },
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: EasyRefresh(
            controller: _refreshController,
            header: const ClassicHeader(
              dragText: '下拉刷新',
              armedText: '释放刷新',
              readyText: '正在刷新...',
              processingText: '正在刷新...',
              processedText: '刷新成功',
              noMoreText: '没有更多',
              failedText: '刷新失败',
              messageText: '最后更新于 %T',
              iconTheme: IconThemeData(color: G5Colors.accentEmerald),
              textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
              messageStyle:
                  TextStyle(color: G5Colors.textSecondary, fontSize: 10),
            ),
            footer: const ClassicFooter(
              dragText: '上拉加载',
              armedText: '释放加载',
              readyText: '正在加载...',
              processingText: '正在加载...',
              processedText: '加载成功',
              noMoreText: '没有更多数据了',
              failedText: '加载失败',
              messageText: '最后更新于 %T',
              iconTheme: IconThemeData(color: G5Colors.accentEmerald),
              textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
              messageStyle:
                  TextStyle(color: G5Colors.textSecondary, fontSize: 10),
            ),
            onRefresh: () => _fetchData(isRefresh: true),
            onLoad: () => _fetchData(isRefresh: false),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return _buildMatchCard(matches[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0x99141923),
        border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(dates.length, (index) {
            bool isSelected = selectedDateIndex == index;
            return GestureDetector(
              onTap: () {
                _onDateSelected(index);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? G5Colors.accentEmerald
                      : G5Colors.pitchElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: G5Colors.pitchBorder),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: G5Colors.accentEmerald.withOpacity(0.4),
                              blurRadius: 4)
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.black.withOpacity(0.8)
                            : G5Colors.textSecondary,
                      ),
                    ),
                    Text(
                      dates[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onDateSelected(int index) {
    if (selectedDateIndex != index) {
      setState(() {
        selectedDateIndex = index;
      });
      _refreshController.callRefresh();
    }
  }

  void _showCalendarDialog(BuildContext context) async {
    final now = DateTime.now();
    // 默认可选范围：前后 30 天
    final firstDate = now.subtract(const Duration(days: 30));
    final lastDate = now.add(const Duration(days: 30));

    // 当前选中的日期对象
    DateTime initialDate;
    if (selectedDateIndex >= 0 && selectedDateIndex < timestamps.length) {
      initialDate = DateTime.fromMillisecondsSinceEpoch(
          timestamps[selectedDateIndex] * 1000);
    } else {
      initialDate = now;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: G5Colors
                  .accentEmerald, // Header background color / Selected day color
              onPrimary:
                  Colors.black, // Header text color / Selected day text color
              surface: G5Colors.pitchCard, // Background color
              onSurface: Colors.white, // Text color
            ),
            dialogBackgroundColor: G5Colors.pitchCard,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // 检查选中的日期是否已经在横向列表中
      final pickedMonth = pickedDate.month.toString().padLeft(2, '0');
      final pickedDay = pickedDate.day.toString().padLeft(2, '0');
      final pickedDateStr = '$pickedMonth-$pickedDay';

      int foundIndex = dates.indexOf(pickedDateStr);

      if (foundIndex != -1) {
        // 已经在列表中，直接选中
        _onDateSelected(foundIndex);
      } else {
        // 不在列表中，需要重新生成以选中日期为中心的前后两天列表
        _generateCustomDateData(pickedDate);
        setState(() {
          selectedDateIndex = 2; // 重新生成后，选中的日期始终在中间(索引2)
        });
        _refreshController.callRefresh();
      }
    }
  }

  void _generateCustomDateData(DateTime centerDate) {
    dates.clear();
    days.clear();
    timestamps.clear();

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrowStr =
        '${now.add(const Duration(days: 1)).year}-${now.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}';
    final yesterdayStr =
        '${now.subtract(const Duration(days: 1)).year}-${now.subtract(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.subtract(const Duration(days: 1)).day.toString().padLeft(2, '0')}';

    for (int i = -2; i <= 2; i++) {
      final targetDate = centerDate.add(Duration(days: i));
      final targetDateStr =
          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      // 生成日期字符串 MM-DD
      final month = targetDate.month.toString().padLeft(2, '0');
      final day = targetDate.day.toString().padLeft(2, '0');
      dates.add('$month-$day');

      // 生成时间戳 (秒)
      timestamps.add(targetDate.millisecondsSinceEpoch ~/ 1000);

      // 生成星期
      if (targetDateStr == todayStr) {
        days.add('今天');
      } else if (targetDateStr == tomorrowStr) {
        days.add('明天');
      } else if (targetDateStr == yesterdayStr) {
        days.add('昨天');
      } else {
        const weekdayMap = {
          1: '周一',
          2: '周二',
          3: '周三',
          4: '周四',
          5: '周五',
          6: '周六',
          7: '周日'
        };
        days.add(weekdayMap[targetDate.weekday] ?? '');
      }
    }
  }

  String _formatMatchTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMatchCard(G5MatchItem match) {
    bool isLive = match.statusId == 2 ||
        match.statusId == 3 ||
        match.statusId == 4; // 假设2,3,4为进行中，具体视接口而定

    String statusDisplay = match.statusName ?? '';
    if (isLive && match.minutes != null && match.minutes!.isNotEmpty) {
      statusDisplay = "${match.minutes}' LIVE";
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FootballDetailPage(match: match),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: G5Colors.pitchCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? G5Colors.accentEmerald.withOpacity(0.3)
                : G5Colors.pitchBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: G5Colors.accentEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.competitionName ?? '',
                      style: const TextStyle(
                        color: G5Colors.accentEmerald,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatMatchTime(match.matchTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: G5Colors.accentCrimson.withOpacity(0.2),
                    border: Border.all(
                        color: G5Colors.accentCrimson.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: G5Colors.accentCrimson,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusDisplay,
                        style: const TextStyle(
                          color: G5Colors.accentCrimson,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  statusDisplay,
                  style: const TextStyle(
                    color: G5Colors.accentGold,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const Divider(color: G5Colors.pitchBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                        color: G5Colors.pitchElevated,
                      ),
                      child: match.homeTeamLogo != null &&
                              match.homeTeamLogo!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                match.homeTeamLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.shield,
                                        color: G5Colors.textSecondary,
                                        size: 20),
                              ),
                            )
                          : const Icon(Icons.shield,
                              color: G5Colors.textSecondary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.homeTeamName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (match.statusId != 1) ...[
                      // 假设 1 是未开赛
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${match.homeNormalScore ?? 0}',
                            style: const TextStyle(
                              color: G5Colors.accentEmerald,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            ' - ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${match.awayNormalScore ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (match.note != null && match.note!.isNotEmpty)
                        Text(
                          match.note!,
                          style: const TextStyle(
                            color: G5Colors.accentGold,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ] else
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        match.awayTeamName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                        color: G5Colors.pitchElevated,
                      ),
                      child: match.awayTeamLogo != null &&
                              match.awayTeamLogo!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                match.awayTeamLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.shield,
                                        color: G5Colors.textSecondary,
                                        size: 20),
                              ),
                            )
                          : const Icon(Icons.shield,
                              color: G5Colors.textSecondary, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
