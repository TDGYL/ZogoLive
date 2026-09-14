import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/models/g5_match_model.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_network_manager.dart';

class PostMatchSearchPage extends G5BaseViewController {
  const PostMatchSearchPage({Key? key}) : super(key: key);

  @override
  State<PostMatchSearchPage> createState() => _PostMatchSearchPageState();
}

class _PostMatchSearchPageState extends G5BaseViewState<PostMatchSearchPage> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
  );

  List<G5MatchItem> _searchMatches = [];
  List<G5MatchItem> _hotMatches = [];
  bool _isSearchLoading = false;
  bool _isHotLoading = true;
  String _searchKeyword = '';

  @override
  void initData() {
    super.initData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchHotData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchHotData() async {
    setState(() {
      _isHotLoading = true;
    });

    final response = await G5NetworkManager().get(
      '/api/livespeed/index/search/match/hot',
    );

    if (response.isSuccess) {
      List<dynamic> rawData = [];
      if (response.data is List) {
        rawData = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        rawData = response.data['data'] as List<dynamic>;
      }

      final newItems = rawData
          .map((json) => _parseSearchMatch(json as Map<String, dynamic>))
          .where((match) => match.categoryId == 1)
          .toList();

      setState(() {
        _hotMatches = newItems;
        _isHotLoading = false;
      });
    } else {
      setState(() {
        _isHotLoading = false;
      });
    }
  }

  Future<void> _fetchSearchData(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchMatches = [];
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    final response = await G5NetworkManager().get(
      '/api/livespeed/index/search',
      queryParameters: {'text': keyword.trim()},
    );

    if (response.isSuccess) {
      List<dynamic> rawData = [];
      final Map<String, dynamic>? dataObj =
          response.data as Map<String, dynamic>?;
      if (dataObj != null && dataObj['matches'] != null) {
        rawData = dataObj['matches'] as List<dynamic>;
      }

      final newItems = rawData
          .map((json) => _parseSearchMatch(json as Map<String, dynamic>))
          .where((match) => match.categoryId == 1)
          .toList();

      setState(() {
        _searchMatches = newItems;
        _isSearchLoading = false;
      });
    } else {
      setState(() {
        _isSearchLoading = false;
      });
    }
  }

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
        'Select Match',
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: G5Colors.pitchElevated,
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _searchKeyword = val.trim();
                  _fetchSearchData(_searchKeyword);
                }
              },
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: 'Search team name...',
                hintStyle:
                    TextStyle(color: G5Colors.textSecondary, fontSize: 12),
                prefixIcon:
                    Icon(Icons.search, color: G5Colors.textSecondary, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                _searchKeyword = val;
                if (val.isEmpty) {
                  setState(() {
                    _searchMatches = [];
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(G5MatchItem match) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(match);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: G5Colors.pitch,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return EasyRefresh(
      controller: _refreshController,
      header: const ClassicHeader(
        dragText: 'Pull to refresh',
        armedText: 'Release to refresh',
        readyText: 'Refreshing...',
        processingText: 'Refreshing...',
        processedText: 'Refreshed',
        failedText: 'Refresh failed',
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
      ),
      onRefresh: () async {
        await _fetchHotData();
        if (_searchKeyword.isNotEmpty) {
          await _fetchSearchData(_searchKeyword);
        }
        _refreshController.finishRefresh(IndicatorResult.success);
      },
      child: CustomScrollView(
        slivers: [
          // ================= 第一段：全部（搜索结果） =================
          if (_searchKeyword.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SectionHeaderDelegate('All (Results)'),
            ),
          if (_searchKeyword.isNotEmpty && _isSearchLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child:
                      CircularProgressIndicator(color: G5Colors.accentEmerald),
                ),
              ),
            ),
          if (_searchKeyword.isNotEmpty &&
              !_isSearchLoading &&
              _searchMatches.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text('No search data',
                      style: TextStyle(color: G5Colors.textSecondary)),
                ),
              ),
            ),
          if (_searchKeyword.isNotEmpty &&
              !_isSearchLoading &&
              _searchMatches.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMatchCard(_searchMatches[index]),
                childCount: _searchMatches.length,
              ),
            ),

          // ================= 第二段：Trending =================
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate('Trending'),
          ),
          if (_isHotLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child:
                      CircularProgressIndicator(color: G5Colors.accentEmerald),
                ),
              ),
            ),
          if (!_isHotLoading && _hotMatches.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text('No trending data',
                      style: TextStyle(color: G5Colors.textSecondary)),
                ),
              ),
            ),
          if (!_isHotLoading && _hotMatches.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMatchCard(_hotMatches[index]),
                childCount: _hotMatches.length,
              ),
            ),

          // 底部留白
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          )
        ],
      ),
    );
  }
}

// 模拟 iOS TableView 的吸顶 Section Header
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _SectionHeaderDelegate(this.title);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: G5Colors.pitch.withOpacity(0.95), // 半透明效果，类似于 iOS 磨砂
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 44.0;

  @override
  double get minExtent => 44.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is _SectionHeaderDelegate && oldDelegate.title != title;
  }
}
