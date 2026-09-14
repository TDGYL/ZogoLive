import 'package:flutter/material.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/models/g5_match_model.dart';
import 'package:livespeed/models/g5_odds_model.dart';
import 'package:livespeed/models/g5_process_model.dart';
import 'package:livespeed/pages/login_page.dart';
import 'package:livespeed/pages/odds_history_page.dart';
import 'package:livespeed/pages/team_detail_page.dart';
import 'package:livespeed/utils/g5_auth_manager.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_match_status_util.dart';
import 'package:livespeed/utils/g5_network_manager.dart';

class FootballDetailPage extends G5BaseViewController {
  final G5MatchItem match;

  const FootballDetailPage({Key? key, required this.match}) : super(key: key);

  @override
  State<FootballDetailPage> createState() => _FootballDetailPageState();
}

class _FootballDetailPageState extends G5BaseViewState<FootballDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Events', 'Stats', 'Odds', 'H2H'];

  G5ProcessData? _processData;
  bool _isLoading = true;

  /// Match DetailStats - G5MatchItem?类型，接口返回的完整比赛Stats（含TeamID），懒加载兜底widget.match
  G5MatchItem? _matchDetail;

  List<G5MatchItem>? _historyTotal;
  List<G5MatchItem>? _homeTotal;
  List<G5MatchItem>? _awayTotal;
  bool _isAnalysisLoading = true;

  G5OddsData? _oddsData;
  bool _isOddsLoading = true;

  /// 是否Following比赛 - bool类型，true表示Following，Open值取自Match Detail接口的subscribed字段
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _isSubscribed = widget.match.subscribed == true;
    _fetchMatchDetail();
    _fetchProcessData();
    _fetchAnalysisData();
    _fetchOddsData();
  }

  /// 当前展示的比赛Stats - 优先使用详情接口返回Stats，兜底页面传参
  G5MatchItem get match => _matchDetail ?? widget.match;

  /// 请求Match Detail
  /// 接口：GET /api/livespeed/football/match/detail
  /// 参数：match_id - int类型，比赛ID
  /// 成功后用返回Stats替换当前比赛Stats（保证任意入口进入都能获取TeamID跳转Team详情）
  Future<void> _fetchMatchDetail() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/match/detail',
        queryParameters: {'match_id': widget.match.matchId},
      );

      if (response.code == 0 && response.data != null) {
        if (mounted) {
          setState(() {
            _matchDetail =
                G5MatchItem.fromJson(response.data as Map<String, dynamic>);
            // 根据详情接口的Follow状态同步按钮状态
            _isSubscribed = _matchDetail?.subscribed == true;
          });
        }
      }
    } catch (e) {
      // Request failed时保持使用传入的比赛Stats
    }
  }

  /// 登录校验，未登录跳转登录页
  /// 参数：action - VoidCallback类型，已登录时执行的操作
  void _checkLoginAndDo(VoidCallback action) {
    if (G5AuthManager().isLoggedIn) {
      action();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// 切换比赛Follow状态
  /// Following调用CancelFollow接口 POST /api/livespeed/football/match/unsubscribe
  /// 未Follow调用Follow接口 POST /api/livespeed/football/match/subscribe
  /// 需要用户登录，成功后同步Follow按钮状态
  void _toggleSubscribe() {
    _checkLoginAndDo(() async {
      final matchId = match.matchId ?? 0;
      if (matchId == 0) return;

      // 目标状态：当前Following则CancelFollow，未Follow则Follow
      final willSubscribe = !_isSubscribed;
      final url = willSubscribe
          ? '/api/livespeed/football/match/subscribe'
          : '/api/livespeed/football/match/unsubscribe';

      try {
        final response = await G5NetworkManager().post(
          url,
          data: {'match_id': matchId},
        );

        if (!mounted) return;

        if (response.code == 0) {
          setState(() {
            _isSubscribed = willSubscribe;
          });
          // 同步到详情Stats模型
          if (_matchDetail != null) {
            _matchDetail!.subscribed = willSubscribe;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willSubscribe ? 'Followed' : 'Unfollowed'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed, try later'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error, try later'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  Future<void> _fetchOddsData() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/match/odds',
        queryParameters: {'match_id': widget.match.matchId},
      );

      if (response.code == 0 && response.data != null) {
        if (mounted) {
          setState(() {
            _oddsData =
                G5OddsData.fromJson(response.data as Map<String, dynamic>);
            _isOddsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isOddsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOddsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAnalysisData() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/match/analysis',
        queryParameters: {'match_id': widget.match.matchId},
      );

      if (response.code == 0 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final hist = data['history'] as Map<String, dynamic>?;
        final fix = data['fixture'] as Map<String, dynamic>?;

        List<G5MatchItem>? historyTotal;
        List<G5MatchItem>? homeTotal;
        List<G5MatchItem>? awayTotal;

        if (hist != null && hist['vs'] != null) {
          historyTotal = (hist['vs'] as List)
              .map((e) => G5MatchItem.fromJson(e as Map<String, dynamic>))
              .toList();
          historyTotal = historyTotal.take(6).toList();
        }

        if (fix != null && fix['home'] != null) {
          homeTotal = (fix['home'] as List)
              .map((e) => G5MatchItem.fromJson(e as Map<String, dynamic>))
              .toList();
          homeTotal = homeTotal.take(6).toList();
        }

        if (fix != null && fix['away'] != null) {
          awayTotal = (fix['away'] as List)
              .map((e) => G5MatchItem.fromJson(e as Map<String, dynamic>))
              .toList();
          awayTotal = awayTotal.take(6).toList();
        }

        if (mounted) {
          setState(() {
            _historyTotal = historyTotal;
            _homeTotal = homeTotal;
            _awayTotal = awayTotal;
            _isAnalysisLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAnalysisLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalysisLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProcessData() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/match/process',
        queryParameters: {'match_id': widget.match.matchId},
      );

      if (response.code == 0 && response.data != null) {
        if (mounted) {
          setState(() {
            _processData =
                G5ProcessData.fromJson(response.data as Map<String, dynamic>);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildMatchCard(),
        _buildTabBar(),
        Expanded(
          child: _buildTabBarView(),
        ),
      ],
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
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: G5Colors.accentEmerald.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          match.competitionName ?? 'League',
          style: const TextStyle(
            color: G5Colors.accentEmerald,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // Follow比赛按钮：Following实心金星，未Follow空心灰星
        IconButton(
          icon: Icon(
            _isSubscribed ? Icons.star : Icons.star_border,
            color: _isSubscribed ? G5Colors.accentGold : G5Colors.textSecondary,
          ),
          onPressed: _toggleSubscribe,
        ),
      ],
    );
  }

  String _formatMatchTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMatchCard() {
    final match = this.match;
    bool isLive = G5MatchStatusUtil.isLive(match.statusId);

    String statusDisplay =
        G5MatchStatusUtil.abbreviate(match.statusName, statusId: match.statusId);
    if (isLive && match.minutes != null && match.minutes!.isNotEmpty) {
      statusDisplay = "${match.minutes}'";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: G5Colors.pitch,
        border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatMatchTime(match.matchTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: G5Colors.accentCrimson.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Home
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (match.homeTeamId != null) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TeamDetailPage(
                          teamId: match.homeTeamId!,
                          competitionId: match.competitionId,
                        ),
                      ));
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: G5Colors.pitchElevated,
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
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
                                          size: 30),
                                ),
                              )
                            : const Icon(Icons.shield,
                                color: G5Colors.textSecondary, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        match.homeTeamName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // 比分
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: match.statusId != 1
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${match.homeNormalScore ?? 0}',
                            style: const TextStyle(
                              color: G5Colors.accentEmerald,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${match.awayNormalScore ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'VS',
                        style: TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              // Away
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (match.awayTeamId != null) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TeamDetailPage(
                          teamId: match.awayTeamId!,
                          competitionId: match.competitionId,
                        ),
                      ));
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: G5Colors.pitchElevated,
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
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
                                          size: 30),
                                ),
                              )
                            : const Icon(Icons.shield,
                                color: G5Colors.textSecondary, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        match.awayTeamName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 注意：去掉了哈兰德和贝林厄姆的比League件部分
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: G5Colors.pitch,
        border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: G5Colors.accentEmerald,
        indicatorWeight: 3,
        labelColor: G5Colors.accentEmerald,
        unselectedLabelColor: G5Colors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        tabs: _tabs.map((e) => Tab(text: e)).toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildIncidentsTab(),
        _buildStatsTab(),
        _buildOddsTab(),
        _buildAnalysisTab(),
      ],
    );
  }

  Widget _buildOddsTab() {
    if (_isOddsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOddsSection('Handicap', _oddsData?.asia, ['Home', 'Line', 'Away'], 'asia'),
        const SizedBox(height: 20),
        _buildOddsSection('WDL', _oddsData?.eu, ['Home', 'Draw', 'Away'], 'eu'),
        const SizedBox(height: 20),
        _buildOddsSection('Goals', _oddsData?.bs, ['Over', 'Line', 'Under'], 'bs'),
        const SizedBox(height: 20),
        _buildOddsSection('Corners', _oddsData?.cr, ['Over', 'Line', 'Under'], 'cr'),
      ],
    );
  }

  Widget _buildOddsSection(String title, List<G5OddsCompany>? companies,
      List<String> headers, String oddsType) {
    if (companies == null || companies.isEmpty) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 表头
          Container(
            color: G5Colors.pitchElevated,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                const SizedBox(
                    width: 80,
                    child: Text('Bookmaker',
                        style: TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12))),
                const SizedBox(
                    width: 40,
                    child: Text('',
                        style: TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12))),
                Expanded(
                    child: Text(headers[0],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12))),
                Expanded(
                    child: Text(headers[1],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12))),
                Expanded(
                    child: Text(headers[2],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12))),
              ],
            ),
          ),
          // 列表
          ...companies
              .map((c) => _buildOddsCompanyRow(c, companies, oddsType))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildOddsCompanyRow(G5OddsCompany company,
      List<G5OddsCompany> allCompanies, String oddsType) {
    bool hasPre = company.pre != null;
    bool hasSpot = company.spot != null;

    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OddsHistoryPage(
                match: widget.match,
                initialCompany: company,
                allCompanies: allCompanies,
                oddsType: oddsType,
              ),
            ),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              // Bookmaker名称
              SizedBox(
                width: 80,
                child: Text(
                  company.name ?? '--',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Open/Pre/Live 标签
              SizedBox(
                width: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Open',
                        style: TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12)),
                    if (hasPre) ...[
                      const SizedBox(height: 8),
                      const Text('Pre',
                          style: TextStyle(
                              color: G5Colors.accentBlue, fontSize: 12)),
                    ],
                    if (hasSpot) ...[
                      const SizedBox(height: 8),
                      const Text('Live',
                          style: TextStyle(
                              color: G5Colors.accentEmerald, fontSize: 12)),
                    ]
                  ],
                ),
              ),
              // Stats展示区
              Expanded(
                child: Column(
                  children: [
                    // OpenStats
                    Row(
                      children: [
                        Expanded(
                            child: Text(company.ini?.home ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: G5Colors.textSecondary,
                                    fontSize: 13))),
                        Expanded(
                            child: Text(company.ini?.draw ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: G5Colors.textSecondary,
                                    fontSize: 13))),
                        Expanded(
                            child: Text(company.ini?.away ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: G5Colors.textSecondary,
                                    fontSize: 13))),
                      ],
                    ),
                    // PreStats
                    if (hasPre) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: _buildOddsValueText(
                                  company.pre?.home, company.ini?.home)),
                          Expanded(
                              child: _buildOddsValueText(
                                  company.pre?.draw, company.ini?.draw)),
                          Expanded(
                              child: _buildOddsValueText(
                                  company.pre?.away, company.ini?.away)),
                        ],
                      ),
                    ],
                    // LiveStats
                    if (hasSpot) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: _buildOddsValueText(company.spot?.home,
                                  company.pre?.home ?? company.ini?.home)),
                          Expanded(
                              child: _buildOddsValueText(company.spot?.draw,
                                  company.pre?.draw ?? company.ini?.draw)),
                          Expanded(
                              child: _buildOddsValueText(company.spot?.away,
                                  company.pre?.away ?? company.ini?.away)),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildOddsValueText(String? current, String? initial) {
    Color color = Colors.white;
    if (current != null && initial != null) {
      double? curVal = double.tryParse(current);
      double? iniVal = double.tryParse(initial);
      if (curVal != null && iniVal != null) {
        if (curVal > iniVal)
          color = G5Colors.accentCrimson; // 涨了变红 (或绿，根据习惯)
        else if (curVal < iniVal) color = G5Colors.accentEmerald; // 跌了变绿
      }
    }
    return Text(
      current ?? '-',
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAnalysisTab() {
    if (_isAnalysisLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(),
        const SizedBox(height: 20),
        _buildHistoryMatchesCard(
            'H2H', _historyTotal, match.homeTeamId),
        const SizedBox(height: 20),
        _buildHistoryMatchesCard('Form - ${match.homeTeamName ?? 'Home'}',
            _homeTotal, match.homeTeamId),
        const SizedBox(height: 20),
        _buildHistoryMatchesCard('Form - ${match.awayTeamName ?? 'Away'}',
            _awayTotal, match.awayTeamId),
      ],
    );
  }

  Widget _buildStatsCard() {
    // 计算H2H的WDL（以Home视角）
    int homeWin = 0;
    int draw = 0;
    int awayWin = 0;
    if (_historyTotal != null) {
      for (var m in _historyTotal!) {
        if (m.homeNormalScore != null && m.awayNormalScore != null) {
          // 如果当前页面的Home是H2H里的Home
          if (m.homeTeamId == match.homeTeamId) {
            if (m.homeNormalScore! > m.awayNormalScore!)
              homeWin++;
            else if (m.homeNormalScore! < m.awayNormalScore!)
              awayWin++;
            else
              draw++;
          } else {
            // 如果当前页面的Home是H2H里的Away
            if (m.awayNormalScore! > m.homeNormalScore!)
              homeWin++;
            else if (m.awayNormalScore! < m.homeNormalScore!)
              awayWin++;
            else
              draw++;
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 6 H2H',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('$homeWin', match.homeTeamName ?? '',
                  G5Colors.accentEmerald),
              _buildStatItem('$draw', 'Draw', Colors.white),
              _buildStatItem('$awayWin', match.awayTeamName ?? '',
                  G5Colors.accentBlue),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentFormRow('${match.homeTeamName ?? 'Home'} form:',
              _homeTotal, match.homeTeamId),
          const SizedBox(height: 12),
          _buildRecentFormRow('${match.awayTeamName ?? 'Away'} form:',
              _awayTotal, match.awayTeamId),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: G5Colors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFormRow(
      String label, List<G5MatchItem>? matches, int? targetTeamId) {
    List<Widget> formBadges = [];
    if (matches != null) {
      for (var m in matches) {
        String result = '-';
        Color bgColor = G5Colors.pitchElevated;
        if (m.homeNormalScore != null && m.awayNormalScore != null) {
          bool isHome = m.homeTeamId == targetTeamId;
          if (m.homeNormalScore! == m.awayNormalScore!) {
            result = 'D';
            bgColor = G5Colors.pitchBorder;
          } else if ((isHome && m.homeNormalScore! > m.awayNormalScore!) ||
              (!isHome && m.awayNormalScore! > m.homeNormalScore!)) {
            result = 'W';
            bgColor = G5Colors.accentEmerald.withOpacity(0.2);
          } else {
            result = 'L';
            bgColor = G5Colors.accentCrimson.withOpacity(0.2);
          }
        }

        Color textColor = Colors.white;
        if (result == 'W') textColor = G5Colors.accentEmerald;
        if (result == 'L') textColor = G5Colors.accentCrimson;
        if (result == 'D') textColor = G5Colors.textSecondary;

        formBadges.add(Container(
          margin: const EdgeInsets.only(left: 6),
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Text(
            result,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      }
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: G5Colors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        Row(children: formBadges),
      ],
    );
  }

  Widget _buildHistoryMatchesCard(
      String title, List<G5MatchItem>? matches, int? targetTeamId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (matches == null || matches.isEmpty)
            const Text('No data', style: TextStyle(color: G5Colors.textSecondary))
          else
            ...matches
                .map((m) => _buildHistoryMatchRow(m, targetTeamId))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryMatchRow(G5MatchItem m, int? targetTeamId) {
    bool homeIsCurrentHome = m.homeTeamId == targetTeamId;
    bool awayIsCurrentHome = m.awayTeamId == targetTeamId;

    String resultText = 'D';
    Color resultColor = G5Colors.textSecondary;
    if (m.homeNormalScore != null && m.awayNormalScore != null) {
      if (m.homeNormalScore! > m.awayNormalScore!) {
        resultText = '${m.homeTeamName} W';
        resultColor =
            homeIsCurrentHome ? G5Colors.accentEmerald : G5Colors.accentBlue;
      } else if (m.homeNormalScore! < m.awayNormalScore!) {
        resultText = '${m.awayTeamName} W';
        resultColor =
            awayIsCurrentHome ? G5Colors.accentEmerald : G5Colors.accentBlue;
      }
    }

    return GestureDetector(
      onTap: () {
        // 点击跳转到这局比赛的详情页
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FootballDetailPage(match: m),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
        ),
        child: Row(
          children: [
            // 左侧：时间和League
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMatchDate(m.matchTime),
                    style: const TextStyle(
                        color: G5Colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.competitionName ?? '',
                    style: const TextStyle(
                        color: G5Colors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 中间：主Away比分
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      m.homeTeamName ?? '',
                      style: TextStyle(
                          color: homeIsCurrentHome
                              ? G5Colors.accentEmerald
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                      softWrap: true,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: G5Colors.pitchElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${m.homeNormalScore ?? 0} - ${m.awayNormalScore ?? 0}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      m.awayTeamName ?? '',
                      style: TextStyle(
                          color: awayIsCurrentHome
                              ? G5Colors.accentEmerald
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
            // 右侧：结果
            SizedBox(
              width: 60,
              child: Text(
                resultText,
                style: TextStyle(color: resultColor, fontSize: 12),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMatchDate(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year.toString().substring(2)}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildIncidentsTab() {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    if (_processData?.incidents == null || _processData!.incidents!.isEmpty) {
      return const Center(
          child:
              Text('No event data', style: TextStyle(color: G5Colors.textSecondary)));
    }

    final incidents = _processData!.incidents!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final incident = incidents[index];
        final isHome = incident.position == 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home区域
              Expanded(
                child: isHome
                    ? _buildIncidentContent(incident, true)
                    : const SizedBox(),
              ),
              // 中间时间轴
              Container(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: G5Colors.pitchElevated,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${incident.time ?? 0}\'',
                        style: const TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (index != incidents.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: G5Colors.pitchElevated,
                        margin: const EdgeInsets.only(top: 4),
                      ),
                  ],
                ),
              ),
              // Away区域
              Expanded(
                child: !isHome && incident.position == 2
                    ? _buildIncidentContent(incident, false)
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncidentContent(G5IncidentItem incident, bool isHome) {
    List<Widget> children = [
      Icon(incident.iconData, color: incident.iconColor, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment:
              isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              incident.custPlayerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 2),
            Text(
              incident.custTypeName,
              style:
                  const TextStyle(color: G5Colors.textSecondary, fontSize: 11),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
            ),
          ],
        ),
      ),
    ];

    if (isHome) {
      children = children.reversed.toList();
    }

    return Row(
      mainAxisAlignment:
          isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildStatsTab() {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    if (_processData?.stats == null || _processData!.stats!.isEmpty) {
      return const Center(
          child:
              Text('No stats data', style: TextStyle(color: G5Colors.textSecondary)));
    }

    final stats = _processData!.stats!;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stat.home ?? 0}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    stat.typeName,
                    style: const TextStyle(
                        color: G5Colors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${stat.away ?? 0}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Transform.flip(
                      flipX: true,
                      child: LinearProgressIndicator(
                        value: stat.homeProgress,
                        backgroundColor: G5Colors.pitchElevated,
                        color: G5Colors.accentEmerald,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: stat.awayProgress,
                      backgroundColor: G5Colors.pitchElevated,
                      color: G5Colors.accentGold,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
