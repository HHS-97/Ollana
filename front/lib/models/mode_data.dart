import './mountain.dart';
import './hiking_route.dart';
import './opponent.dart';

class ModeData {
  final bool isNearby;
  final Mountain mountain;
  final HikingRoute path;
  final Opponent? opponent; // null 허용

  ModeData({
    required this.isNearby,
    required this.mountain,
    required this.path,
    this.opponent,
  });

  factory ModeData.fromJson(Map<String, dynamic> json) {
    // Mountain 객체 생성
    final mountainJson = json['mountain'] as Map<String, dynamic>;
    final mountainData = {
      ...mountainJson,
      'location': '', // API 응답에 없는 필드 기본값 설정
      'height': 0.0, // API 응답에 없는 필드 기본값 설정
    };
    final mountain = Mountain.fromJson(mountainData);

    // HikingRoute 객체 생성
    final pathJson = json['path'] as Map<String, dynamic>;
    final path = HikingRoute.fromJson(pathJson);

    // Opponent 객체 생성 (null 가능)
    Opponent? opponent;
    if (json['opponent'] != null) {
      opponent = Opponent.fromJson(json['opponent'] as Map<String, dynamic>);
    }

    return ModeData(
      isNearby: json['isNearby'] as bool,
      mountain: mountain,
      path: path,
      opponent: opponent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isNearby': isNearby,
      'mountain': mountain.toJson(),
      'path': path.toJson(),
      'opponent': opponent?.toJson(),
    };
  }
}
