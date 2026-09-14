import 'package:flutter/foundation.dart';
import 'package:livespeed/models/g5_odds_model.dart';

class G5OddsHistoryData {
  List<G5OddsHistoryItem>? asia;
  List<G5OddsHistoryItem>? eu;
  List<G5OddsHistoryItem>? bs;
  List<G5OddsHistoryItem>? cr;

  G5OddsHistoryData({this.asia, this.eu, this.bs, this.cr});

  factory G5OddsHistoryData.fromJson(Map<String, dynamic> json) {
    return G5OddsHistoryData(
      asia: _parseList(json['asia']),
      eu: _parseList(json['eu']),
      bs: _parseList(json['bs']),
      cr: _parseList(json['cr']),
    );
  }

  static List<G5OddsHistoryItem>? _parseList(dynamic data) {
    if (data == null || data is! List) return null;
    return data.map((e) => G5OddsHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class G5OddsHistoryItem {
  int? updatedAt;
  String? matchOffset;
  String? home;
  String? draw;
  String? away;
  int? state;
  int? closed;
  String? score;

  G5OddsHistoryItem({
    this.updatedAt,
    this.matchOffset,
    this.home,
    this.draw,
    this.away,
    this.state,
    this.closed,
    this.score,
  });

  factory G5OddsHistoryItem.fromJson(Map<String, dynamic> json) {
    return G5OddsHistoryItem(
      updatedAt: json['updated_at'] != null ? (json['updated_at'] as num).toInt() : null,
      matchOffset: json['match_offset']?.toString(),
      home: json['home']?.toString(),
      draw: json['draw']?.toString(),
      away: json['away']?.toString(),
      state: json['state'] != null ? (json['state'] as num).toInt() : null,
      closed: json['closed'] != null ? (json['closed'] as num).toInt() : null,
      score: json['score']?.toString(),
    );
  }
}
