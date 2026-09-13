import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_post_model.dart';
import 'package:zogolive/models/g5_comment_model.dart';
import 'package:zogolive/models/g5_match_model.dart';
import 'package:zogolive/pages/football_detail_page.dart';
import 'package:zogolive/pages/team_detail_page.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_auth_manager.dart';
import 'package:zogolive/view_models/g5_community_detail_view_model.dart';
import 'package:zogolive/pages/login_page.dart';

class CommunityDetailPage extends G5BaseViewController {
  /// 帖子数据 - G5PostItem类型，从上一页面传入
  final G5PostItem post;

  const CommunityDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends G5BaseViewState<CommunityDetailPage> {
  /// 评论输入控制器 - TextEditingController类型，管理评论输入框文本
  final TextEditingController _commentController = TextEditingController();

  /// 点赞状态 - bool类型，当前用户是否已点赞
  bool _isLiked = false;

  /// 点赞数量 - int类型，帖子点赞总数
  int _likeCount = 0;

  /// 评论数量 - int类型，帖子评论总数，评论/回复成功后自动+1
  int _commentCount = 0;

  /// 是否正在输入 - bool类型，控制发送按钮显示
  bool _isTyping = false;

  /// 当前回复的一级评论 - G5CommentItem?类型，null表示直接评论帖子，非null表示回复该评论
  G5CommentItem? _replyTargetComment;

  /// 社区详情ViewModel - G5CommunityDetailViewModel类型，懒加载
  G5CommunityDetailViewModel? _viewModel;

  /// 懒加载初始化ViewModel
  G5CommunityDetailViewModel get viewModel {
    _viewModel ??= G5CommunityDetailViewModel();
    return _viewModel!;
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLike ?? false;
    _likeCount = widget.post.likeCount ?? 0;
    _commentCount = widget.post.commentCount ?? 0;
  }

  @override
  void initData() {
    _fetchPostDetail();
    _fetchComments();
  }

  /// 当前展示的帖子数据 - 优先使用接口返回的详情，兜底使用传参数据
  G5PostItem get post => viewModel.postDetail ?? widget.post;

  /// 请求帖子详情
  /// 通过ViewModel发起GET请求，成功后同步点赞数、评论数和点赞状态
  void _fetchPostDetail() async {
    final postId = widget.post.id ?? 0;
    if (postId == 0) return;
    final success = await viewModel.fetchPostDetail(postId: postId);
    if (!mounted) return;
    if (success) {
      final detail = viewModel.postDetail;
      if (detail != null) {
        setState(() {
          // 同步点赞状态、点赞数、评论数（同步底部评论条右侧的点赞按钮状态）
          _isLiked = detail.isLike ?? _isLiked;
          _likeCount = detail.likeCount ?? _likeCount;
          _commentCount = detail.commentCount ?? _commentCount;
        });
      }
    }
  }

  /// 请求评论列表数据
  /// 通过ViewModel发起GET请求，参数为当前帖子的ID
  void _fetchComments() async {
    final objectId = widget.post.id?.toString() ?? '';
    if (objectId.isEmpty) return;
    await viewModel.fetchComments(objectId: objectId);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 检查登录状态并执行操作
  /// 参数：action - VoidCallback，登录状态下执行的回调
  void _checkLoginAndDo(VoidCallback action) {
    if (G5AuthManager().isLoggedIn) {
      action();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// 切换帖子点赞状态
  /// 调用帖子点赞接口：未点赞时type=1点赞，已点赞时type=2取消点赞
  /// 成功后同步更新点赞状态和点赞数
  void _toggleLike() {
    _checkLoginAndDo(() async {
      final postId = post.id ?? 0;
      if (postId == 0) return;

      // 目标状态：当前未点赞则点赞(type=1)，已点赞则取消(type=2)
      final willLike = !_isLiked;
      final success = await viewModel.likePost(
        postId: postId,
        type: willLike ? 1 : 2,
      );
      if (!mounted) return;
      if (success) {
        setState(() {
          _isLiked = willLike;
          if (willLike) {
            _likeCount++;
          } else {
            _likeCount--;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(viewModel.errorMessage ?? '点赞失败，请重试')),
        );
      }
    });
  }

  /// 切换评论点赞状态
  /// 调用评论点赞接口，成功后同步更新该评论的点赞状态和数量
  /// 参数：comment - G5CommentItem，要点赞的评论数据
  void _toggleCommentSupport(G5CommentItem comment) {
    _checkLoginAndDo(() async {
      final commentId = comment.id ?? 0;
      if (commentId == 0) return;

      // 目标状态：当前未点赞则点赞，已点赞则取消
      final targetSupport = !(comment.isSupport == true);
      final success = await viewModel.supportComment(
        objectId: commentId,
        isSupport: targetSupport,
      );
      if (!mounted) return;
      if (success) {
        setState(() {
          comment.isSupport = targetSupport;
          comment.support = (comment.support ?? 0) + (targetSupport ? 1 : -1);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(viewModel.errorMessage ?? '点赞失败，请重试')),
        );
      }
    });
  }

  /// 提交评论/回复
  /// 根据是否有回复目标决定参数：直接评论帖子只传object_id和words，
  /// 回复一级评论额外传comment_id；成功后插入返回数据并刷新列表
  void _submitComment() {
    final words = _commentController.text.trim();
    if (words.isEmpty) return;
    final objectId = post.id ?? 0;
    if (objectId == 0) return;

    final commentId = _replyTargetComment?.id;

    _checkLoginAndDo(() async {
      final success = await viewModel.addComment(
        objectId: objectId,
        words: words,
        commentId: commentId,
      );
      if (!mounted) return;
      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _isTyping = false;
          _replyTargetComment = null;
          // 评论或回复成功后，评论数+1
          _commentCount += 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(viewModel.errorMessage ?? '评论失败，请重试')),
        );
      }
    });
  }

  /// 开始回复指定的一级评论
  /// 参数：comment - G5CommentItem，要回复的一级评论
  void _startReply(G5CommentItem comment) {
    _checkLoginAndDo(() {
      setState(() {
        _replyTargetComment = comment;
        _commentController.text = '';
      });
      FocusScope.of(context).requestFocus();
    });
  }

  /// 取消回复，切回直接评论帖子模式
  void _cancelReply() {
    setState(() {
      _replyTargetComment = null;
      _commentController.clear();
      _isTyping = false;
    });
    FocusScope.of(context).unfocus();
  }

  /// 点击比赛卡片跳转比赛详情
  /// 如果键盘弹出则先收起键盘，再将G5PostMatch转换为G5MatchItem后push
  /// 参数：postMatch - G5PostMatch，帖子关联的比赛数据
  void _pushToMatchDetail(G5PostMatch postMatch) {
    // 收起键盘
    FocusScope.of(context).unfocus();
    final match = _convertToMatchItem(postMatch);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FootballDetailPage(match: match),
    ));
  }

