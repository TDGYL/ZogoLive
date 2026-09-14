import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/models/g5_search_result_model.dart';
import 'package:zogolive/pages/football_detail_page.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';
import 'package:zogolive/utils/g5_search_history_manager.dart';

/// 搜索页分类枚举
/// 说明：搜索结果的分类标签，all=全部，match=比赛，user=用户
enum G5SearchTab { all, match, user }

/// 搜索页面
/// 严格还原 home_search.html 设计稿
/// 顶部搜索框 + 分类菜单（全部/比赛/用户）+ 结果列表
/// 键盘弹起（搜索框获得焦点）展示历史搜索界面，键盘收起展示搜索结果界面
class SearchPage extends G5BaseViewController {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends G5BaseViewState<SearchPage> {
  /// 搜索输入控制器 - TextEditingController类型，监听搜索框内容变化
  final TextEditingController _searchController = TextEditingController();

  /// 搜索框焦点节点 - FocusNode类型，监听焦点切换历史界面/结果界面
  final FocusNode _searchFocusNode = FocusNode();

  /// 当前选中的分类 - G5SearchTab类型，切换时刷新列表数据
  G5SearchTab _currentTab = G5SearchTab.all;

  /// 搜索关键词 - String类型，当前生效的搜索词（点击搜索后更新）
  String _keyword = '';

  /// 搜索历史列表 - List<String>类型，最多8条，最新的在最前
  List<String> _historyList = [];

  /// 是否展示搜索历史界面 - bool类型，true=历史+热门界面，false=搜索结果界面
  bool _showHistory = true;

  /// 热门比赛列表 - List<G5MatchItem>类型，接口/api/livespeed/index/search/match/hot返回的热门比赛
  List<G5MatchItem> _hotMatches = [];

  /// 热门列表是否加载中 - bool类型，true表示热门接口请求进行中
  bool _isHotLoading = true;

  /// 搜索结果模型 - G5SearchResultModel?类型，包含matches比赛列表和users用户列表
  G5SearchResultModel? _searchResult;

  /// 搜索结果是否加载中 - bool类型，true表示搜索接口请求进行中
  bool _isSearchLoading = false;

  @override
  bool get showBackButton => false;

  @override
  void initState() {
    super.initState();
    // 监听焦点变化：获得焦点（键盘弹起）展示历史界面，失去焦点（键盘收起）展示结果界面
    _searchFocusNode.addListener(_onFocusChanged);
    _loadHistory();
    _fetchHotMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 焦点变化回调
  /// 获得焦点（键盘弹起）时切回历史搜索界面；失去焦点（键盘收起）时展示搜索结果界面
  void _onFocusChanged() {
    if (!mounted) return;
    if (_searchFocusNode.hasFocus) {
      // 键盘弹起：展示历史搜索界面
      if (!_showHistory) {
        setState(() {
          _showHistory = true;
        });
      }
    } else {
      // 键盘收起：已有关键词时展示搜索结果界面
      if (_showHistory && _keyword.isNotEmpty) {
        setState(() {
          _showHistory = false;
        });
      }
    }
  }

  /// 加载本地搜索历史
  Future<void> _loadHistory() async {
    final list = await G5SearchHistoryManager.instance.getHistoryList();
    if (mounted) {
      setState(() {
        _historyList = list;
      });
    }
  }

  /// 执行搜索
  /// 收起键盘后进入搜索结果界面，并保存搜索历史
  /// 参数：keyword - String类型，搜索关键词
  void _doSearch(String keyword) {
    final String trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入搜索内容')),
      );
      return;
    }

    setState(() {
      _keyword = trimmed;
      _showHistory = false;
    });

    // 收起键盘
    FocusScope.of(context).unfocus();

    // 保存搜索历史
    G5SearchHistoryManager.instance.addHistory(trimmed).then((list) {
      if (mounted) {
        setState(() {
          _historyList = list;
        });
      }
    });

    _fetchSearchResults();
  }

