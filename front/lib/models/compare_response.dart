class CompareResponse {
  final List<CompareRecord> records;
  final CompareResult? result;

  CompareResponse({required this.records, this.result});

  factory CompareResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final records = (data['records'] as List)
        .map((e) => CompareRecord.fromJson(e))
        .toList();
    final resultJson = data['result'];
    return CompareResponse(
      records: records,
      result: resultJson != null ? CompareResult.fromJson(resultJson) : null,
    );
  }
}

class CompareRecord {
  final int recordId;
  final String date;
  final int maxHeartRate;
  final double averageHeartRate;
  final int time;

  CompareRecord({
    required this.recordId,
    required this.date,
    required this.maxHeartRate,
    required this.averageHeartRate,
    required this.time,
  });

  factory CompareRecord.fromJson(Map<String, dynamic> json) {
    return CompareRecord(
      recordId: json['recordId'],
      date: json['date'],
      maxHeartRate: json['maxHeartRate'],
      averageHeartRate: json['averageHeartRate'],
      time: json['time'],
    );
  }
}

class CompareResult {
  final String growthStatus;
  final int maxHeartRateDiff;
  final int avgHeartRateDiff;
  final int timeDiff;

  CompareResult({
    required this.growthStatus,
    required this.maxHeartRateDiff,
    required this.avgHeartRateDiff,
    required this.timeDiff,
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    return CompareResult(
      growthStatus: json['growthStatus'],
      maxHeartRateDiff: json['maxHeartRateDiff'],
      avgHeartRateDiff: json['avgHeartRateDiff'],
      timeDiff: json['timeDiff'],
    );
  }
}