import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/pages/football_detail_page.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

/// 我关注的比赛列表页
/// 数据来源：POST /api/livespeed/football/matches（tab固定=4）
/// 支持下拉刷新和上拉加载
class MyMatchesPage extends G5BaseViewController {
  const MyMatchesPage({Key? key}) : super(key: key);

  @override
  State<MyMatchesPage> createState() => _MyMatchesPageState();
}

class _MyMatchesPageState extends G5BaseViewState<MyMatchesPage> {
  /// 刷新控制器 - EasyRefreshController类型，控制下拉刷新/上拉加载
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  /// 比赛列表数据 - List<G5MatchItem>类型，关注比赛列表
  List<G5MatchItem> matches = [];

  /// 当前页码 - int类型，下拉刷新重置为1，上拉加载递增
  int _page = 1;

  /// 每页条数 - int类型，固定10条
  final int _size = 10;

  @override
  void initState() {
    super.initState();
    // 使用 WidgetsBinding 确保在第一帧渲染完成后再触发下拉刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshController.callRefresh();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 请求关注比赛列表数据
  /// 接口：POST /api/livespeed/football/matches
  /// 参数：tab固定=4，page页码，size=10，timestamp当天时间戳，competition_ids空数组
  /// 参数：isRefresh - bool类型，true下拉刷新（page=1），false上拉加载（page+1）
  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _page = 1;
    } else {
      _page++;
    }

    // 当天时间戳（秒）
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final params = {
      "tab": 4,
      "page": _page,
      "size": _size,
      "timestamp": timestamp,
      "competition_ids": []
    };

    try {
      final response = await G5NetworkManager().post(
        '/api/livespeed/football/matches',
        data: params,
      );

      if (response.isSuccess) {
        final data = G5MatchData.fromJson(response.data);
        final newItems = data.results ?? [];

        if (mounted) {
          setState(() {
            if (isRefresh) {
              matches = newItems;
            } else {
              matches.addAll(newItems);
            }
          });
        }

        if (isRefresh) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? '加载失败，请稍后重试'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (isRefresh) {
        _refreshController.finishRefresh(IndicatorResult.fail);
      } else {
        _refreshController.finishLoad(IndicatorResult.fail);
      }
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: const Text(
        '我关注的比赛',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return EasyRefresh(
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
        messageStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 10),
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
        messageStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 10),
      ),
      onRefresh: () => _fetchData(isRefresh: true),
      onLoad: () => _fetchData(isRefresh: false),
      child: matches.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.sports_soccer,
                    color: G5Colors.textSecondary, size: 48),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    '暂无关注的比赛',
                    style:
                        TextStyle(color: G5Colors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return _buildMatchCard(matches[index]);
              },
            ),
    );
  }

  /// 构建单个比赛卡片
  /// 展示赛事名、开赛时间、主客队队徽队名和比分，点击跳转比赛详情
  /// 参数：match - G5MatchItem类型，比赛数据
  Widget _buildMatchCard(G5MatchItem match) {
    return GestureDetector(
      onTap: () {
        // 跳转比赛详情
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FootballDetailPage(match: match),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: G5Colors.pitchCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: G5Colors.pitchBorder),
        ),
        child: Column(
          children: [
            // 顶行：赛事名 + 开赛时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.competitionName ?? '',
                    style: const TextStyle(
                      color: G5Colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (match.statusName != null &&
                    match.statusName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: G5Colors.pitchElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.statusName ?? '',
                      style: const TextStyle(
                        color: G5Colors.accentEmerald,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 主客队 + 比分
            Row(
              children: [
                // 主队（队名 + 队徽）
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.homeTeamName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (match.homeTeamLogo != null &&
                          match.homeTeamLogo!.isNotEmpty)
                        Image.network(
                          match.homeTeamLogo!,
                          width: 24,
                          height: 24,
                          errorBuilder: (c, e, s) =>
                              const SizedBox(width: 24, height: 24),
                        ),
                    ],
                  ),
                ),
                // 比分 或 VS
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: G5Colors.pitchElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: (match.homeTeamScore != null &&
                          match.awayTeamScore != null)
                      ? Text(
                          '${match.homeTeamScore} - ${match.awayTeamScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Text(
                          'VS',
                          style: TextStyle(
                            color: G5Colors.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                // 客队（队徽 + 队名）
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (match.awayTeamLogo != null &&
                          match.awayTeamLogo!.isNotEmpty)
                        Image.network(
                          match.awayTeamLogo!,
                          width: 24,
                          height: 24,
                          errorBuilder: (c, e, s) =>
                              const SizedBox(width: 24, height: 24),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          match.awayTeamName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
