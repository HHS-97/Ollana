// mountain.dart: 산 모델 클래스
// 산에 대한 기본 정보를 저장하는 데이터 모델

class Mountain {
  final num id;
  final String name;
  final String location;
  final double height;
  final String difficulty;
  final String description;
  final String imageUrl;

  Mountain({
    required this.id,
    required this.name,
    required this.location,
    required this.height,
    this.difficulty = '',
    this.description = '',
    this.imageUrl = '',
  });

  factory Mountain.fromJson(Map<String, dynamic> json) {
    return Mountain(
      id: json['mountainId'] ?? 0,
      name: json['mountainName'] ?? '',
      location: json['location'] ?? '',
      height: (json['height'] is num) ? json['height'].toDouble() : 0.0,
      difficulty: json['difficulty'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'height': height,
      'difficulty': difficulty,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
