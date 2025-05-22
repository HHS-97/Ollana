class MeVsMe {
  final num recordId;
  final String date;
  final num maxHeartRate;
  final double averageHeartRate;
  final num time;

  MeVsMe({
    required this.recordId,
    required this.date,
    required this.maxHeartRate,
    required this.averageHeartRate,
    required this.time,
  });

  // API 응답에서 객체 생성
  factory MeVsMe.fromJson(Map<String, dynamic> json) {
    return MeVsMe(
      recordId: json['recordId'] ?? 0,
      date: json['date'] ?? '',
      maxHeartRate: json['maxHeartRate'] ?? 0,
      averageHeartRate: (json['averageHeartRate'] is num)
          ? json['averageHeartRate'].toDouble()
          : 0.0,
      time: json['time'] ?? 0,
    );
  }

  // 객체를 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'date': date,
      'maxHeartRate': maxHeartRate,
      'averageHeartRate': averageHeartRate,
      'time': time,
    };
  }
}
