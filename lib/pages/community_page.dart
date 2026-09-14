import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/models/g5_post_model.dart';
import 'package:livespeed/pages/login_page.dart';
import 'package:livespeed/pages/community_detail_page.dart';
import 'package:livespeed/pages/post_community_page.dart';
import 'package:livespeed/utils/g5_auth_manager.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_event_bus.dart';
import 'package:livespeed/utils/g5_network_manager.dart';

class CommunityPage extends G5BaseViewController {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends G5BaseViewState<CommunityPage> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<G5PostItem> posts = [];
  int _page = 1;
  final int _size = 10;

  /// 帖子DeleteEvents订阅 - StreamSubscription?类型，监听详情页Delete帖子通知
  StreamSubscription? _postDeleteSubscription;

  bool _isFirstLoading = true;

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    // 监听帖子DeleteEvents，同步从列表中移除被Delete的帖子
    _postDeleteSubscription =
        G5EventBus().on<PostDeleteEvent>().listen((event) {
      if (mounted) {
        setState(() {
          posts.removeWhere((item) => item.id == event.postId);
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshController.callRefresh();
    });
  }

  @override
  void dispose() {
    _postDeleteSubscription?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _page = 1;
    } else {
      _page++;
    }

    final params = {
      "type": 2, // 社区列表固定传 2
      "page": _page,
      "size": _size,
      "match_type": 1,
    };

    final response = await G5NetworkManager().get(
      '/api/livespeed/community/list',
      queryParameters: params,
    );
    if (response.isSuccess) {
      final data = G5PostData.fromJson(response.data);
      final newItems = data.results ?? [];
      setState(() {
        if (isRefresh) {
          posts = newItems;
        } else {
          posts.addAll(newItems);
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

  // 辅助方法：时间戳转相对时间
  String _formatPublishTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(publishDate);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    } else {
      return '${publishDate.month}-${publishDate.day}';
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
              color: G5Colors.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: G5Colors.accentGold.withOpacity(0.3)),
            ),
            child:
                const Icon(Icons.groups, color: G5Colors.accentGold, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LiveSpeed·Community',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '240,000+ tactical fans',
                style: TextStyle(fontSize: 10, color: G5Colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
          child: ElevatedButton.icon(
            onPressed: () {
              if (G5AuthManager().isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PostCommunityPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in first')),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: G5Colors.accentEmerald,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.edit, size: 12),
            label: const Text('Post',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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
        noMoreText: 'No more',
        failedText: 'Refresh failed',
        messageText: 'Last updated %T',
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
        messageStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 10),
      ),
      footer: const ClassicFooter(
        dragText: 'Pull up to load',
        armedText: 'Release to load',
        readyText: 'Loading...',
        processingText: 'Loading...',
        processedText: 'Loaded',
        noMoreText: 'No more data',
        failedText: 'Load failed',
        messageText: 'Last updated %T',
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
        messageStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 10),
      ),
      onRefresh: () => _fetchData(isRefresh: true),
      onLoad: () => _fetchData(isRefresh: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(posts[index]);
        },
      ),
    );
  }

  /// 显示Report二次确认弹窗
  /// 点击"Cancel"关闭弹窗，点击"Report"NoticeReported
  void _showReportConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: G5Colors.pitchCard,
          title: const Text('Notice', style: TextStyle(color: Colors.white)),
          content: const Text('Report this post?',
              style: TextStyle(color: G5Colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: G5Colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 关闭弹窗
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reported')),
                );
              },
              child: const Text('Report',
                  style: TextStyle(color: G5Colors.accentEmerald)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(G5PostItem post) {
    final author = post.author;
    final match = post.match;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CommunityDetailPage(post: post),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: G5Colors.accentGold.withOpacity(0.4)),
                      color: G5Colors.pitchElevated,
                    ),
                    child: author?.avatar != null && author!.avatar!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              author.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person,
                                      color: G5Colors.textSecondary, size: 20),
                            ),
                          )
                        : const Icon(Icons.person,
                            color: G5Colors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatPublishTime(post.createTime)} · User', // 假设没有 location，用默认文本
                        style: const TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // 作者本人时隐藏Report按钮
              if (!(author != null &&
                  G5AuthManager().isLoggedIn &&
                  author.id == G5AuthManager().currentUser?.id))
                GestureDetector(
                  onTap: () => _showReportConfirmDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: G5Colors.pitchElevated,
                      border: Border.all(color: G5Colors.pitchBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Report',
                      style: TextStyle(
                        color: G5Colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content ?? '',
            style: const TextStyle(
              color: G5Colors.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (post.image != null && post.image!.isNotEmpty) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // 如果包含 com/ 则截取后面的字符串
                String rawTags = post.image!;
                if (rawTags.contains('com/')) {
                  rawTags = rawTags.substring(rawTags.indexOf('com/') + 4);
                }
                
                final tags = rawTags.split(',');
                final maxTagWidth = constraints.maxWidth * 0.75;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.where((t) => t.trim().isNotEmpty).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: G5Colors.accentBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: G5Colors.accentBlue.withOpacity(0.3)),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxTagWidth),
                        child: Text(
                          tag.trim(),
                          style: const TextStyle(
                            color: G5Colors.accentBlue,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          if (match != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: G5Colors.pitchElevated,
                border:
                    Border.all(color: G5Colors.accentEmerald.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer,
                      color: G5Colors.accentEmerald, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Match: ${match.homeTeamName} ${match.homeScore} - ${match.awayScore} ${match.awayTeamName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: G5Colors.textSecondary, size: 16),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}
