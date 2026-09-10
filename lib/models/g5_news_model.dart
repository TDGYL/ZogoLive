/// 资讯模型 - JSON 映射
class G5NewsData {
  int? total;
  List<G5NewsItem>? results;

  G5NewsData({this.total, this.results});

  factory G5NewsData.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List?;
    List<G5NewsItem> items = [];
    if (list != null) {
      items = list.map((e) => G5NewsItem.fromJson(e)).toList();
    }
    return G5NewsData(
      total: json['total'] as int?,
      results: items,
    );
  }
}

class G5NewsItem {
  int? id;
  String? title;
  String? cover;
  int? type;
  String? author;
  String? authorAvatar;
  String? source;
  String? sourceUrl;
  int? createdAt;
  int? onlineAt;
  int? offlineAt;
  int? status;
  String? content;
  bool? isSupport;
  int? videoDirection;
  String? h5Url;
  bool? isFollow;
  int? contentCounts;
  int? videoHeight;
  int? videoWidth;
  bool? living;
  int? expertId;
  String? patch;
  String? groupId;
  int? weight;
  String? verticalCoverUrl;
  int? intelligenceCounts;

  G5NewsItem({
    this.id,
    this.title,
    this.cover,
    this.type,
    this.author,
    this.authorAvatar,
    this.source,
    this.sourceUrl,
    this.createdAt,
    this.onlineAt,
    this.offlineAt,
    this.status,
    this.content,
    this.isSupport,
    this.videoDirection,
    this.h5Url,
    this.isFollow,
    this.contentCounts,
    this.videoHeight,
    this.videoWidth,
    this.living,
    this.expertId,
    this.patch,
    this.groupId,
    this.weight,
    this.verticalCoverUrl,
    this.intelligenceCounts,
  });

  factory G5NewsItem.fromJson(Map<String, dynamic> json) {
    return G5NewsItem(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      title: json['title'] as String?,
      cover: json['cover'] as String?,
      type: json['type'] != null ? (json['type'] as num).toInt() : null,
      author: json['author'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      source: json['source'] as String?,
      sourceUrl: json['source_url'] as String?,
      createdAt: json['created_at'] != null ? (json['created_at'] as num).toInt() : null,
      onlineAt: json['online_at'] != null ? (json['online_at'] as num).toInt() : null,
      offlineAt: json['offline_at'] != null ? (json['offline_at'] as num).toInt() : null,
      status: json['status'] != null ? (json['status'] as num).toInt() : null,
      content: json['content'] as String?,
      isSupport: json['is_support'] as bool?,
      videoDirection: json['video_direction'] != null ? (json['video_direction'] as num).toInt() : null,
      h5Url: json['h5_url'] as String?,
      isFollow: json['is_follow'] as bool?,
      contentCounts: json['content_counts'] != null ? (json['content_counts'] as num).toInt() : null,
      videoHeight: json['video_height'] != null ? (json['video_height'] as num).toInt() : null,
      videoWidth: json['video_width'] != null ? (json['video_width'] as num).toInt() : null,
      living: json['living'] as bool?,
      expertId: json['expert_id'] != null ? (json['expert_id'] as num).toInt() : null,
      patch: json['patch'] as String?,
      groupId: json['group_id'] as String?,
      weight: json['weight'] != null ? (json['weight'] as num).toInt() : null,
      verticalCoverUrl: json['vertical_cover_url'] as String?,
      intelligenceCounts: json['intelligence_counts'] != null ? (json['intelligence_counts'] as num).toInt() : null,
    );
  }
}
