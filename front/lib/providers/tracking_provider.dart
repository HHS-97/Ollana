// tracking_provider.dart: 등산 트래킹 상태 관리
import 'package:flutter/foundation.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';

enum TrackingStatus {
  idle, // 트래킹 시작 전
  tracking, // 트래킹 중
  paused, // 일시 정지
  completed // 완료됨
}

class TrackingProvider with ChangeNotifier {
  Mountain? _selectedMountain;
  HikingRoute? _selectedRoute;
  TrackingStatus _status = TrackingStatus.idle;
  DateTime? _startTime;
  DateTime? _endTime;
  double _distance = 0.0;
  int _duration = 0; // 분 단위
  List<Map<String, dynamic>> _trackPoints = [];

  // 게터
  Mountain? get selectedMountain => _selectedMountain;
  HikingRoute? get selectedRoute => _selectedRoute;
  TrackingStatus get status => _status;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  double get distance => _distance;
  int get duration => _duration;
  List<Map<String, dynamic>> get trackPoints => _trackPoints;

  // 산과 등산로 선택
  void selectMountainAndRoute(Mountain mountain, HikingRoute route) {
    _selectedMountain = mountain;
    _selectedRoute = route;
    notifyListeners();
  }

  // 트래킹 시작
  void startTracking() {
    if (_status == TrackingStatus.idle || _status == TrackingStatus.paused) {
      if (_status == TrackingStatus.idle) {
        _startTime = DateTime.now();
        _trackPoints = [];
        _distance = 0.0;
        _duration = 0;
      }
      _status = TrackingStatus.tracking;
      notifyListeners();
    }
  }

  // 트래킹 일시 정지
  void pauseTracking() {
    if (_status == TrackingStatus.tracking) {
      _status = TrackingStatus.paused;
      notifyListeners();
    }
  }

  // 트래킹 재개
  void resumeTracking() {
    if (_status == TrackingStatus.paused) {
      _status = TrackingStatus.tracking;
      notifyListeners();
    }
  }

  // 트래킹 종료
  void completeTracking() {
    if (_status == TrackingStatus.tracking ||
        _status == TrackingStatus.paused) {
      _status = TrackingStatus.completed;
      _endTime = DateTime.now();
      notifyListeners();
    }
  }

  // 트래킹 초기화
  void resetTracking() {
    _status = TrackingStatus.idle;
    _startTime = null;
    _endTime = null;
    _distance = 0.0;
    _duration = 0;
    _trackPoints = [];
    notifyListeners();
  }

  // 위치 포인트 추가
  void addTrackPoint(double latitude, double longitude, double altitude) {
    if (_status == TrackingStatus.tracking) {
      final point = {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _trackPoints.add(point);

      // 거리 계산 로직은 실제 구현에서 추가
      // _updateDistance();

      // 소요 시간 업데이트 (분 단위)
      if (_startTime != null) {
        final now = DateTime.now();
        _duration = now.difference(_startTime!).inMinutes;
      }

      notifyListeners();
    }
  }
}
