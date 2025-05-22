// mountain_map.dart: 산 지도 정보를 위한 모델 정의
// - Mountain: 산 정보 클래스
// - Level: 산 난이도 열거형

class MountainMap {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double altitude;
  final String level;
  final String description;

  MountainMap({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.level,
    required this.description,
  });

  factory MountainMap.fromJson(Map<String, dynamic> json) {
    return MountainMap(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      altitude: json['altitude'] ?? 0.0,
      level: json['level'] ?? 'M',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'level': level,
      'description': description,
    };
  }
}

enum Level {
  H, // 상
  M, // 중
  L, // 하
}

extension LevelExtension on String {
  Level toLevel() {
    switch (this) {
      case 'H':
        return Level.H;
      case 'M':
        return Level.M;
      case 'L':
        return Level.L;
      default:
        return Level.M;
    }
  }
}
