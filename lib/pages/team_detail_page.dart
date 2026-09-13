import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/models/g5_news_model.dart';
import 'package:zogolive/models/g5_team_lineup_model.dart';
import 'package:zogolive/models/g5_team_model.dart';
import 'package:zogolive/models/g5_team_rank_model.dart';
import 'package:zogolive/pages/football_detail_page.dart';
import 'package:zogolive/pages/news_detail_page.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

class TeamDetailPage extends G5BaseViewController {
  final int teamId;
  final int? competitionId;

  const TeamDetailPage({Key? key, required this.teamId, this.competitionId})
      : super(key: key);

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends G5BaseViewState<TeamDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['概览', '赛程', '阵容', '积分榜'];

  bool _isLoading = true;
  G5TeamData? _teamData;

  bool _isNewsLoading = false;
  List<G5NewsItem> _newsList = [];

  bool _isMatchesLoading = false;
  List<G5MatchItem> _matchesList = [];

  bool _isLineupLoading = false;
  List<G5TeamLineupGroup> _lineupList = [];

  bool _isRankLoading = false;
  List<G5TeamRankGroup> _rankList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // 如果外部传入了 competitionId，则立即发起赛程和新闻的请求，不必等 teamData 返回
    if (widget.competitionId != null) {
      _fetchTeamNews(widget.competitionId!);
      _fetchTeamMatches(widget.competitionId!);
      _fetchTeamRank(widget.competitionId!);
    }

