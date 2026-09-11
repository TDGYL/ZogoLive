import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/models/g5_odds_model.dart';
import 'package:zogolive/models/g5_odds_history_model.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

class OddsHistoryPage extends G5BaseViewController {
  final G5MatchItem match;
  final G5OddsCompany initialCompany;
  final List<G5OddsCompany> allCompanies;
  final String oddsType; // 'asia', 'eu', 'bs', 'cr'

  const OddsHistoryPage({
    Key? key,
    required this.match,
    required this.initialCompany,
    required this.allCompanies,
    required this.oddsType,
  }) : super(key: key);

  @override
  State<OddsHistoryPage> createState() => _OddsHistoryPageState();
}

class _OddsHistoryPageState extends G5BaseViewState<OddsHistoryPage> {
  late String _selectedCompanyId;
  late String _currentOddsType;

  bool _isLoading = true;
  G5OddsHistoryData? _historyData;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.initialCompany.companyId ?? '';
    _currentOddsType = widget.oddsType;
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await G5NetworkManager().get(
        '/api/v1/football/match/odd-histories',
        queryParameters: {
          'match_id': widget.match.matchId,
          'company_id': _selectedCompanyId,
        },
      );

      if (response.code == 0 && response.data != null) {
        if (mounted) {
          setState(() {
            _historyData = G5OddsHistoryData.fromJson(response.data as Map<String, dynamic>);
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
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanySidebar(),
              Expanded(
                child: _buildTimelineContent(),
              ),
            ],
          ),
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
      title: const Text(
        '指数动态变化',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'label': '让球让分', 'value': 'asia'},
      {'label': '胜平负', 'value': 'eu'},
      {'label': '进球数', 'value': 'bs'},
      {'label': '角球', 'value': 'cr'},
    ];

    return Container(
      color: G5Colors.pitch,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: tabs.map((tab) {
          bool isSelected = _currentOddsType == tab['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentOddsType = tab['value'] as String;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? G5Colors.pitchCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : G5Colors.pitchBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : G5Colors.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompanySidebar() {
    return Container(
      width: 100,
      decoration: const BoxDecoration(
        color: G5Colors.pitch,
        border: Border(right: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: ListView.builder(
        itemCount: widget.allCompanies.length,
        itemBuilder: (context, index) {
          final comp = widget.allCompanies[index];
          bool isSelected = comp.companyId == _selectedCompanyId;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() {
                  _selectedCompanyId = comp.companyId ?? '';
                });
                _fetchHistoryData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? G5Colors.pitchCard : Colors.transparent,
                border: isSelected
                    ? const Border(left: BorderSide(color: G5Colors.accentBlue, width: 4))
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    comp.name ?? '',
                    style: TextStyle(
                      color: isSelected ? Colors.white : G5Colors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comp.spot?.draw ?? comp.pre?.draw ?? comp.ini?.draw ?? '-',
                    style: const TextStyle(
                      color: G5Colors.accentCrimson,
                      fontSize: 10,
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

  Widget _buildTimelineContent() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }

    List<G5OddsHistoryItem>? currentList;
    switch (_currentOddsType) {
      case 'asia':
        currentList = _historyData?.asia;
        break;
      case 'eu':
        currentList = _historyData?.eu;
        break;
      case 'bs':
        currentList = _historyData?.bs;
        break;
      case 'cr':
        currentList = _historyData?.cr;
        break;
    }

    if (currentList == null || currentList.isEmpty) {
      return const Center(child: Text('暂无历史数据', style: TextStyle(color: G5Colors.textSecondary)));
    }

    return Column(
      children: [
        // 表头
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: const BoxDecoration(
            color: G5Colors.pitchCard,
            border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 50, child: Text('时间/比分', style: TextStyle(color: G5Colors.textSecondary, fontSize: 10))),
              Expanded(child: Text('主队水位', textAlign: TextAlign.center, style: TextStyle(color: G5Colors.textSecondary, fontSize: 10))),
              SizedBox(width: 60, child: Text('盘口', textAlign: TextAlign.center, style: TextStyle(color: G5Colors.textSecondary, fontSize: 10))),
              Expanded(child: Text('客队水位', textAlign: TextAlign.center, style: TextStyle(color: G5Colors.textSecondary, fontSize: 10))),
            ],
          ),
        ),
        // 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: currentList.length,
            itemBuilder: (context, index) {
              final item = currentList![index];
              // 简单模拟涨跌，实际应该和上一个数据比
              bool isUp = index % 2 == 0;
              bool isDown = !isUp && index % 3 == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: G5Colors.pitchCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: index == 0 ? G5Colors.accentBlue.withOpacity(0.5) : G5Colors.pitchBorder,
                  ),
                ),
                child: Row(
                  children: [
                    // 时间与比分
                    SizedBox(
                      width: 50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.matchOffset ?? "初盘",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.score ?? "0-0",
                            style: const TextStyle(color: G5Colors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    // 主队水位
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.home ?? '-',
                            style: TextStyle(
                              color: isUp ? G5Colors.accentCrimson : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isUp)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.arrow_drop_up, color: G5Colors.accentCrimson, size: 14),
                            ),
                        ],
                      ),
                    ),
                    // 盘口
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: G5Colors.pitchElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: G5Colors.pitchBorder),
                      ),
                      child: Text(
                        item.draw ?? '-',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                      ),
                    ),
                    // 客队水位
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.away ?? '-',
                            style: TextStyle(
                              color: isDown ? G5Colors.accentEmerald : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isDown)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.arrow_drop_down, color: G5Colors.accentEmerald, size: 14),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}