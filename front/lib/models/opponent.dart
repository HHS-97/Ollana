import './opponent_record.dart';

class Opponent {
  final int opponentId;
  final String nickname;
  final List<OpponentRecord> records;
  final int? maxHeartRate;
  final double? averageHeartRate;

  Opponent({
    required this.opponentId,
    required this.nickname,
    required this.records,
    this.maxHeartRate,
    this.averageHeartRate,
  });

  factory Opponent.fromJson(Map<String, dynamic> json) {
    return Opponent(
      opponentId: json['opponentId'] as int,
      nickname: json['nickname'] as String,
      records: (json['records'] as List)
          .map((record) =>
              OpponentRecord.fromJson(record as Map<String, dynamic>))
          .toList(),
      maxHeartRate: json['maxHeartRate'] as int?,
      averageHeartRate: json['averageHeartRate'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opponentId': opponentId,
      'nickname': nickname,
      'records': records.map((record) => record.toJson()).toList(),
      'maxHeartRate': maxHeartRate,
      'averageHeartRate': averageHeartRate,
    };
  }
}
