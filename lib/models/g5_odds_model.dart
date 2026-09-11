import 'package:flutter/foundation.dart';

class G5OddsData {
  List<G5OddsCompany>? asia; // 让球让分
  List<G5OddsCompany>? eu; // 胜平负
  List<G5OddsCompany>? bs; // 进球数
  List<G5OddsCompany>? cr; // 角球

  G5OddsData({this.asia, this.eu, this.bs, this.cr});

  factory G5OddsData.fromJson(Map<String, dynamic> json) {
    return G5OddsData(
      asia: _parseList(json['asia']),
      eu: _parseList(json['eu']),
      bs: _parseList(json['bs']),
      cr: _parseList(json['cr']),
    );
  }

  static List<G5OddsCompany>? _parseList(dynamic data) {
    if (data == null || data is! List) return null;
    return data.map((e) => G5OddsCompany.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class G5OddsCompany {
  String? name;
  String? companyId;
  G5OddsDetail? ini; // 初盘
  G5OddsDetail? pre; // 赛前
  G5OddsDetail? spot; // 即时

  G5OddsCompany({this.name, this.companyId, this.ini, this.pre, this.spot});

  factory G5OddsCompany.fromJson(Map<String, dynamic> json) {
    return G5OddsCompany(
      name: json['name']?.toString(),
      companyId: json['company_id']?.toString(),
      ini: json['ini'] != null ? G5OddsDetail.fromJson(json['ini']) : (json['init'] != null ? G5OddsDetail.fromJson(json['init']) : null),
      pre: json['pre'] != null ? G5OddsDetail.fromJson(json['pre']) : null,
      spot: json['spot'] != null ? G5OddsDetail.fromJson(json['spot']) : null,
    );
  }
}

class G5OddsDetail {
  String? home;
  String? draw;
  String? away;

  G5OddsDetail({this.home, this.draw, this.away});

  factory G5OddsDetail.fromJson(Map<String, dynamic> json) {
    return G5OddsDetail(
      home: json['home']?.toString(),
      draw: json['draw']?.toString(),
      away: json['away']?.toString(),
    );
  }
}