    _fetchTeamData();
    _fetchTeamLineup();
  }

  Future<void> _fetchTeamData() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/team/data',
        queryParameters: {'team_id': widget.teamId},
      );

      if (response.code == 0 && response.data != null) {
        if (mounted) {
          setState(() {
            _teamData =
                G5TeamData.fromJson(response.data as Map<String, dynamic>);
            _isLoading = false;
          });

          // 如果外部没有传入 competitionId，但是详情接口返回了，则使用返回的 id 去请求（兜底）
          if (widget.competitionId == null &&
              _teamData?.competitionId != null) {
            _fetchTeamNews(_teamData!.competitionId!);
            _fetchTeamMatches(_teamData!.competitionId!);
            _fetchTeamRank(_teamData!.competitionId!);
          }
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

  Future<void> _fetchTeamNews(int competitionId) async {
    setState(() {
      _isNewsLoading = true;
    });
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/info/list',
        queryParameters: {
          'page': 1,
          'size': 5,
          'competition_id': competitionId,
        },
      );
      if (response.code == 0 && response.data != null) {
        final data = G5NewsData.fromJson(response.data as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _newsList = data.results ?? [];
            _isNewsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isNewsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNewsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTeamMatches(int competitionId) async {
    setState(() {
      _isMatchesLoading = true;
    });
    try {
      final now = DateTime.now();
      // 获取明天的时间戳
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final timestamp = (tomorrow.millisecondsSinceEpoch / 1000).floor();

      final response = await G5NetworkManager().post(
        '/api/livespeed/football/matches',
        data: {
          'tab': 0,
          'page': 1,
          'size': 10,
          'timestamp': timestamp,
          'competition_ids': [competitionId],
        },
      );
      if (response.code == 0 && response.data != null) {
        final data =
            G5MatchData.fromJson(response.data as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _matchesList = data.results ?? [];
            _isMatchesLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isMatchesLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMatchesLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTeamLineup() async {
    setState(() {
      _isLineupLoading = true;
    });
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/team/lineup',
        queryParameters: {'team_id': widget.teamId},
      );
      if (response.code == 0 && response.data != null) {
        final list = (response.data as List)
            .map((e) => G5TeamLineupGroup.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _lineupList = list;
            _isLineupLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLineupLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLineupLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTeamRank(int competitionId) async {
    setState(() {
      _isRankLoading = true;
    });
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/football/team/rank',
        queryParameters: {
          'competition_id': competitionId,
          'season_id': 2025,
        },
      );
      if (response.code == 0 && response.data != null) {
        final list = (response.data as List)
            .map((e) => G5TeamRankGroup.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _rankList = list;
            _isRankLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isRankLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRankLoading = false;
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
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }

    if (_teamData == null) {
      return const Center(
          child:
              Text('暂无球队数据', style: TextStyle(color: G5Colors.textSecondary)));
    }

    return Column(
      children: [
        _buildHeaderCard(),
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
      title: Text(
        _teamData?.name ?? '球队详情',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderCard() {
    final team = _teamData!;

    // 身价格式化
    String marketValueStr = '-';
    if (team.marketValue != null) {
      if (team.marketValue! >= 100000000) {
        marketValueStr =
            '€${(team.marketValue! / 100000000).toStringAsFixed(1)}亿';
      } else if (team.marketValue! >= 10000) {
        marketValueStr = '€${(team.marketValue! / 10000).toStringAsFixed(0)}万';
      } else {
        marketValueStr = '€${team.marketValue}';
      }
    }

    return Container(
      color: G5Colors.pitch,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // 顶部：头像、名称、标签
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: G5Colors.pitchElevated,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.all(8),
                child: team.logo != null && team.logo!.isNotEmpty
                    ? Image.network(
                        team.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shield,
                                color: G5Colors.textSecondary, size: 30),
                      )
                    : const Icon(Icons.shield,
                        color: G5Colors.textSecondary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (team.competitionName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: G5Colors.accentEmerald.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      G5Colors.accentEmerald.withOpacity(0.3)),
                            ),
                            child: Text(
                              team.competitionName!,
                              style: const TextStyle(
                                color: G5Colors.accentEmerald,
                                fontSize: 10,
                              ),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${team.name ?? ''} • ${team.countryName ?? ''}',
                      style: const TextStyle(
                          color: G5Colors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: G5Colors.pitchElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: G5Colors.pitchBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield,
                                  color: G5Colors.accentGold, size: 10),
                              const SizedBox(width: 4),
                              Text('成立 ${team.foundationTime ?? "-"}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: G5Colors.pitchElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: G5Colors.pitchBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: G5Colors.accentBlue, size: 10),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    team.venueName ?? "-",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          // 底部数据网格
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: G5Colors.pitchBorder)),
            ),
            child: Row(
              children: [
                _buildQuickMetric('总身价', marketValueStr, Colors.white),
                _buildQuickMetric(
                    '国家', team.countryName ?? '-', G5Colors.accentGold),
                _buildQuickMetric('主教练', team.managerName ?? '-', Colors.white),
                _buildQuickMetric(
                    '容量',
                    team.venueCapacity != null ? '${team.venueCapacity}' : '-',
                    Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: G5Colors.pitchElevated.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: G5Colors.pitchBorder),
        ),
        child: Column(
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: G5Colors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: G5Colors.pitch,
        border: Border(
            top: BorderSide(color: G5Colors.pitchBorder),
            bottom: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false, // 改为 false 让选项卡均分宽度
        indicatorColor: G5Colors.accentBlue,
        indicatorWeight: 3,
        labelColor: G5Colors.accentBlue,
        unselectedLabelColor: G5Colors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        tabs: _tabs.map((e) => Tab(text: e)).toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tabName) {
        if (tabName == '概览') {
          return _buildOverviewTab();
        } else if (tabName == '赛程') {
          return _buildFixturesTab();
        } else if (tabName == '阵容') {
          return _buildLineupTab();
        } else if (tabName == '积分榜') {
          return _buildStandingsTab();
        }
        return Center(
            child: Text('$tabName (待开发)',
                style: const TextStyle(color: G5Colors.textSecondary)));
      }).toList(),
    );
  }

  Widget _buildFixturesTab() {
    if (_isMatchesLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }

    if (_matchesList.isEmpty) {
      return const Center(
          child:
              Text('暂无赛程数据', style: TextStyle(color: G5Colors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchesList.length,
      itemBuilder: (context, index) {
        final match = _matchesList[index];
        bool isFinished = match.statusId == 8; // 8代表完赛
        bool isLive = match.statusId != null &&
            match.statusId! > 1 &&
            match.statusId! < 8; // 进行中

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => FootballDetailPage(match: match),
            ));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFinished ? G5Colors.pitchElevated : G5Colors.pitchCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLive
                    ? G5Colors.accentEmerald.withOpacity(0.4)
                    : G5Colors.pitchBorder,
              ),
              boxShadow: isLive
                  ? [
                      BoxShadow(
                          color: G5Colors.accentEmerald.withOpacity(0.1),
                          blurRadius: 8)
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 左侧时间和赛事
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMatchDate(match.matchTime),
                        style: TextStyle(
                          color: isLive
                              ? G5Colors.accentEmerald
                              : G5Colors.textSecondary,
                          fontSize: 11,
                          fontWeight:
                              isLive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        match.competitionName ?? '',
                        style: const TextStyle(
                            color: G5Colors.textSecondary, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 中间主客队和比分
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 主队
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                match.homeTeamName ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (match.homeTeamLogo != null &&
                                match.homeTeamLogo!.isNotEmpty)
                              ClipOval(
                                child: Image.network(match.homeTeamLogo!,
                                    width: 24, height: 24, fit: BoxFit.cover),
                              ),
                          ],
                        ),
                      ),

                      // 比分
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: G5Colors.pitch,
                          borderRadius: BorderRadius.circular(4),
                          border: isLive
                              ? Border.all(
                                  color:
                                      G5Colors.accentEmerald.withOpacity(0.5))
                              : null,
                        ),
                        child: Text(
                          isFinished || isLive
                              ? '${match.homeNormalScore} - ${match.awayNormalScore}'
                              : _formatMatchTimeOnly(match.matchTime),
                          style: TextStyle(
                            color: isLive
                                ? G5Colors.accentEmerald
                                : (isFinished
                                    ? Colors.white
                                    : G5Colors.accentGold),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 客队
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (match.awayTeamLogo != null &&
                                match.awayTeamLogo!.isNotEmpty)
                              ClipOval(
                                child: Image.network(match.awayTeamLogo!,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const SizedBox(width: 24, height: 24)),
                              ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                match.awayTeamName ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 右侧状态
                SizedBox(
                  width: 50,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLive
                            ? G5Colors.accentEmerald.withOpacity(0.1)
                            : (isFinished
                                ? G5Colors.accentEmerald.withOpacity(0.1)
                                : G5Colors.accentGold.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isLive
                              ? G5Colors.accentEmerald.withOpacity(0.2)
                              : (isFinished
                                  ? G5Colors.accentEmerald.withOpacity(0.2)
                                  : G5Colors.accentGold.withOpacity(0.2)),
                        ),
                      ),
                      child: Text(
                        match.statusName ?? '未开赛',
                        style: TextStyle(
                          color: isLive
                              ? G5Colors.accentEmerald
                              : (isFinished
                                  ? G5Colors.accentEmerald
                                  : G5Colors.accentGold),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatMatchDate(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMatchTimeOnly(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLineupTab() {
    if (_isLineupLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }

    // 过滤掉 personList 为空的分组
    final validGroups = _lineupList
        .where((g) => g.personList != null && g.personList!.isNotEmpty)
        .toList();
    if (validGroups.isEmpty) {
      return const Center(
          child:
              Text('暂无阵容数据', style: TextStyle(color: G5Colors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: validGroups.length,
      itemBuilder: (context, index) {
        final group = validGroups[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: G5Colors.pitchElevated,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group.positionName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '进球 / 出场',
                      style: TextStyle(
                          color: G5Colors.textSecondary, fontSize: 12),
                    )
                  ],
                ),
              ),
              // 球员列表
              ...group.personList!
                  .map((player) => _buildPlayerRow(player))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerRow(G5TeamPlayer player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: Row(
        children: [
          // 号码
          SizedBox(
            width: 30,
            child: Text(
              player.shirtNumber != null ? '${player.shirtNumber}' : '-',
              style: const TextStyle(
                  color: G5Colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
          // 头像
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: G5Colors.pitchElevated,
              shape: BoxShape.circle,
              border: Border.all(color: G5Colors.pitchBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: player.logo != null && player.logo!.isNotEmpty
                ? Image.network(player.logo!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.person,
                        color: G5Colors.textSecondary, size: 20))
                : const Icon(Icons.person,
                    color: G5Colors.textSecondary, size: 20),
          ),
          // 姓名
          Expanded(
            child: Text(
              player.name ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 数据
          SizedBox(
            width: 60,
            child: Text(
              '${player.goals ?? 0} / ${player.matches ?? 0}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.newspaper, color: G5Colors.accentBlue, size: 16),
                  SizedBox(width: 8),
                  Text('球队最新动态',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (_isNewsLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: G5Colors.accentEmerald))
              else if (_newsList.isEmpty)
                const Text('暂无最新新闻数据',
                    style:
                        TextStyle(color: G5Colors.textSecondary, fontSize: 12))
              else
                ..._newsList.map((news) => _buildNewsRow(news)).toList(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildNewsRow(G5NewsItem news) {
    return GestureDetector(
      onTap: () {
        if (news.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(newsId: news.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: G5Colors.pitchElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: news.cover != null && news.cover!.isNotEmpty
                  ? Image.network(news.cover!, fit: BoxFit.cover)
                  : const Icon(Icons.image, color: G5Colors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(news.createdAt),
                    style: const TextStyle(
                      color: G5Colors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${date.month}-${date.day}';
    }
  }

  Widget _buildStandingsTab() {
    if (_isRankLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }
    if (_rankList.isEmpty) {
      return const Center(
          child:
              Text('暂无积分榜数据', style: TextStyle(color: G5Colors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankList.length,
      itemBuilder: (context, index) {
        final group = _rankList[index];
        final items = group.list ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.promotionName != null &&
                  group.promotionName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12, bottom: 4),
                  child: Text(
                    group.promotionName!,
                    style: const TextStyle(
                      color: G5Colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // 表头
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 32,
                        child: Text('排名',
                            style: TextStyle(
                                color: G5Colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('球队',
                            style: TextStyle(
                                color: G5Colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                    SizedBox(
                        width: 32,
                        child: Text('赛',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: G5Colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                    SizedBox(
                        width: 48,
                        child: Text('胜/平/负',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: G5Colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                    SizedBox(
                        width: 32,
                        child: Text('积分',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: G5Colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // 列表项
              ...items.map((item) => _buildStandingsRow(item)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandingsRow(G5TeamRankItem item) {
    bool isCurrentTeam = item.teamId == widget.teamId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentTeam
            ? G5Colors.accentBlue.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentTeam
            ? Border.all(color: G5Colors.accentBlue.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // 排名
          SizedBox(
            width: 32,
            child: Text(
              '${item.position ?? "-"}',
              style: TextStyle(
                color: (item.position ?? 0) <= 3
                    ? G5Colors.accentGold
                    : G5Colors.textSecondary,
                fontSize: 12,
                fontWeight: (item.position ?? 0) <= 3
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          // 球队
          Expanded(
            child: Row(
              children: [
                if (item.logo != null && item.logo!.isNotEmpty)
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.network(item.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const SizedBox()),
                  ),
                Expanded(
                  child: Text(
                    item.teamName ?? '-',
                    style: TextStyle(
                      color:
                          isCurrentTeam ? Colors.white : G5Colors.textPrimary,
                      fontSize: 12,
                      fontWeight:
                          isCurrentTeam ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // 赛
          SizedBox(
            width: 32,
            child: Text(
              '${item.total ?? 0}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: G5Colors.textSecondary, fontSize: 12),
            ),
          ),
          // 胜平负
          SizedBox(
            width: 48,
            child: Text(
              '${item.won ?? 0}/${item.draw ?? 0}/${item.loss ?? 0}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: G5Colors.textSecondary, fontSize: 10),
            ),
          ),
          // 积分
          SizedBox(
            width: 32,
            child: Text(
              '${item.points ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCurrentTeam ? G5Colors.accentBlue : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
