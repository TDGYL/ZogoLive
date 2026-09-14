import 'package:livespeed/base/g5_base_view_model.dart';
import 'package:livespeed/models/g5_comment_model.dart';
import 'package:livespeed/models/g5_post_model.dart';
import 'package:livespeed/utils/g5_network_manager.dart';

/// 社区详情页 ViewModel - 负责帖子详情、评论列表的Stats请求与状态管理
/// 遵循MVVM架构，隔离业务逻辑与视图层
class G5CommunityDetailViewModel extends G5BaseViewModel {
  /// 评论列表Stats - List<G5CommentItem>类型，存储一级评论
  List<G5CommentItem> _comments = [];

  /// 评论总数 - int类型，服务端返回的评论总条数
  int _total = 0;

  /// 帖子详情Stats - G5PostItem?类型，请求成功后存储帖子详情
  G5PostItem? _postDetail;

  /// 请求错误信息 - String?类型，Request failed时的错误描述，成功时为null
  String? _errorMessage;

  /// 获取评论列表Stats
  List<G5CommentItem> get comments => _comments;

  /// 获取评论总数
  int get total => _total;

  /// 获取帖子详情Stats
  G5PostItem? get postDetail => _postDetail;

  /// 获取错误信息
  String? get errorMessage => _errorMessage;

  /// 请求帖子详情
  /// 接口：GET /api/livespeed/community/detail
  /// 参数：postId - int类型，帖子ID
  /// 返回：Future<bool>，true表示请求成功，false表示失败
  Future<bool> fetchPostDetail({required int postId}) async {
    _errorMessage = null;

    final response = await G5NetworkManager().get(
      '/api/livespeed/community/detail',
      queryParameters: {
        'id': postId,
      },
    );

    if (response.isSuccess && response.data != null) {
      _postDetail = G5PostItem.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Request failed';
      notifyListeners();
      return false;
    }
  }

  /// 请求评论列表
  /// 接口：GET /api/livespeed/community/comment/list
  /// 参数：objectId - String类型，帖子的ID
  /// 返回：Future<bool>，true表示请求成功，false表示失败
  Future<bool> fetchComments({required String objectId}) async {
    setLoading(true);
    _errorMessage = null;

    final response = await G5NetworkManager().get(
      '/api/livespeed/community/comment/list',
      queryParameters: {
        'object_id': objectId,
      },
    );

    setLoading(false);

    if (response.isSuccess && response.data != null) {
      final data = G5CommentData.fromJson(response.data as Map<String, dynamic>);
      _comments = data.results ?? [];
      _total = data.total ?? 0;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Request failed';
      notifyListeners();
      return false;
    }
  }

  /// 发表评论/回复
  /// 接口：POST /api/livespeed/community/comment/add
  /// 参数：objectId - int类型，帖子ID；words - String类型，评论内容；
  ///       commentId - int?类型，回复时的一级评论ID，直接评论帖子时不传
  /// 返回：Future<bool>，true表示提交成功，false表示失败
  Future<bool> addComment({
    required int objectId,
    required String words,
    int? commentId,
  }) async {
    setLoading(true);
    _errorMessage = null;

    final params = <String, dynamic>{
      'object_id': objectId,
      'words': words,
    };
    if (commentId != null) {
      params['comment_id'] = commentId;
    }

    final response = await G5NetworkManager().post(
      '/api/livespeed/community/comment/add',
      data: params,
    );

    setLoading(false);

    if (response.isSuccess && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final commentJson = data['comment'] as Map<String, dynamic>?;
      if (commentJson != null) {
        final newComment = G5CommentItem.fromJson(commentJson);
        _insertComment(newComment, commentId: commentId);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Comment failed';
      notifyListeners();
      return false;
    }
  }

  /// 插入新评论到列表
  /// 直接评论帖子时插入到一级评论列表头部并总数+1；
  /// 回复一级评论时插入到对应一级评论的子评论列表尾部
  /// 参数：comment - G5CommentItem，服务端返回的新评论Stats；
  ///       commentId - int?，回复时的一级评论ID
  void _insertComment(G5CommentItem comment, {int? commentId}) {
    if (commentId == null) {
      // 直接评论帖子：插入一级评论列表头部
      _comments.insert(0, comment);
      _total += 1;
      return;
    }

    // 回复一级评论：插入到对应一级评论的子评论列表
    for (final item in _comments) {
      if (item.id == commentId) {
        item.showChildComments = [...(item.showChildComments ?? []), comment];
        break;
      }
    }
  }

  /// 评论点赞/Cancel点赞
  /// 接口：POST /api/livespeed/support
  /// 参数：objectId - int类型，评论ID；isSupport - bool类型，true点赞/falseCancel
  /// object_type固定为3（评论类型）
  /// 返回：Future<bool>，true表示成功，false表示失败
  Future<bool> supportComment({
    required int objectId,
    required bool isSupport,
  }) async {
    _errorMessage = null;

    final response = await G5NetworkManager().post(
      '/api/livespeed/support',
      data: {
        'object_id': objectId,
        'object_type': 3,
        'is_support': isSupport,
      },
    );

    if (response.isSuccess) {
      return true;
    } else {
      _errorMessage = response.message ?? 'Like failed';
      notifyListeners();
      return false;
    }
  }

  /// 帖子点赞/Cancel点赞
  /// 接口：POST /api/livespeed/community/like
  /// 参数：postId - int类型，帖子ID；type - int类型，1表示点赞，2表示Cancel点赞
  /// 返回：Future<bool>，true表示成功，false表示失败
  Future<bool> likePost({required int postId, required int type}) async {
    _errorMessage = null;

    final response = await G5NetworkManager().post(
      '/api/livespeed/community/like',
      data: {
        'post_id': postId,
        'type': type,
      },
    );

    if (response.isSuccess) {
      return true;
    } else {
      _errorMessage = response.message ?? 'Like failed';
      notifyListeners();
      return false;
    }
  }

  /// 删除帖子
  /// 接口：POST /api/livespeed/community/delete
  /// 参数：postId - int类型，帖子ID
  /// 返回：Future<bool>，true表示删除成功，false表示失败
  Future<bool> deletePost({required int postId}) async {
    _errorMessage = null;

    final response = await G5NetworkManager().post(
      '/api/livespeed/community/delete',
      data: {
        'id': postId,
      },
    );

    if (response.isSuccess) {
      return true;
    } else {
      _errorMessage = response.message ?? 'Delete failed';
      notifyListeners();
      return false;
    }
  }

  /// 关注/Cancel关注帖子作者
  /// 接口：POST /api/livespeed/imchat/subscribe
  /// 参数：targetId - int类型，作者用户ID；type - int类型，1关注，2Cancel关注
  /// 返回：Future<bool>，true表示成功，false表示失败
  Future<bool> toggleFollowAuthor({
    required int targetId,
    required int type,
  }) async {
    _errorMessage = null;

    final response = await G5NetworkManager().post(
      '/api/livespeed/imchat/subscribe',
      data: {
        'target_id': targetId,
        'type': type,
      },
    );

    if (response.isSuccess) {
      return true;
    } else {
      _errorMessage = response.message ?? 'Operation failed';
      notifyListeners();
      return false;
    }
  }
}
