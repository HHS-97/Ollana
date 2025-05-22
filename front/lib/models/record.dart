class Record {
  final int recordId;
  final DateTime date;
  final int maxHeartRate;
  final double averageHeartRate;
  final int time;

  Record({
    required this.recordId,
    required this.date,
    required this.maxHeartRate,
    required this.averageHeartRate,
    required this.time,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      recordId: json['recordId'],
      date: DateTime.parse(json['date']),
      maxHeartRate: json['maxHeartRate'],
      averageHeartRate: (json['averageHeartRate'] as num).toDouble(),
      time: json['time'],
    );
  }
}
