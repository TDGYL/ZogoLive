/// 社区评论列表Stats模型 - 包含评论列表及总数
/// 字段说明：
/// - total: int? 评论总数
/// - results: List<G5CommentItem>? 评论Stats数组
class G5CommentData {
  /// 评论总数 - int类型，表示评论的总数量
  int? total;

  /// 评论Stats数组 - List<G5CommentItem>类型，包含所有评论项
  List<G5CommentItem>? results;

  G5CommentData({this.total, this.results});

  /// 从JSON映射创建G5CommentData
  /// 参数：json - Map<String, dynamic> 服务端返回的JSONStats
  /// 返回：G5CommentData 实例
  factory G5CommentData.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List?;
    return G5CommentData(
      total: json['total'] as int?,
      results: list
          ?.map((e) => G5CommentItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

/// 社区评论项模型 - 单条评论/回复的Stats结构
/// 评论和回复共用同一结构，通过 parent_id 和 is_reply_child 区分层级
class G5CommentItem {
  /// 评论ID - int类型，唯一标识该条评论
  int? id;

  /// 关联对象ID - int类型，评论所属帖子的ID
  int? objectId;

  /// 关联对象类型 - int类型，表示评论所属的对象类型（如帖子=3）
  int? objectType;

  /// 评论用户ID - int类型，发表该评论的用户ID
  int? userId;

  /// 父评论ID - int类型，一级评论为0，回复则对应一级评论的ID
  int? parentId;

  /// 回复目标用户ID - int类型，回复某用户时该用户的ID，一级评论为0
  int? replyToUser;

  /// 回复目标评论ID - int类型，回复某评论时该评论的ID，一级评论为0
  int? replyToComment;

  /// 评论内容 - String类型，评论的文字内容
  String? words;

  /// 点赞数 - int类型，该评论获得的点赞数量
  int? support;

  /// 是否为子回复 - int类型，0表示一级评论，1表示二级回复
  int? isReplyChild;

  /// 评论时间 - int类型，Unix时间戳（秒级）
  int? commentTime;

  /// 删除时间 - String?类型，评论被删除的时间，未删除为null
  String? deletedAt;

  /// 用户头像URL - String类型，评论用户的头像图片地址
  String? userPic;

  /// 用户名 - String类型，评论用户的昵称
  String? userName;

  /// 当前用户是否已点赞 - bool类型，true表示已点赞
  bool? isSupport;

  /// 剩余子评论数量 - int类型，未展示的回复数量
  int? remainChildCommentCount;

  /// 展示的子评论列表 - List<G5CommentItem>?类型，该评论下的回复列表
  List<G5CommentItem>? showChildComments;

  /// 回复目标用户名 - String类型，回复某用户时该用户的昵称
  String? replyToUserName;

  G5CommentItem({
    this.id,
    this.objectId,
    this.objectType,
    this.userId,
    this.parentId,
    this.replyToUser,
    this.replyToComment,
    this.words,
    this.support,
    this.isReplyChild,
    this.commentTime,
    this.deletedAt,
    this.userPic,
    this.userName,
    this.isSupport,
    this.remainChildCommentCount,
    this.showChildComments,
    this.replyToUserName,
  });

  /// 从JSON映射创建G5CommentItem
  /// 参数：json - Map<String, dynamic> 单条评论的JSONStats
  /// 返回：G5CommentItem 实例
  factory G5CommentItem.fromJson(Map<String, dynamic> json) {
    var childList = json['show_child_comments'] as List?;
    return G5CommentItem(
      id: json['id'] as int?,
      objectId: json['object_id'] as int?,
      objectType: json['object_type'] as int?,
      userId: json['user_id'] as int?,
      parentId: json['parent_id'] as int?,
      replyToUser: json['reply_to_user'] as int?,
      replyToComment: json['reply_to_comment'] as int?,
      words: json['words'] as String?,
      support: json['support'] as int?,
      isReplyChild: json['is_reply_child'] as int?,
      commentTime: json['comment_time'] as int?,
      deletedAt: json['deleted_at'] as String?,
      userPic: json['user_pic'] as String?,
      userName: json['user_name'] as String?,
      isSupport: json['is_support'] as bool?,
      remainChildCommentCount: json['remain_child_comment_count'] as int?,
      replyToUserName: json['reply_to_user_name'] as String?,
      showChildComments: childList
          ?.map((e) => G5CommentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
