import 'g5_match_model.dart';

/// 搜索用户模型
/// 对应 /api/livespeed/index/search 返回的 users 数组元素
class G5SearchUser {
  /// 用户ID - int?类型，用户唯一标识
  final int? id;

  /// 用户UUID - int?类型，用户UUID标识
  final int? uuid;

  /// 用户头像 - String?类型，头像URL
  final String? avatar;

  /// 用户昵称 - String?类型，昵称
  final String? nickname;

  /// 是否直播中 - int?类型，1=直播中
  final int? isLiving;

  /// 是否专家 - int?类型，1=专家
  final int? isExpert;

  /// 是否VIP - int?类型，1=VIP
  final int? isVip;

  /// 关注状态 - int?类型，0或2=未关注，1或3=已关注
  final int? followType;

  /// 构造函数
  G5SearchUser({
    this.id,
    this.uuid,
    this.avatar,
    this.nickname,
    this.isLiving,
    this.isExpert,
    this.isVip,
    this.followType,
  });

  /// 是否已关注 - bool类型，follow_type=1或3表示已关注
  bool get isFollowed => followType == 1 || followType == 3;

  /// JSON转模型
  /// 参数：json - Map<String, dynamic>类型，接口返回的用户数据
  /// 返回：G5SearchUser，用户模型
  factory G5SearchUser.fromJson(Map<String, dynamic> json) {
    return G5SearchUser(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      uuid: json['uuid'] != null ? (json['uuid'] as num).toInt() : null,
      avatar: json['avatar'] as String?,
      nickname: json['nickname'] as String?,
      isLiving:
          json['is_living'] != null ? (json['is_living'] as num).toInt() : null,
      isExpert:
          json['is_expert'] != null ? (json['is_expert'] as num).toInt() : null,
      isVip: json['is_vip'] != null ? (json['is_vip'] as num).toInt() : null,
      followType: json['follow_type'] != null
          ? (json['follow_type'] as num).toInt()
          : null,
    );
  }
}

/// 搜索结果模型
/// 对应 /api/livespeed/index/search 返回的 data 对象
class G5SearchResultModel {
  /// 比赛结果列表 - List<G5MatchItem>类型，搜索匹配的比赛
  final List<G5MatchItem> matches;

  /// 用户结果列表 - List<G5SearchUser>类型，搜索匹配的用户
  final List<G5SearchUser> users;

  /// 构造函数
  G5SearchResultModel({
    this.matches = const [],
    this.users = const [],
  });

  /// JSON转模型
  /// 只解析matches和users两个字段，其余字段（experts/schemes/competitions）暂不使用
  /// 参数：json - Map<String, dynamic>类型，接口返回的data对象
  /// 返回：G5SearchResultModel，搜索结果模型
  factory G5SearchResultModel.fromJson(Map<String, dynamic> json) {
    return G5SearchResultModel(
      matches: (json['matches'] as List<dynamic>? ?? [])
          .map((e) => _parseMatch(e as Map<String, dynamic>))
          .toList(),
      users: (json['users'] as List<dynamic>? ?? [])
          .map((e) => G5SearchUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 解析单条比赛数据为G5MatchItem模型
  /// 参数：json - Map<String, dynamic>类型，接口返回的单条比赛数据
  /// 返回：G5MatchItem，比赛列表模型
  static G5MatchItem _parseMatch(Map<String, dynamic> json) {
    return G5MatchItem(
      matchId:
          json['match_id'] != null ? (json['match_id'] as num).toInt() : null,
      matchTime: json['match_time'] != null
          ? (json['match_time'] as num).toInt()
          : null,
      competitionName: json['competition_name'] as String?,
      homeTeamId: json['home_team_id'] != null
          ? (json['home_team_id'] as num).toInt()
          : null,
      homeTeamName: json['home_team_name'] as String?,
      homeTeamLogo: json['home_team_logo'] as String?,
      homeTeamScore: json['home_team_score'] != null
          ? (json['home_team_score'] as num).toInt()
          : null,
      awayTeamId: json['away_team_id'] != null
          ? (json['away_team_id'] as num).toInt()
          : null,
      awayTeamName: json['away_team_name'] as String?,
      awayTeamLogo: json['away_team_logo'] as String?,
      awayTeamScore: json['away_team_score'] != null
          ? (json['away_team_score'] as num).toInt()
          : null,
    );
  }
}
