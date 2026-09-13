/// 球队排名分组模型
class G5TeamRankGroup {
  /// 晋级/降级名称
  final String? promotionName;

  /// 排名列表
  final List<G5TeamRankItem>? list;

  G5TeamRankGroup({
    this.promotionName,
    this.list,
  });

  factory G5TeamRankGroup.fromJson(Map<String, dynamic> json) {
    List<G5TeamRankItem>? list;
    if (json['list'] != null) {
      list = (json['list'] as List).map((e) => G5TeamRankItem.fromJson(e)).toList();
    }
    return G5TeamRankGroup(
      promotionName: json['promotion_name'] as String?,
      list: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promotion_name': promotionName,
      'list': list?.map((e) => e.toJson()).toList(),
    };
  }
}

/// 球队排名项模型
class G5TeamRankItem {
  /// 球队ID
  final int? teamId;

  /// 球队名称
  final String? teamName;

  /// 球队Logo
  final String? logo;

  /// 晋级ID
  final int? promotionId;

  /// 积分
  final int? points;

  /// 排名
  final int? position;

  /// 备注
  final String? noteZh;

  /// 场次
  final int? total;

  /// 胜
  final int? won;

  /// 平
  final int? draw;

  /// 负
  final int? loss;

  /// 进球
  final int? goals;

  /// 失球
  final int? goalsAgainst;

  G5TeamRankItem({
    this.teamId,
    this.teamName,
    this.logo,
    this.promotionId,
    this.points,
    this.position,
    this.noteZh,
    this.total,
    this.won,
    this.draw,
    this.loss,
    this.goals,
    this.goalsAgainst,
  });

  factory G5TeamRankItem.fromJson(Map<String, dynamic> json) {
    return G5TeamRankItem(
      teamId: json['team_id'] != null ? (json['team_id'] as num).toInt() : null,
      teamName: json['team_name'] as String?,
      logo: json['logo'] as String?,
      promotionId: json['promotion_id'] != null ? (json['promotion_id'] as num).toInt() : null,
      points: json['points'] != null ? (json['points'] as num).toInt() : null,
      position: json['position'] != null ? (json['position'] as num).toInt() : null,
      noteZh: json['note_zh'] as String?,
      total: json['total'] != null ? (json['total'] as num).toInt() : null,
      won: json['won'] != null ? (json['won'] as num).toInt() : null,
      draw: json['draw'] != null ? (json['draw'] as num).toInt() : null,
      loss: json['loss'] != null ? (json['loss'] as num).toInt() : null,
      goals: json['goals'] != null ? (json['goals'] as num).toInt() : null,
      goalsAgainst: json['goals_against'] != null ? (json['goals_against'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'team_name': teamName,
      'logo': logo,
      'promotion_id': promotionId,
      'points': points,
      'position': position,
      'note_zh': noteZh,
      'total': total,
      'won': won,
      'draw': draw,
      'loss': loss,
      'goals': goals,
      'goals_against': goalsAgainst,
    };
  }
}
