// lib/models/opponent_record.dart

class OpponentRecord {
  final int time;
  final double distance;
  final int heartRate;
  final double latitude;
  final double longitude;

  OpponentRecord({
    required this.time,
    required this.distance,
    required this.heartRate,
    required this.latitude,
    required this.longitude,
  });

  factory OpponentRecord.fromJson(Map<String, dynamic> json) {
    return OpponentRecord(
      time: json['time'] as int,
      distance: (json['distance'] as num).toDouble(),
      heartRate: json['heartRate'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'distance': distance,
      'heartRate': heartRate,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
