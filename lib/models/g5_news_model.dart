/// 资讯模型
class G5NewsModel {
  /// 资讯标题
  String title;

  /// 发布时间
  String publishTime;

  /// 阅读量
  String reads;

  /// 封面图 URL
  String coverUrl;

  /// 来源/标签
  String source;

  /// 是否是头条(大图)
  bool isHeadline;

  G5NewsModel({
    required this.title,
    required this.publishTime,
    required this.reads,
    required this.coverUrl,
    required this.source,
    this.isHeadline = false,
  });

  /// 从 JSON 解析
  factory G5NewsModel.fromJson(Map<String, dynamic> json) {
    return G5NewsModel(
      title: json['title'] as String? ?? '',
      publishTime: json['publishTime'] as String? ?? '',
      reads: json['reads'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      source: json['source'] as String? ?? '',
      isHeadline: json['isHeadline'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'publishTime': publishTime,
      'reads': reads,
      'coverUrl': coverUrl,
      'source': source,
      'isHeadline': isHeadline,
    };
  }
}