  /// 点击球队头像跳转球队详情
  /// 参数：teamId - int，球队ID；competitionId - int?，所属赛事ID
  void _pushToTeamDetail({required int teamId, int? competitionId}) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TeamDetailPage(
        teamId: teamId,
        competitionId: competitionId,
      ),
    ));
  }

  /// 将帖子关联比赛模型转换为比赛列表模型
  /// 字段一一对应映射，缺失字段为null
  /// 参数：postMatch - G5PostMatch，帖子关联的比赛数据
  /// 返回：G5MatchItem，比赛列表页使用的比赛模型
  G5MatchItem _convertToMatchItem(G5PostMatch postMatch) {
    return G5MatchItem(
      matchId: postMatch.matchId,
      competitionId: postMatch.competitionId,
      seasonId: postMatch.seasonId,
      statusId: postMatch.statusId,
      statusName: postMatch.statusName,
      competitionName: postMatch.competitionName,
      homeTeamId: postMatch.homeTeamId,
      homeTeamName: postMatch.homeTeamName,
      homeTeamLogo: postMatch.homeTeamLogo,
      awayTeamId: postMatch.awayTeamId,
      awayTeamName: postMatch.awayTeamName,
      awayTeamLogo: postMatch.awayTeamLogo,
      homeTeamScore: postMatch.homeScore,
      awayTeamScore: postMatch.awayScore,
    );
  }

  /// 格式化时间戳为相对时间描述
  /// 参数：timestamp - int?，Unix时间戳（秒级）
  /// 返回：String，如"3天前"、"2小时前"、"刚刚"
  String _formatTime(int? timestamp) {
    if (timestamp == null) return '刚刚';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
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
      title: Row(
        children: [
          if (post.author?.avatar != null &&
              post.author!.avatar!.isNotEmpty)
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(post.author!.avatar!),
            )
          else
            const CircleAvatar(
              radius: 14,
              backgroundColor: G5Colors.pitchElevated,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              post.author?.name ?? '球迷',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _checkLoginAndDo(() {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已关注')),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: G5Colors.accentBlue,
              minimumSize: const Size(60, 26),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('+ 关注',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return GestureDetector(
      // 点击空白处收起键盘
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author info
                    Row(
                      children: [
                        if (post.author?.avatar != null &&
                            post.author!.avatar!.isNotEmpty)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                NetworkImage(post.author!.avatar!),
                          )
                        else
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: G5Colors.pitchElevated,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    post.author?.name ?? '球迷',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: G5Colors.accentBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('创作者',
                                        style: TextStyle(
                                            color: G5Colors.accentBlue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatTime(post.createTime)} · IP属地未知',
                                style: const TextStyle(
                                    color: G5Colors.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Content
                    Text(
                      post.content ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    // Tags（话题）：优先取详情images第一个字符串切割，兜底用image
                    if (post.images != null && post.images!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildTags(post.images!.first),
                      )
                    else if (post.image != null &&
                        post.image!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildTags(post.image!),
                      ),

                    // Match Card (如果有关联比赛)，点击跳转比赛详情
                    if (post.match != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: GestureDetector(
                          onTap: () => _pushToMatchDetail(post.match!),
                          child: _buildMatchCard(post.match!),
                        ),
                      ),
                      
                    const SizedBox(height: 20),
                    // Stats
                    Row(
                      children: [
                        Text('$_commentCount 评论',
                            style: const TextStyle(
                                color: G5Colors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 16),
                        Text('$_likeCount 赞',
                            style: const TextStyle(
                                color: G5Colors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Comments Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Text('全部评论',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('(${viewModel.total})',
                        style: const TextStyle(
                            color: G5Colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // Comments List
            _buildCommentSliverList(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Bottom padding for input bar
            ),
          ],
        ),
        // Bottom Input Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: G5Colors.pitchCard,
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 回复模式提示Banner
                if (_replyTargetComment != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: G5Colors.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply,
                            color: G5Colors.accentBlue, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '回复 ${_replyTargetComment?.userName ?? ''}：',
                            style: const TextStyle(
                                color: G5Colors.accentBlue, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(Icons.close,
                              color: G5Colors.textSecondary, size: 16),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _checkLoginAndDo(() {
                            // Keep focus
                          });
                        },
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: G5Colors.pitchElevated,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _replyTargetComment != null
                                  ? '回复 ${_replyTargetComment?.userName ?? ''}...'
                                  : '说点什么吧...',
                              hintStyle: const TextStyle(
                                  color: G5Colors.textSecondary, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              isCollapsed: true,
                            ),
                            onTap: () {
                              _checkLoginAndDo(() {});
                            },
                            onChanged: (val) {
                              setState(() {
                                _isTyping = val.trim().isNotEmpty;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_isTyping)
                      ElevatedButton(
                        onPressed: _submitComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: G5Colors.accentBlue,
                          minimumSize: const Size(60, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('发送',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      )
                    else
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked
                              ? G5Colors.accentCrimson
                              : G5Colors.textSecondary,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  /// 构建评论列表Sliver
  /// 根据ViewModel的加载状态和数据返回不同内容
  /// 返回：Widget，评论列表或加载/空状态
  Widget _buildCommentSliverList() {
    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(
              color: G5Colors.accentBlue,
            ),
          ),
        ),
      );
    }

    if (viewModel.comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('暂无评论',
                style: TextStyle(color: G5Colors.textSecondary, fontSize: 14)),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _buildCommentItem(viewModel.comments[index]);
        },
        childCount: viewModel.comments.length,
      ),
    );
  }

  List<Widget> _buildTags(String rawTags) {
    String cleanStr = rawTags;
    if (cleanStr.contains('com/')) {
      cleanStr = cleanStr.substring(cleanStr.indexOf('com/') + 4);
    }
    List<String> tags =
        cleanStr.split(',').where((e) => e.trim().isNotEmpty).toList();

    return tags.map((tag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: G5Colors.accentBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          tag,
          style: const TextStyle(
              color: G5Colors.accentBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }

  Widget _buildMatchCard(G5PostMatch match) {
    return Container(
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
                if (match.homeTeamLogo != null && match.homeTeamLogo!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      if (match.homeTeamId != null) {
                        _pushToTeamDetail(
                          teamId: match.homeTeamId!,
                          competitionId: match.competitionId,
                        );
                      }
                    },
                    child: Image.network(match.homeTeamLogo!,
                        width: 24,
                        height: 24,
                        errorBuilder: (c, e, s) =>
                            const SizedBox(width: 24, height: 24)),
                  ),
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
                if (match.awayTeamLogo != null && match.awayTeamLogo!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      if (match.awayTeamId != null) {
                        _pushToTeamDetail(
                          teamId: match.awayTeamId!,
                          competitionId: match.competitionId,
                        );
                      }
                    },
                    child: Image.network(match.awayTeamLogo!,
                        width: 24,
                        height: 24,
                        errorBuilder: (c, e, s) =>
                            const SizedBox(width: 24, height: 24)),
                  ),
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
    );
  }

  /// 构建单个评论项（一级评论）
  /// 参数：comment - G5CommentItem，评论数据模型
  /// 返回：Widget，包含评论内容及其子评论列表
  Widget _buildCommentItem(G5CommentItem comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserAvatar(comment.userPic),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(comment.userName ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        _buildSupportButton(comment),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_formatTime(comment.commentTime),
                        style: const TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(comment.words ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _startReply(comment),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: G5Colors.pitchElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('回复',
                            style: TextStyle(
                                color: G5Colors.textSecondary, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 子评论列表
          if (comment.showChildComments != null &&
              comment.showChildComments!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: G5Colors.pitchElevated.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: comment.showChildComments!
                      .map((child) => _buildChildComment(child))
                      .toList(),
                ),
              ),
            ),
          // 剩余子评论数量提示
          if (comment.remainChildCommentCount != null &&
              comment.remainChildCommentCount! > 0)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: GestureDetector(
                onTap: () {
                  // TODO: 展开更多子评论
                },
                child: Text(
                  '查看剩余${comment.remainChildCommentCount}条回复',
                  style: const TextStyle(
                      color: G5Colors.accentBlue, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建子评论项（二级回复）
  /// 参数：comment - G5CommentItem，子评论数据模型
  /// 返回：Widget，包含回复用户名、目标用户名和回复内容
  Widget _buildChildComment(G5CommentItem comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(comment.userPic, radius: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: comment.userName ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (comment.replyToUserName != null &&
                                comment.replyToUserName!.isNotEmpty)
                              TextSpan(
                                text: ' 回复 ${comment.replyToUserName}',
                                style: const TextStyle(
                                    color: G5Colors.textSecondary,
                                    fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _buildSupportButton(comment, iconSize: 12),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.words ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户头像
  /// 参数：pic - String?，头像URL；radius - double，头像半径
  /// 返回：Widget，CircleAvatar组件
  Widget _buildUserAvatar(String? pic, {double radius = 16}) {
    if (pic != null && pic.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(pic),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: G5Colors.pitchElevated,
      child: Icon(Icons.person, color: Colors.white, size: radius + 4),
    );
  }

  /// 构建点赞按钮
  /// 参数：comment - G5CommentItem，评论数据；iconSize - double，图标大小
  /// 返回：Widget，可点击的点赞按钮及数量
  Widget _buildSupportButton(G5CommentItem comment, {double iconSize = 14}) {
    final isSupported = comment.isSupport == true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleCommentSupport(comment),
      child: Row(
        children: [
          Icon(
            isSupported ? Icons.favorite : Icons.favorite_border,
            color: isSupported
                ? G5Colors.accentCrimson
                : G5Colors.textSecondary,
            size: iconSize,
          ),
          const SizedBox(width: 4),
          Text('${comment.support ?? 0}',
              style: const TextStyle(
                  color: G5Colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
