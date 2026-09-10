/// 社区帖子模型
class G5PostModel {
  /// 用户昵称
  String authorName;

  /// 用户头像 URL
  String authorAvatarUrl;

  /// 发布时间 (如 20分钟前)
  String publishTime;

  /// 发布地点 (如 马德里)
  String location;

  /// 用户头衔 (如 Pro 分析师)
  String title;

  /// 帖子内容
  String content;

  /// 配图 URL 列表
  List<String> imageUrls;

  /// 关联比赛信息
  String relatedMatch;

  G5PostModel({
    required this.authorName,
    required this.authorAvatarUrl,
    required this.publishTime,
    required this.location,
    required this.title,
    required this.content,
    required this.imageUrls,
    this.relatedMatch = '',
  });

  /// 从 JSON 解析
  factory G5PostModel.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['imageUrls'] != null) {
      imgs = List<String>.from(json['imageUrls'] as List);
    }

    return G5PostModel(
      authorName: json['authorName'] as String? ?? '',
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      publishTime: json['publishTime'] as String? ?? '',
      location: json['location'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrls: imgs,
      relatedMatch: json['relatedMatch'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'publishTime': publishTime,
      'location': location,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'relatedMatch': relatedMatch,
    };
  }
}
