import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

class PostMatchSearchPage extends G5BaseViewController {
  const PostMatchSearchPage({Key? key}) : super(key: key);

  @override
  State<PostMatchSearchPage> createState() => _PostMatchSearchPageState();
}

class _PostMatchSearchPageState extends G5BaseViewState<PostMatchSearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<G5MatchItem> _matches = [];
  int _page = 1;
  final int _size = 20;
  bool _isFirstLoading = true;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // 切换 Tab 时重置搜索词并刷新
        _searchKeyword = '';
        _refreshController.callRefresh();
      }
    });
  }

  @override
  void initData() {
    super.initData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshController.callRefresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _page = 1;
    } else {
      _page++;
    }

    // “全部”和“热门”使用同一个 GET 接口
    final response = await G5NetworkManager().get(
      '/api/livespeed/index/search/match/hot',
    );

    if (response.isSuccess) {
      final List<dynamic> rawData = response.data ?? [];

      // 解析数据并过滤 category == 1 的足球比赛
      List<G5MatchItem> newItems = rawData
          .map((json) => _parseSearchMatch(json as Map<String, dynamic>))
          .where((match) =>
              match.categoryId ==
              1) // 假设我们把 category 映射到了 categoryId 字段上，或者通过一个特定字段标识，这里我们可以在 _parseSearchMatch 里处理。
          .toList();

      // 简单本地过滤搜索
      if (_searchKeyword.isNotEmpty) {
        newItems = newItems.where((match) {
          final home = match.homeTeamName ?? '';
          final away = match.awayTeamName ?? '';
          return home.contains(_searchKeyword) || away.contains(_searchKeyword);
        }).toList();
      }

      setState(() {
        if (isRefresh) {
          _matches = newItems;
        } else {
          _matches.addAll(newItems);
        }
        if (_isFirstLoading) {
          _isFirstLoading = false;
        }
      });

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
      setState(() {
        if (_isFirstLoading) {
          _isFirstLoading = false;
        }
      });
      if (isRefresh) {
        _refreshController.finishRefresh(IndicatorResult.fail);
      } else {
        _refreshController.finishLoad(IndicatorResult.fail);
      }
    }
  }

  // 手动解析搜索接口返回的字段，映射为 G5MatchItem
  G5MatchItem _parseSearchMatch(Map<String, dynamic> json) {
    return G5MatchItem(
      matchId:
          json['match_id'] != null ? (json['match_id'] as num).toInt() : null,
      matchTime: json['match_time'] != null
          ? (json['match_time'] as num).toInt()
          : null,
      categoryId:
          json['category'] != null ? (json['category'] as num).toInt() : null,
      competitionName: json['competition_name'] as String?,
      homeTeamId: json['home_team_id'] != null
          ? (json['home_team_id'] as num).toInt()
          : null,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: json['home_team_logo'] as String?,
      homeTeamScore: json['home_team_score'] != null
          ? (json['home_team_score'] as num).toInt()
          : null,
      awayTeamId: json['away_team_id'] != null
          ? (json['away_team_id'] as num).toInt()
          : null,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: json['away_team_logo'] as String?,
      awayTeamScore: json['away_team_score'] != null
          ? (json['away_team_score'] as num).toInt()
          : null,
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '选择关联比赛',
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: G5Colors.pitchElevated,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '搜索球队名称...',
                    hintStyle:
                        TextStyle(color: G5Colors.textSecondary, fontSize: 12),
                    prefixIcon: Icon(Icons.search,
                        color: G5Colors.textSecondary, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    _searchKeyword = val;
                    _refreshController.callRefresh();
                  },
                ),
              ),
            ),
            // TabBar
            TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: G5Colors.accentBlue,
              indicatorWeight: 3,
              labelColor: G5Colors.accentBlue,
              unselectedLabelColor: G5Colors.textSecondary,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '全部'),
                Tab(text: '热门'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_isFirstLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }

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
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
      ),
      footer: const ClassicFooter(
        dragText: '上拉加载',
        armedText: '释放加载',
        readyText: '正在加载...',
        processingText: '正在加载...',
        processedText: '加载成功',
        noMoreText: '没有更多数据了',
        failedText: '加载失败',
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
      ),
      onRefresh: () => _fetchData(isRefresh: true),
      onLoad: () => _fetchData(isRefresh: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop(match);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: G5Colors.pitchCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: G5Colors.pitchBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(match.homeTeamName ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        if (match.homeTeamLogo != null &&
                            match.homeTeamLogo!.isNotEmpty)
                          Image.network(match.homeTeamLogo!,
                              width: 24,
                              height: 24,
                              errorBuilder: (c, e, s) =>
                                  const SizedBox(width: 24, height: 24)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: G5Colors.pitchElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('VS',
                        style: TextStyle(
                            color: G5Colors.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (match.awayTeamLogo != null &&
                            match.awayTeamLogo!.isNotEmpty)
                          Image.network(match.awayTeamLogo!,
                              width: 24,
                              height: 24,
                              errorBuilder: (c, e, s) =>
                                  const SizedBox(width: 24, height: 24)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(match.awayTeamName ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
