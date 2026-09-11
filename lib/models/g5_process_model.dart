import 'package:flutter/material.dart';
import 'package:zogolive/utils/g5_colors.dart';

class G5ProcessData {
  List<G5StatItem>? stats;
  List<G5IncidentItem>? incidents;

  G5ProcessData({this.stats, this.incidents});

  factory G5ProcessData.fromJson(Map<String, dynamic> json) {
    return G5ProcessData(
      stats: json['stats'] != null
          ? (json['stats'] as List).map((i) => G5StatItem.fromJson(i)).toList()
          : null,
      incidents: json['incidents'] != null
          ? (json['incidents'] as List)
              .map((i) => G5IncidentItem.fromJson(i))
              .toList()
          : null,
    );
  }
}

class G5StatItem {
  int? away;
  int? home;
  int? type;

  G5StatItem({this.away, this.home, this.type});

  factory G5StatItem.fromJson(Map<String, dynamic> json) {
    return G5StatItem(
      away: json['away'] != null ? (json['away'] as num).toInt() : null,
      home: json['home'] != null ? (json['home'] as num).toInt() : null,
      type: json['type'] != null ? (json['type'] as num).toInt() : null,
    );
  }

  String get typeName {
    switch (type) {
      case 25:
        return 'Possession';
      case 21:
        return 'Shots on target';
      case 22:
        return 'Shots off target';
      case 23:
        return 'Attack';
      case 24:
        return 'Dangerous Attack';
      case 2:
        return 'Corner Kick';
      case 4:
        return 'Red Card';
      case 3:
        return 'Yellow Card';
      case 1:
        return '3分球进球数';
      case 2: // 注意，足球里2是角球，篮球里2是2分球进球数。如果你这个接口专门对应篮球（/api/v1/basketball/match/process），可以将足球相关的覆盖或者按需调整。这里先补齐篮球枚举
        return '2分球进球数';
      case 3: 
        return '罚球进球数';
      case 4:
        return '剩余暂停数';
      case 5:
        return '犯规数';
      case 6:
        return '罚球命中率';
      case 7:
        return '总暂停数';
      default:
        return 'Unknown Stat';
    }
  }

  double get homeProgress {
    final int total = (home ?? 0) + (away ?? 0);
    if (total == 0 || home == 0) return 0.0;
    return (home!) / total;
  }

  double get awayProgress {
    final int total = (home ?? 0) + (away ?? 0);
    if (total == 0 || away == 0) return 0.0;
    return (away!) / total;
  }
}

class G5IncidentItem {
  int? type;
  int? typeV2;
  int? position; // 0-中立、1-主队、2-客队
  int? time; // 分钟
  int? second;
  int? homeScore;
  int? awayScore;
  int? playerId;
  String? playerName;
  int? varReason;
  int? varResult;
  int? reasonType;
  int? assist1Id;
  int? assist2Id;
  int? inPlayerId;
  int? outPlayerId;
  String? assist1Name;
  String? assist2Name;
  String? inPlayerName;
  String? outPlayerName;

  G5IncidentItem({
    this.type,
    this.typeV2,
    this.position,
    this.time,
    this.second,
    this.homeScore,
    this.awayScore,
    this.playerId,
    this.playerName,
    this.varReason,
    this.varResult,
    this.reasonType,
    this.assist1Id,
    this.assist2Id,
    this.inPlayerId,
    this.outPlayerId,
    this.assist1Name,
    this.assist2Name,
    this.inPlayerName,
    this.outPlayerName,
  });

