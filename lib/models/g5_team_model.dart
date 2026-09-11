import 'package:flutter/foundation.dart';

class G5TeamData {
  int? competitionId;
  String? competitionName;
  String? name;
  String? logo;
  int? foundationTime;
  String? countryName;
  String? countryLogo;
  String? venueName;
  int? venueCapacity;
  String? managerName;
  String? managerLogo;
  int? marketValue;
  bool? isSubscribe;
  String? website;

  G5TeamData({
    this.competitionId,
    this.competitionName,
    this.name,
    this.logo,
    this.foundationTime,
    this.countryName,
    this.countryLogo,
    this.venueName,
    this.venueCapacity,
    this.managerName,
    this.managerLogo,
    this.marketValue,
    this.isSubscribe,
    this.website,
  });

  factory G5TeamData.fromJson(Map<String, dynamic> json) {
    return G5TeamData(
      competitionId: json['competition_id'] != null ? (json['competition_id'] as num).toInt() : null,
      competitionName: json['competition_name']?.toString(),
      name: json['name']?.toString(),
      logo: json['logo']?.toString(),
      foundationTime: json['foundation_time'] != null ? (json['foundation_time'] as num).toInt() : null,
      countryName: json['country_name']?.toString(),
      countryLogo: json['country_logo']?.toString(),
      venueName: json['venue_name']?.toString(),
      venueCapacity: json['venue_capacity'] != null ? (json['venue_capacity'] as num).toInt() : null,
      managerName: json['manager_name']?.toString(),
      managerLogo: json['manager_logo']?.toString(),
      marketValue: json['market_value'] != null ? (json['market_value'] as num).toInt() : null,
      isSubscribe: json['is_subscribe'] as bool?,
      website: json['website']?.toString(),
    );
  }
}