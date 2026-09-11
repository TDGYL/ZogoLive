import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/models/g5_process_model.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

class FootballDetailPage extends G5BaseViewController {
  final G5MatchItem match;

  const FootballDetailPage({Key? key, required this.match}) : super(key: key);

  @override
  State<FootballDetailPage> createState() => _FootballDetailPageState();
}

class _FootballDetailPageState extends G5BaseViewState<FootballDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['事件', '数据', '指数', '历史对战'];

  G5ProcessData? _processData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchProcessData();
  }

  Future<void> _fetchProcessData() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/v1/football/match/process',
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
          widget.match.competitionName ?? '联赛',
          style: const TextStyle(
            color: G5Colors.accentEmerald,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.star_border, color: G5Colors.textSecondary),
          onPressed: () {},
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
    final match = widget.match;
    bool isLive =
        match.statusId == 2 || match.statusId == 3 || match.statusId == 4;

    String statusDisplay = match.statusName ?? '';
    if (isLive && match.minutes != null && match.minutes!.isNotEmpty) {
      statusDisplay = "${match.minutes}' LIVE";
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
              // 主队
              Expanded(
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
              // 客队
              Expanded(
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
            ],
          ),
          // 注意：去掉了哈兰德和贝林厄姆的比赛事件部分
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
        const Center(
            child: Text('指数 (待开发)',
                style: TextStyle(color: G5Colors.textSecondary))),
        const Center(
            child: Text('历史对战 (待开发)',
                style: TextStyle(color: G5Colors.textSecondary))),
      ],
    );
  }

  Widget _buildIncidentsTab() {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    if (_processData?.incidents == null || _processData!.incidents!.isEmpty) {
      return const Center(
          child:
              Text('暂无事件数据', style: TextStyle(color: G5Colors.textSecondary)));
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
              // 主队区域
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
              // 客队区域
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
              Text('暂无统计数据', style: TextStyle(color: G5Colors.textSecondary)));
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
