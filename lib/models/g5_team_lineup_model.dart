class G5TeamLineupGroup {
  String? position;
  List<G5TeamPlayer>? personList;

  G5TeamLineupGroup({this.position, this.personList});

  factory G5TeamLineupGroup.fromJson(Map<String, dynamic> json) {
    return G5TeamLineupGroup(
      position: json['position'] as String?,
      personList: json['person_list'] != null
          ? (json['person_list'] as List)
              .map((e) => G5TeamPlayer.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'person_list': personList?.map((e) => e.toJson()).toList(),
    };
  }

  String get positionName {
    switch (position) {
      case 'Coach':
        return 'Coach';
      case 'F':
        return 'FWD';
      case 'M':
        return 'MID';
      case 'D':
        return 'DEF';
      case 'G':
        return 'GK';
      default:
        return position ?? '';
    }
  }
}

class G5TeamPlayer {
  int? id;
  String? name;
  String? logo;
  String? position;
  int? shirtNumber;
  int? goals;
  int? matches;

  G5TeamPlayer({
    this.id,
    this.name,
    this.logo,
    this.position,
    this.shirtNumber,
    this.goals,
    this.matches,
  });

  factory G5TeamPlayer.fromJson(Map<String, dynamic> json) {
    return G5TeamPlayer(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      name: json['name'] as String?,
      logo: json['logo'] as String?,
      position: json['position'] as String?,
      shirtNumber: json['shirt_number'] != null ? (json['shirt_number'] as num).toInt() : null,
      goals: json['goals'] != null ? (json['goals'] as num).toInt() : null,
      matches: json['matches'] != null ? (json['matches'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'position': position,
      'shirt_number': shirtNumber,
      'goals': goals,
      'matches': matches,
    };
  }
}