  factory G5IncidentItem.fromJson(Map<String, dynamic> json) {
    return G5IncidentItem(
      type: json['type'] != null ? (json['type'] as num).toInt() : null,
      typeV2: json['type_v2'] != null ? (json['type_v2'] as num).toInt() : null,
      position: json['position'] != null ? (json['position'] as num).toInt() : null,
      time: json['time'] != null ? (json['time'] as num).toInt() : null,
      second: json['second'] != null ? (json['second'] as num).toInt() : null,
      homeScore: json['home_score'] != null ? (json['home_score'] as num).toInt() : null,
      awayScore: json['away_score'] != null ? (json['away_score'] as num).toInt() : null,
      playerId: json['player_id'] != null ? (json['player_id'] as num).toInt() : null,
      playerName: json['player_name'] as String?,
      varReason: json['var_reason'] != null ? (json['var_reason'] as num).toInt() : null,
      varResult: json['var_result'] != null ? (json['var_result'] as num).toInt() : null,
      reasonType: json['reason_type'] != null ? (json['reason_type'] as num).toInt() : null,
      assist1Id: json['assist1_id'] != null ? (json['assist1_id'] as num).toInt() : null,
      assist2Id: json['assist2_id'] != null ? (json['assist2_id'] as num).toInt() : null,
      inPlayerId: json['in_player_id'] != null ? (json['in_player_id'] as num).toInt() : null,
      outPlayerId: json['out_player_id'] != null ? (json['out_player_id'] as num).toInt() : null,
      assist1Name: json['assist1_name'] as String?,
      assist2Name: json['assist2_name'] as String?,
      inPlayerName: json['in_player_name'] as String?,
      outPlayerName: json['out_player_name'] as String?,
    );
  }

  String get custPlayerName {
    // 换人
    if (type == 9) {
      return outPlayerName ?? '';
    }
    // 助攻
    if (type == 18) {
      return (assist1Name != null && assist1Name!.isNotEmpty) ? assist1Name! : (assist2Name ?? '');
    }
    return playerName ?? '';
  }

  String get custTypeName {
    switch (type) {
      case 4:
        return 'Red card';
      case 3:
        return 'Yellow Card';
      case 15:
        return 'Two yellows turn red';
      case 1:
        return 'Goal';
      case 17:
        return 'Own goal';
      case 9:
        return 'substitute';
      case 28:
        return 'Assistant referee';
      case 2:
        return 'corner';
      case 8:
        return 'penalty stroke goal';
      case 16:
        return 'penalty missed';
      case 29:
        return 'stroke goal';
      case 30:
        return 'penalty penalty missed';
      case 18:
        return 'assist';
      case 24:
        return 'dangerous attack';
      default:
        return 'unknow';
    }
  }

  String get custEventIcon {
    switch (type) {
      case 4:
        return 'event_red';
      case 3:
        return 'event_yellow';
      case 15:
        return 'event_twoYellow_red';
      case 1:
        return 'event_goal';
      case 17:
        return 'event_wulongGoal';
      case 9:
        return 'event_huanren';
      case 28:
        return 'event_caipan';
      case 2:
        return 'event_corner';
      case 8:
        return 'event_dianqiu_goal';
      case 16:
        return 'event_dianqiu_miss';
      case 29:
        return 'event_dianqiu_goal';
      case 30:
        return 'event_dianqiu_miss';
      case 18:
        return 'event_assist';
      case 24:
        return 'event_dangerous_attack';
      default:
        return '';
    }
  }

  // 辅助获取对应的IconData
  IconData get iconData {
    switch (type) {
      case 4: // Red card
      case 15: // Two yellow to red
        return Icons.square;
      case 3: // Yellow card
        return Icons.square;
      case 1: // Goal
      case 8: // Penalty goal
      case 17: // Own goal
      case 29: // Stroke goal
        return Icons.sports_soccer;
      case 9: // Substitute
        return Icons.swap_horiz;
      case 2: // Corner
        return Icons.flag;
      case 16: // Penalty missed
      case 30:
      case 28: // Referee
      case 18: // Assist
      case 24: // Dangerous attack
      default:
        return Icons.info_outline;
    }
  }
  
  Color get iconColor {
    switch (type) {
      case 4:
      case 15:
        return Colors.red;
      case 3:
        return Colors.yellow;
      case 1:
      case 8:
      case 29:
      case 17:
        return Colors.white;
      case 9:
        return G5Colors.accentEmerald;
      case 2:
        return G5Colors.accentGold;
      default:
        return Colors.grey;
    }
  }
}