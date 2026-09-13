/// 社区帖子模型 - JSON 映射
class G5PostData {
  int? total;
  List<G5PostItem>? results;

  G5PostData({this.total, this.results});

  factory G5PostData.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List?;
    List<G5PostItem> items = [];
    if (list != null) {
      items = list.map((e) => G5PostItem.fromJson(e)).toList();
    }
    return G5PostData(
      total: json['total'] as int?,
      results: items,
    );
  }
}

class G5PostItem {
  int? id;
  String? content;
  String? image;
  List<String>? images;
  int? likeCount;
  int? commentCount;
  int? createTime;
  G5PostAuthor? author;
  G5PostMatch? match;
  bool? isLike;

  G5PostItem({
    this.id,
    this.content,
    this.image,
    this.images,
    this.likeCount,
    this.commentCount,
    this.createTime,
    this.author,
    this.match,
    this.isLike,
  });

  factory G5PostItem.fromJson(Map<String, dynamic> json) {
    return G5PostItem(
      id: json['id'] as int?,
      content: json['content'] as String?,
      image: json['image'] as String?,
      images: (json['images'] as List?)
          ?.map((e) => e as String)
          .toList(),
      likeCount: json['like_count'] as int?,
      commentCount: json['comment_count'] as int?,
      createTime: json['create_time'] as int?,
      author:
          json['author'] != null ? G5PostAuthor.fromJson(json['author']) : null,
      match: json['match'] != null ? G5PostMatch.fromJson(json['match']) : null,
      isLike: json['is_like'] as bool?,
    );
  }
}

class G5PostAuthor {
  int? id;
  String? name;
  bool? isSubscribe;
  String? avatar;
  int? memberId;

  G5PostAuthor({
    this.id,
    this.name,
    this.isSubscribe,
    this.avatar,
    this.memberId,
  });

  factory G5PostAuthor.fromJson(Map<String, dynamic> json) {
    return G5PostAuthor(
      id: json['id'] as int?,
      name: json['name'] as String?,
      isSubscribe: json['is_subscribe'] as bool?,
      avatar: json['avatar'] as String?,
      memberId: json['member_id'] as int?,
    );
  }
}

class G5PostMatch {
  int? matchType;
  int? matchId;
  int? competitionId;
  int? seasonId;
  int? startTime;
  int? statusId;
  String? statusName;
  String? competitionName;
  int? homeTeamId;
  String? homeTeamName;
  String? homeTeamLogo;
  int? awayTeamId;
  String? awayTeamName;
  String? awayTeamLogo;
  int? homeScore;
  int? awayScore;

  G5PostMatch({
    this.matchType,
    this.matchId,
    this.competitionId,
    this.seasonId,
    this.startTime,
    this.statusId,
    this.statusName,
    this.competitionName,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
  });

  factory G5PostMatch.fromJson(Map<String, dynamic> json) {
    return G5PostMatch(
      matchType: json['match_type'] as int?,
      matchId: json['match_id'] as int?,
      competitionId: json['competition_id'] as int?,
      seasonId: json['season_id'] as int?,
      startTime: json['start_time'] as int?,
      statusId: json['status_id'] as int?,
      statusName: json['status_name'] as String?,
      competitionName: json['competition_name'] as String?,
      homeTeamId: json['home_team_id'] as int?,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: json['home_team_logo'] as String?,
      awayTeamId: json['away_team_id'] as int?,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: json['away_team_logo'] as String?,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
    );
  }
}
