/// 比赛模型 - JSON 映射
class G5MatchData {
  int? total;
  int? timestamp;
  List<G5MatchItem>? results;

  G5MatchData({this.total, this.timestamp, this.results});

  factory G5MatchData.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List?;
    List<G5MatchItem> items = [];
    if (list != null) {
      items = list.map((e) => G5MatchItem.fromJson(e)).toList();
    }
    return G5MatchData(
      total: json['total'] as int?,
      timestamp: json['timestamp'] as int?,
      results: items,
    );
  }
}

class G5MatchItem {
  int? matchId;
  int? seasonId;
  int? competitionId;
  String? competitionLogo;
  String? competitionName;
  String? competitionPrimaryColor;
  String? competitionSecondaryColor;
  
  int? homeTeamId;
  String? homeTeamName;
  String? homeTeamLogo;
  
  int? awayTeamId;
  String? awayTeamName;
  String? awayTeamLogo;
  
  int? statusId;
  String? statusName;
  int? matchTime;
  int? neutral;
  
  int? homeNormalScore;
  int? homeHalfScore;
  int? homeRed;
  int? homeYellow;
  int? homeCorn;
  int? homeAddScore;
  int? homePointScore;
  
  int? awayNormalScore;
  int? awayHalfScore;
  int? awayRed;
  int? awayYellow;
  int? awayCorn;
  int? awayAddScore;
  int? awayPointScore;
  
  int? lineup;
  int? stageId;
  
  bool? subscribed;
  String? homePosition;
  String? awayPosition;
  bool? hasOt;
  bool? hasPenalty;
  int? win;
  String? note;
  String? minutes;
  int? mlive;
  String? mliveUrl;
  int? liveVideo;
  int? hasArticle;
  String? stageName;
  String? groupNum;
  int? roundNum;
  int? schemeCount;
  int? countdown;
  int? isWorldCup;
  int? categoryId; // 运动分类 1为足球
  int? homeTeamScore;
  int? awayTeamScore;

  G5MatchItem({
    this.matchId,
    this.seasonId,
    this.competitionId,
    this.competitionLogo,
    this.competitionName,
    this.competitionPrimaryColor,
    this.competitionSecondaryColor,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamLogo,
    this.homeTeamScore,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamLogo,
    this.awayTeamScore,
    this.statusId,
    this.statusName,
    this.matchTime,
    this.neutral,
    this.homeNormalScore,
    this.homeHalfScore,
    this.homeRed,
    this.homeYellow,
    this.homeCorn,
    this.homeAddScore,
    this.homePointScore,
    this.awayNormalScore,
    this.awayHalfScore,
    this.awayRed,
    this.awayYellow,
    this.awayCorn,
    this.awayAddScore,
    this.awayPointScore,
    this.lineup,
    this.stageId,
    this.subscribed,
    this.homePosition,
    this.awayPosition,
    this.hasOt,
    this.hasPenalty,
    this.win,
    this.note,
    this.minutes,
    this.mlive,
    this.mliveUrl,
    this.liveVideo,
    this.hasArticle,
    this.stageName,
    this.groupNum,
    this.roundNum,
    this.schemeCount,
    this.countdown,
    this.isWorldCup,
    this.categoryId,
  });

  factory G5MatchItem.fromJson(Map<String, dynamic> json) {
    return G5MatchItem(
      matchId: json['match_id'] as int?,
      seasonId: json['season_id'] as int?,
      competitionId: json['competition_id'] as int?,
      competitionLogo: json['competition_logo'] as String?,
      competitionName: json['competition_name'] as String?,
      competitionPrimaryColor: json['competition_primary_color'] as String?,
      competitionSecondaryColor: json['competition_secondary_color'] as String?,
      homeTeamId: json['home_team_id'] as int?,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: json['home_team_logo'] as String?,
      awayTeamId: json['away_team_id'] as int?,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: json['away_team_logo'] as String?,
      statusId: json['status_id'] as int?,
      statusName: json['status_name'] as String?,
      matchTime: json['match_time'] as int?,
      neutral: json['neutral'] as int?,
      homeNormalScore: json['home_normal_score'] as int?,
      homeHalfScore: json['home_half_score'] as int?,
      homeRed: json['home_red'] as int?,
      homeYellow: json['home_yellow'] as int?,
      homeCorn: json['home_corn'] as int?,
      homeAddScore: json['home_add_score'] as int?,
      homePointScore: json['home_point_score'] as int?,
      awayNormalScore: json['away_normal_score'] as int?,
      awayHalfScore: json['away_half_score'] as int?,
      awayRed: json['away_red'] as int?,
      awayYellow: json['away_yellow'] as int?,
      awayCorn: json['away_corn'] as int?,
      awayAddScore: json['away_add_score'] as int?,
      awayPointScore: json['away_point_score'] as int?,
      lineup: json['lineup'] as int?,
      stageId: json['stage_id'] as int?,
      subscribed: json['subscribed'] as bool?,
      homePosition: json['home_position'] as String?,
      awayPosition: json['away_position'] as String?,
      hasOt: json['has_ot'] as bool?,
      hasPenalty: json['has_penalty'] as bool?,
      win: json['win'] as int?,
      note: json['note'] as String?,
      minutes: json['minutes'] as String?,
      mlive: json['mlive'] as int?,
      mliveUrl: json['mlive_url'] as String?,
      liveVideo: json['live_video'] as int?,
      hasArticle: json['has_article'] as int?,
      stageName: json['stage_name'] as String?,
      groupNum: json['group_num'] as String?,
      roundNum: json['round_num'] as int?,
      schemeCount: json['scheme_count'] as int?,
      countdown: json['countdown'] as int?,
      isWorldCup: json['is_world_cup'] as int?,
      categoryId: json['category'] != null ? (json['category'] as num).toInt() : null,
    );
  }
}
