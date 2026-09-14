import 'package:flutter/material.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/models/g5_match_model.dart';
import 'package:livespeed/pages/post_match_search_page.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_auth_manager.dart';

import 'package:livespeed/utils/g5_network_manager.dart';

class PostCommunityPage extends G5BaseViewController {
  const PostCommunityPage({Key? key}) : super(key: key);

  @override
  State<PostCommunityPage> createState() => _PostCommunityPageState();
}

class _PostCommunityPageState extends G5BaseViewState<PostCommunityPage> {
  final TextEditingController _contentController = TextEditingController();

  // 战术标签 (Multi)
  final List<String> _strategyTags = ['Top Clash', 'Tactical Review'];
  final List<String> _selectedStrategyTags = [];

  // 话题分类 (Multi)
  final List<String> _topics = [
    '🔥 Match Talk',
    '📊 Tactics',
    '📰 Transfers',
    '👟 Gear',
    '🏆 Title Race'
  ];
  final List<String> _selectedTopics = [];

  // 关联的比赛
  G5MatchItem? _selectedMatch;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handlePublish() async {
    final textContent = _contentController.text.trim();
    if (textContent.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic must be over 10 characters')),
      );
      return;
    }

    // 拼接选中的Tactical Review标签
    String finalContent = textContent;
    if (_selectedStrategyTags.isNotEmpty) {
      final tagsString = _selectedStrategyTags.map((tag) => '#$tag').join(' ');
      finalContent += ' $tagsString';
    }

    // 处理话题分类参数（images字段）
    List<String> images = [];
    if (_selectedTopics.isNotEmpty) {
      images.add(_selectedTopics.join(','));
    }

    // 构建参数
    final Map<String, dynamic> params = {
      "id": 0,
      "content": finalContent,
      "images": images,
    };

    // 若有Match则追加比赛参数
    if (_selectedMatch != null && _selectedMatch!.matchId != null) {
      params["match_type"] = 1;
      params["match_id"] = _selectedMatch!.matchId;
    }

    try {
      print("fabu=======${params}");
      final response = await G5NetworkManager().post(
        '/api/livespeed/community/save',
        data: params,
      );

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Published！')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Publish failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publish failed, check network')),
        );
      }
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      leading: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel',
            style: TextStyle(color: G5Colors.textSecondary, fontSize: 16)),
      ),
      leadingWidth: 80,
      title: const Text(
        'New Post',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
          child: ElevatedButton.icon(
            onPressed: _handlePublish,
            style: ElevatedButton.styleFrom(
              backgroundColor: G5Colors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.send, size: 12),
            label: const Text('Publish',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    final user = G5AuthManager().currentUser;
    final userName = user?.nickname ?? 'Fan';
    final userAvatar = user?.avatar ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息栏
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: G5Colors.accentBlue.withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: userAvatar.isNotEmpty
                      ? Image.network(userAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.person, color: Colors.grey))
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: G5Colors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: G5Colors.accentBlue.withOpacity(0.2)),
                        ),
                        child: const Text('LV.6 Senior Fan',
                            style: TextStyle(
                                color: G5Colors.accentBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.public,
                          color: G5Colors.textSecondary, size: 10),
                      SizedBox(width: 4),
                      Text('Public · LiveSpeed Community',
                          style: TextStyle(
                              color: G5Colors.textSecondary, fontSize: 12)),
                    ],
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 20),

          // 输入区域
          Container(
            decoration: BoxDecoration(
              color: G5Colors.pitchCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: G5Colors.pitchBorder),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts, tactical analysis, or discuss matches with fans...',
                    hintStyle:
                        TextStyle(color: G5Colors.textSecondary, fontSize: 16),
                    border: InputBorder.none,
                    counterStyle:
                        TextStyle(color: G5Colors.textSecondary, fontSize: 12),
                  ),
                ),
                const Divider(color: G5Colors.pitchBorder, height: 24),
                // 战术标签Multi
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _strategyTags.map((tag) {
                    final isSelected = _selectedStrategyTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedStrategyTags.remove(tag);
                          } else {
                            _selectedStrategyTags.add(tag);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? G5Colors.accentBlue.withOpacity(0.2)
                              : G5Colors.pitchElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isSelected
                                  ? G5Colors.accentBlue
                                  : Colors.transparent),
                        ),
                        child: Text(
                          '# $tag',
                          style: TextStyle(
                            color: isSelected
                                ? G5Colors.accentBlue
                                : G5Colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Match
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield, color: G5Colors.accentBlue, size: 14),
                  SizedBox(width: 4),
                  Text('Match Teams',
                      style: TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Help recommend to same-team fans',
                  style: TextStyle(
                      color: G5Colors.textSecondary.withOpacity(0.6),
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),

          if (_selectedMatch == null)
            GestureDetector(
              onTap: () async {
                final match = await Navigator.of(context).push<G5MatchItem>(
                  MaterialPageRoute(
                      builder: (_) => const PostMatchSearchPage()),
                );
                if (match != null) {
                  setState(() {
                    _selectedMatch = match;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: G5Colors.pitchCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: G5Colors.accentBlue.withOpacity(0.5),
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: G5Colors.accentBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.add, color: G5Colors.accentBlue),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Match',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Link a match to show a match card',
                                style: TextStyle(
                                    color: G5Colors.textSecondary,
                                    fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: G5Colors.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Text('Select',
                              style: TextStyle(
                                  color: G5Colors.accentBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right,
                              color: G5Colors.accentBlue, size: 14),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          else
            _buildSelectedMatchCard(),

          const SizedBox(height: 20),

          // 话题分类
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tag, color: G5Colors.accentBlue, size: 14),
                        SizedBox(width: 4),
                        Text('Add Topics',
                            style: TextStyle(
                                color: G5Colors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('Multi',
                        style: TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _topics.map((topic) {
                    final isSelected = _selectedTopics.contains(topic);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTopics.remove(topic);
                          } else {
                            _selectedTopics.add(topic);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? G5Colors.accentBlue
                              : G5Colors.pitchElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          topic,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : G5Colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: G5Colors.pitchElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedMatch?.competitionName ?? '',
                  style: const TextStyle(
                      color: G5Colors.textSecondary, fontSize: 12)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final match =
                          await Navigator.of(context).push<G5MatchItem>(
                        MaterialPageRoute(
                            builder: (_) => const PostMatchSearchPage()),
                      );
                      if (match != null) {
                        setState(() {
                          _selectedMatch = match;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          const Icon(Icons.sync, color: Colors.white, size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMatch = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: G5Colors.accentCrimson.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close,
                          color: G5Colors.accentCrimson, size: 14),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (_selectedMatch?.homeTeamLogo != null &&
                        _selectedMatch!.homeTeamLogo!.isNotEmpty)
                      Image.network(_selectedMatch!.homeTeamLogo!,
                          width: 32,
                          height: 32,
                          errorBuilder: (c, e, s) =>
                              const SizedBox(width: 32, height: 32)),
                    const SizedBox(height: 4),
                    Text(_selectedMatch?.homeTeamName ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS',
                    style: TextStyle(
                        color: G5Colors.accentGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (_selectedMatch?.awayTeamLogo != null &&
                        _selectedMatch!.awayTeamLogo!.isNotEmpty)
                      Image.network(_selectedMatch!.awayTeamLogo!,
                          width: 32,
                          height: 32,
                          errorBuilder: (c, e, s) =>
                              const SizedBox(width: 32, height: 32)),
                    const SizedBox(height: 4),
                    Text(_selectedMatch?.awayTeamName ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
