import 'record.dart';
import 'package:flutter/foundation.dart';

class PathDetail {
  final int pathId;
  final String pathName;
  final List<Record> records;
  final bool isExceed; // 추가

  PathDetail({
    required this.pathId,
    required this.pathName,
    required this.records,
    required this.isExceed,
  });

  factory PathDetail.fromJson(Map<String, dynamic> json, {required int pathId, String? pathName}) {
    debugPrint('PathDetail.fromJson JSON: $json');
    final result = PathDetail(
      pathId: pathId,
      pathName: pathName ?? 'Unknown Path',
      records: (json['records'] as List? ?? [])
          .map((r) => Record.fromJson(r))
          .toList(),
      isExceed: json['isExceed'] ?? false,
    );
    debugPrint('Parsed PathDetail: pathId=$pathId, pathName=${result.pathName}, records=${result.records.length}, isExceed=${result.isExceed}');
    return result;
  }

  factory PathDetail.fromJsonWithPath(Map<String, dynamic> json) {
    final path = json['path'];
    return PathDetail(
      pathId: path['pathId'],
      pathName: path['pathName'],
      records: (json['records'] as List)
          .map((r) => Record.fromJson(r))
          .toList(),
      isExceed: false, // getFootprintDetail에서는 isExceed 없음
    );
  }
}