  /// 请求搜索结果数据
  /// 接口：GET /api/livespeed/index/search
  /// 参数：text - String类型，搜索关键词
  /// 返回matches比赛列表和users用户列表
  Future<void> _fetchSearchResults() async {
    if (_keyword.isEmpty) return;

    setState(() {
      _isSearchLoading = true;
    });

    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/index/search',
        queryParameters: {'text': _keyword},
      );

      if (response.isSuccess && response.data != null) {
        final result = G5SearchResultModel.fromJson(
            response.data as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _searchResult = result;
            _isSearchLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResult = null;
            _isSearchLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResult = null;
          _isSearchLoading = false;
        });
      }
    }
  }

  /// 切换分类菜单
  /// 参数：tab - G5SearchTab类型，目标分类
  void _switchTab(G5SearchTab tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
    });
    // 切换分类时刷新列表数据
    if (_keyword.isNotEmpty) {
      _fetchSearchResults();
    }
  }

  /// 清空全部搜索历史
  Future<void> _clearHistory() async {
    await G5SearchHistoryManager.instance.clearHistory();
    if (mounted) {
      setState(() {
        _historyList = [];
      });
    }
  }

  /// 取消搜索，清空输入并回到历史界面
  void _cancelSearch() {
    setState(() {
      _searchController.clear();
      _keyword = '';
      _showHistory = true;
      _searchResult = null;
    });
  }

  /// 请求热门比赛列表
  /// 接口：GET /api/livespeed/index/search/match/hot
  /// 参照post_match_search_page的逻辑解析数据，只保留足球类目（categoryId==1）
  Future<void> _fetchHotMatches() async {
    setState(() {
      _isHotLoading = true;
    });

    try {
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

        if (mounted) {
          setState(() {
            _hotMatches = newItems;
            _isHotLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isHotLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isHotLoading = false;
        });
      }
    }
  }

  /// 解析搜索比赛JSON为G5MatchItem模型
  /// 字段映射与post_match_search_page的_parseSearchMatch保持一致
  /// 参数：json - Map<String, dynamic>类型，接口返回的单条比赛数据
  /// 返回：G5MatchItem，比赛列表模型
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

  /// 点击热门比赛条目跳转比赛详情
  /// 参数：match - G5MatchItem类型，热门比赛数据
  void _pushToMatchDetail(G5MatchItem match) {
    // 收起键盘
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FootballDetailPage(match: match),
    ));
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return null; // 使用自定义搜索头部
  }

  @override
  Widget buildBody(BuildContext context) {
    return GestureDetector(
      // 点击空白处收起键盘
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _showHistory
                ? _buildDefaultView()
                : _buildSearchResultsView(),
          ),
        ],
      ),
    );
  }

  /// 构建顶部搜索框区域（返回按钮 + 搜索框 + 取消按钮）
  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: G5Colors.pitch,
        border: Border(
          bottom: BorderSide(
              color: G5Colors.pitchBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () {
              if (!_showHistory) {
                _cancelSearch();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.chevron_left,
                  color: G5Colors.textSecondary, size: 26),
            ),
          ),
          const SizedBox(width: 8),
          // 搜索输入框
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 14, right: 8),
              decoration: BoxDecoration(
                color: G5Colors.pitchCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: G5Colors.pitchBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: G5Colors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _doSearch,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: '搜索比赛、球队、主播/用户',
                        hintStyle: TextStyle(
                            color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  ),
                  // 清空输入按钮
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _cancelSearch();
                        // 清空后重新聚焦方便继续输入
                        _searchFocusNode.requestFocus();
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF334155),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Color(0xFFCBD5E1), size: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 取消按钮
          GestureDetector(
            onTap: _cancelSearch,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(
                '取消',
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 历史搜索界面（默认视图） ====================

  /// 构建默认视图：搜索历史 + 热门实时搜索
  Widget _buildDefaultView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHistorySection(),
        const SizedBox(height: 24),
        _buildHotSearchSection(),
      ],
    );
  }

  /// 构建搜索历史区块（胶囊标签流式布局）
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行 + 清空按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.access_time,
                    color: Color(0xFF818CF8), size: 14),
                SizedBox(width: 6),
                Text(
                  '搜索历史',
                  style: TextStyle(
                    color: G5Colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (_historyList.isNotEmpty)
              GestureDetector(
                onTap: _clearHistory,
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline,
                        color: Color(0xFF64748B), size: 13),
                    SizedBox(width: 2),
                    Text(
                      '清空',
                      style:
                          TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_historyList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '暂无搜索历史记录',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          )
        else
          // 历史胶囊标签流式布局
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _historyList
                .map((keyword) => _buildHistoryChip(keyword))
                .toList(),
          ),
      ],
    );
  }

  /// 构建单个历史搜索胶囊标签
  /// 点击胶囊发起搜索；点击右侧x删除单条历史
  /// 参数：keyword - String类型，历史关键词
  Widget _buildHistoryChip(String keyword) {
    return GestureDetector(
      onTap: () {
        _searchController.text = keyword;
        _doSearch(keyword);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 4),
        decoration: BoxDecoration(
          color: G5Colors.pitchCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: G5Colors.pitchBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              keyword,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            const SizedBox(width: 4),
            // 删除单条历史
            GestureDetector(
              onTap: () => _removeHistoryItem(keyword),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close,
                    color: Color(0xFF64748B), size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 删除单条搜索历史
  /// 参数：keyword - String类型，要删除的关键词
  Future<void> _removeHistoryItem(String keyword) async {
    final newList = await G5SearchHistoryManager.instance.removeHistory(keyword);
    if (mounted) {
      setState(() {
        _historyList = newList;
      });
    }
  }

  /// 构建热门实时搜索榜区块
  Widget _buildHotSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.local_fire_department,
                    color: Color(0xFFF59E0B), size: 14),
                SizedBox(width: 6),
                Text(
                  '热门实时搜索',
                  style: TextStyle(
                    color: G5Colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Text(
              '每15分钟更新',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 加载中
        if (_isHotLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          )
        // 空态
        else if (_hotMatches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('暂无热门数据',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ),
          )
        // 热门比赛列表
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: G5Colors.pitchCard.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: G5Colors.pitchBorder.withOpacity(0.6)),
            ),
            child: Column(
              children: _hotMatches
                  .asMap()
                  .entries
                  .map((entry) =>
                      _buildHotItem(entry.value, entry.key + 1))
                  .toList(),
            ),
          ),
      ],
    );
  }

  /// 构建单个热门比赛条目
  /// 保留榜单排名徽章样式（1红 2金 3蓝 其余灰），展示主客队队徽+队名+比分
  /// 参数：match - G5MatchItem类型，热门比赛数据；rank - int类型，榜单排名（从1开始）
  Widget _buildHotItem(G5MatchItem match, int rank) {
    // 排名徽章颜色：1红 2金 3蓝 其余灰
    Color rankBg;
    Color rankText;
    switch (rank) {
      case 1:
        rankBg = const Color(0xFFEF4444).withOpacity(0.2);
        rankText = const Color(0xFFF87171);
        break;
      case 2:
        rankBg = const Color(0xFFF59E0B).withOpacity(0.2);
        rankText = const Color(0xFFFBBF24);
        break;
      case 3:
        rankBg = const Color(0xFF6366F1).withOpacity(0.2);
        rankText = const Color(0xFF818CF8);
        break;
      default:
        rankBg = Colors.transparent;
        rankText = const Color(0xFF64748B);
    }

    return InkWell(
      // 点击跳转比赛详情
      onTap: () => _pushToMatchDetail(match),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Row(
          children: [
            // 排名徽章
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 主队（队名 + 队徽）
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(match.homeTeamName ?? '',
                        style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  if (match.homeTeamLogo != null &&
                      match.homeTeamLogo!.isNotEmpty)
                    Image.network(match.homeTeamLogo!,
                        width: 20,
                        height: 20,
                        errorBuilder: (c, e, s) =>
                            const SizedBox(width: 20, height: 20)),
                ],
              ),
            ),
            // 比分 或 VS
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: (match.homeTeamScore != null &&
                      match.awayTeamScore != null)
                  ? Text(
                      '${match.homeTeamScore} - ${match.awayTeamScore}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: G5Colors.pitchElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('VS',
                          style: TextStyle(
                              color: G5Colors.accentGold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
            ),
            // 客队（队徽 + 队名）
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (match.awayTeamLogo != null &&
                      match.awayTeamLogo!.isNotEmpty)
                    Image.network(match.awayTeamLogo!,
                        width: 20,
                        height: 20,
                        errorBuilder: (c, e, s) =>
                            const SizedBox(width: 20, height: 20)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(match.awayTeamName ?? '',
                        style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
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

  // ==================== 搜索结果界面 ====================

  /// 构建搜索结果视图：分类Tab + 结果列表
  Widget _buildSearchResultsView() {
    return Column(
      children: [
        _buildTabMenu(),
        Expanded(child: _buildResultBody()),
      ],
    );
  }

  /// 构建分类菜单（全部/比赛/用户），Tab样式：选中indigo下划线，元素之间间隔10像素
  Widget _buildTabMenu() {
    final tabMap = const {
      G5SearchTab.all: '全部',
      G5SearchTab.match: '比赛',
      G5SearchTab.user: '用户',
    };

    return Container(
      decoration: BoxDecoration(
        color: G5Colors.pitch,
        border: Border(
          bottom: BorderSide(
              color: G5Colors.pitchBorder.withOpacity(0.6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        // 菜单元素之间间隔10像素
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (final entry in tabMap.entries) ...[
            if (entry.key != G5SearchTab.all) const SizedBox(width: 10),
            _buildTabItem(entry.key, entry.value),
          ],
        ],
      ),
    );
  }

  /// 构建单个分类Tab项
  /// 参数：tab - G5SearchTab类型，分类枚举；label - String类型，分类文案
  Widget _buildTabItem(G5SearchTab tab, String label) {
    final bool isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () => _switchTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF818CF8)
                : G5Colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建结果列表主体
  /// "全部"分两段展示：第一段比赛、第二段用户（段落无数据则隐藏）
  /// "比赛"/"用户"分类只展示对应段落
  Widget _buildResultBody() {
    // 加载中
    if (_isSearchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    final matches =
        (_searchResult?.matches ?? []).where((m) => m.categoryId == null || m.categoryId == 1).toList();
    final users = _searchResult?.users ?? [];

    // 根据当前分类决定各段落是否展示
    final bool showMatchSection =
        matches.isNotEmpty && _currentTab != G5SearchTab.user;
    final bool showUserSection =
        users.isNotEmpty && _currentTab != G5SearchTab.match;

    // 两段都无数据：展示空态
    if (!showMatchSection && !showUserSection) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: G5Colors.pitchCard,
                border: Border.all(color: G5Colors.pitchBorder),
              ),
              child: const Icon(Icons.search,
                  color: Color(0xFF475569), size: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              '未找到相关结果',
              style: TextStyle(
                  color: G5Colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '试试搜索 "曼城"、"NBA" 或 "主播"',
              style:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 第一段：比赛（无数据隐藏）
        if (showMatchSection) ...[
          _buildSectionTitle('比赛', matches.length),
          const SizedBox(height: 10),
          ...matches.map((match) => _buildMatchCard(match)),
        ],
        // 第二段：用户（无数据隐藏，与比赛段之间留20像素间距）
        if (showUserSection) ...[
          if (showMatchSection) const SizedBox(height: 20),
          _buildSectionTitle('用户', users.length),
          const SizedBox(height: 10),
          ...users.map((user) => _buildUserCard(user)),
        ],
      ],
    );
  }

  /// 构建段落标题（标题 + 数量徽标）
  /// 参数：title - String类型，段落标题；count - int类型，该段数据条数
  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: G5Colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: G5Colors.pitchElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
                color: G5Colors.textSecondary, fontSize: 10),
          ),
        ),
      ],
    );
  }

  /// 构建单个比赛结果卡片
  /// 展示主客队队徽、队名、比分/VS，点击跳转比赛详情
  /// 参数：match - G5MatchItem类型，比赛数据
  Widget _buildMatchCard(G5MatchItem match) {
    return GestureDetector(
      // 点击跳转比赛详情
      onTap: () => _pushToMatchDetail(match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (match.matchTime != null)
                  Text(
                    _formatMatchTime(match.matchTime!),
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // 主客队 + 比分
            Row(
              children: [
                // 主队（队名 + 队徽）
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
                              fontWeight: FontWeight.bold),
                        )
                      : const Text('VS',
                          style: TextStyle(
                              color: G5Colors.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                ),
                // 客队（队徽 + 队名）
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
          ],
        ),
      ),
    );
  }

  /// 格式化比赛时间为展示文案
  /// 参数：timestamp - int类型，秒级时间戳
  /// 返回：String，格式 MM-dd HH:mm
  String _formatMatchTime(int timestamp) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  /// 构建单个用户结果卡片
  /// 展示头像（直播中带LIVE角标）、昵称（专家带认证标）、关注按钮（follow_type状态）
  /// 参数：user - G5SearchUser类型，用户数据
  Widget _buildUserCard(G5SearchUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Row(
        children: [
          // 头像（直播中带LIVE角标）
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: (user.avatar != null && user.avatar!.isNotEmpty)
                    ? Image.network(user.avatar!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                            width: 44,
                            height: 44,
                            color: G5Colors.pitchElevated,
                            child: const Icon(Icons.person,
                                color: G5Colors.textSecondary, size: 22)))
                    : Container(
                        width: 44,
                        height: 44,
                        color: G5Colors.pitchElevated,
                        child: const Icon(Icons.person,
                            color: G5Colors.textSecondary, size: 22)),
              ),
              // 直播中角标
              if (user.isLiving == 1)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: G5Colors.accentCrimson,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: G5Colors.pitch, width: 1.5),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 昵称 + 专家认证标
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    user.nickname ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.isExpert == 1) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified,
                      color: Color(0xFF818CF8), size: 14),
                ],
              ],
            ),
          ),
          // 关注按钮：follow_type=0/2未关注（可点击关注），follow_type=1/3已关注
          GestureDetector(
            onTap: () => _toggleFollow(user),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: user.isFollowed
                    ? G5Colors.pitchElevated
                    : const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: user.isFollowed
                      ? G5Colors.pitchBorder
                      : const Color(0xFF6366F1).withOpacity(0.5),
                ),
              ),
              child: Text(
                user.isFollowed ? '已关注' : '+ 关注',
                style: TextStyle(
                  color: user.isFollowed
                      ? G5Colors.textSecondary
                      : const Color(0xFF818CF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 切换用户关注状态
  /// 接口：POST /api/livespeed/imchat/subscribe
  /// 参数：target_id-用户id（int），type-1关注/2取消关注（当前未关注传1，已关注传2）
  /// 请求完毕toast提示，成功后本地更新关注状态
  /// 参数：user - G5SearchUser类型，目标用户
  Future<void> _toggleFollow(G5SearchUser user) async {
    // 已关注（follow_type=1/3）时传2取消关注，未关注（follow_type=0/2）时传1关注
    final int type = user.isFollowed ? 2 : 1;

    try {
      final response = await G5NetworkManager().post(
        '/api/livespeed/imchat/subscribe',
        data: {
          // 关注用户取uuid字段
          'target_id': user.id,
          'type': type,
        },
      );

      if (!mounted) return;

      if (response.isSuccess) {
        // 成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 1 ? '关注成功' : '已取消关注'),
            duration: const Duration(seconds: 1),
          ),
        );

        // 本地更新关注状态
        setState(() {
          final index =
              _searchResult?.users.indexWhere((u) => u.id == user.id) ?? -1;
          if (index >= 0 && _searchResult != null) {
            final users = _searchResult!.users;
            users[index] = G5SearchUser(
              id: users[index].id,
              uuid: users[index].uuid,
              avatar: users[index].avatar,
              nickname: users[index].nickname,
              isLiving: users[index].isLiving,
              isExpert: users[index].isExpert,
              isVip: users[index].isVip,
              // 关注成功follow_type置1，取消关注置0
              followType: type == 1 ? 1 : 0,
            );
          }
        });
      } else {
        // 失败提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? '操作失败，请稍后重试'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('网络异常，请稍后重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
