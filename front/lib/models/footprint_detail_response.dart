import 'package:flutter/foundation.dart';
import 'path_detail.dart';

class FootprintDetailResponse {
  final String mountainName;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool last;
  final List<PathDetail> paths;

  FootprintDetailResponse({
    required this.mountainName,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.last,
    required this.paths,
  });

  factory FootprintDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return FootprintDetailResponse(
      mountainName: data['mountain']['mountainName'],
      currentPage: data['currentPage'],
      totalPages: data['totalPages'],
      totalElements: data['totalElements'],
      last: data['last'],
      paths: (data['paths'] as List)
          .map((p) => PathDetail.fromJsonWithPath(p))
          .toList(),
    );
  }
}