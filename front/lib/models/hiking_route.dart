// hiking_route.dart: 등산로 모델 클래스
// 산의 등산로 정보를 저장하는 데이터 모델

import 'package:flutter/foundation.dart';
import 'dart:math';

class HikingRoute {
  final num id;
  final num mountainId;
  final String name;
  final int distance;
  final int estimatedTime; // 분 단위
  final String difficulty;
  final String description;
  final List<String> waypoints;
  final String mapImageUrl;
  final List<Map<String, double>> path; // 경로 좌표 정보

  HikingRoute({
    required this.id,
    required this.mountainId,
    required this.name,
    required this.distance,
    required this.estimatedTime,
    this.difficulty = '보통',
    this.description = '',
    this.waypoints = const [],
    this.mapImageUrl = '',
    this.path = const [], // 기본값으로 빈 리스트 설정
  });

  factory HikingRoute.fromJson(Map<String, dynamic> json) {
    // 경로 좌표 처리
    List<Map<String, double>> parsedPath = [];

    // 'route' 또는 'path' 필드에서 경로 좌표 가져오기
    var routeData = json['route'];
    routeData ??= json['path'];

    if (routeData != null && routeData is List) {
      for (var point in routeData) {
        if (point is Map) {
          parsedPath.add({
            'latitude':
                (point['latitude'] is num) ? point['latitude'].toDouble() : 0.0,
            'longitude': (point['longitude'] is num)
                ? point['longitude'].toDouble()
                : 0.0,
          });
        }
      }
    }

    // mountainId가 없는 경우 로그 출력
    final hasMountainId =
        json.containsKey('mountainId') && json['mountainId'] != null;
    if (!hasMountainId) {
      debugPrint(
          '⚠️ HikingRoute.fromJson: mountainId가 없음 - JSON: ${json.toString().substring(0, min(100, json.toString().length))}...');
    }

    return HikingRoute(
      id: json['pathId'] ?? 0,
      mountainId:
          json['mountainId'] ?? json['mountain_id'] ?? 0, // mountain_id도 확인
      name: json['pathName'] ?? '',
      distance: (json['distance'] is num)
          ? json['distance'].toInt()
          : (json['pathLength'] is num)
              ? json['pathLength'].toInt()
              : 0,
      estimatedTime: json['estimatedTime'] is int
          ? json['estimatedTime']
          : (json['pathTime'] != null)
              ? int.tryParse(json['pathTime'].toString()) ?? 0
              : 0,
      difficulty: json['difficulty'] ?? '보통',
      description: json['description'] ?? '',
      waypoints: List<String>.from(json['waypoints'] ?? []),
      mapImageUrl: json['mapImageUrl'] ?? '',
      path: parsedPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mountainId': mountainId,
      'name': name,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'difficulty': difficulty,
      'description': description,
      'waypoints': waypoints,
      'mapImageUrl': mapImageUrl,
      'path': path,
    };
  }
}
