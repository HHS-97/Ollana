// live_tracking_screen.dart: 실시간 트래킹 화면
// - 네이버 지도 기반 실시간 위치 및 등산로 표시
// - 현재 정보 (고도, 이동 거리, 소요 시간 등) 표시
// - 트래킹 종료 기능

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http; // HTTP 패키지 추가
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../models/mode_data.dart';
import '../../models/opponent_record.dart'; // OpponentRecord 클래스 import 추가
import '../../services/mode_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // 백그라운드 서비스 import 추가
import 'tracking_result_screen.dart'; // 결과 화면 추가
import 'package:logger/logger.dart'; // 로거 패키지 추가

// 네이버 지도 라이브러리 임포트
import 'package:flutter_naver_map/flutter_naver_map.dart';

// 로거 인스턴스 생성
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);

// 칼만 필터 클래스 추가
class SimpleKalmanFilter {
  // 상태 변수
  late double _estimate; // 현재 추정값
  late double _errorEstimate; // 추정 오차
  late double _q; // 프로세스 잡음 (환경 노이즈)
  late double _r; // 측정 잡음 (센서 정확도)
  late double _lastEstimate; // 이전 추정값
  late double _kalmanGain; // 칼만 게인

  // 초기화
  SimpleKalmanFilter({
    required double processNoise, // Q
    required double measurementNoise, // R
    required double estimateError, // 초기 추정 오차
    double? initialValue, // 초기값 (없으면 첫 측정값 사용)
  }) {
    _q = processNoise;
    _r = measurementNoise;
    _errorEstimate = estimateError;
    _estimate = initialValue ?? 0.0;
    _lastEstimate = _estimate;
    _kalmanGain = 0.0;
  }

  // 필터 업데이트 메서드
  double update(double measurement) {
    // 예측 단계: 이전 상태로부터 새 상태 예측
    final double prediction = _lastEstimate;
    final double errorPrediction = _errorEstimate + _q;

    // 업데이트 단계: 측정값으로 예측 보정
    _kalmanGain = errorPrediction / (errorPrediction + _r);
    _estimate = prediction + _kalmanGain * (measurement - prediction);
    _errorEstimate = (1 - _kalmanGain) * errorPrediction;
    _lastEstimate = _estimate;

    return _estimate;
  }

  // 현재 추정값 반환
  double get estimate => _estimate;

  // 칼만 게인 반환 (디버깅용)
  double get gain => _kalmanGain;
}

// GPS 위치용 2차원 칼만 필터 래퍼
class GpsKalmanFilter {
  // 위도와 경도에 대한 별도 필터
  late SimpleKalmanFilter _latFilter;
  late SimpleKalmanFilter _lngFilter;
  double _filteredLat = 0.0;
  double _filteredLng = 0.0;
  int _updateCount = 0;

  GpsKalmanFilter({double? initialLat, double? initialLng}) {
    // 위도 필터: 위도는 -90 ~ 90 범위, 일반적으로 변화가 적음
    _latFilter = SimpleKalmanFilter(
      processNoise: 0.00001, // 작은 Q값: 느린 상태 변화 가정
      measurementNoise: 0.001, // R값: 측정 신뢰도 (GPS 정확도에 따라 조정)
      estimateError: 1.0, // 초기 추정 오차
      initialValue: initialLat,
    );

    // 경도 필터: 경도는 -180 ~ 180 범위, 동일 속도시 위도보다 큰 변화
    _lngFilter = SimpleKalmanFilter(
      processNoise: 0.00001, // 작은 Q값: 느린 상태 변화 가정
      measurementNoise: 0.001, // R값: 측정 신뢰도 (GPS 정확도에 따라 조정)
      estimateError: 1.0, // 초기 추정 오차
      initialValue: initialLng,
    );

    if (initialLat != null) _filteredLat = initialLat;
    if (initialLng != null) _filteredLng = initialLng;
  }

  // 필터 업데이트 (새 GPS 측정값 적용)
  void update(double lat, double lng, double accuracy) {
    // GPS 정확도에 따라 측정 잡음 동적 조정
    // 정확도가 낮을수록(값이 클수록) 측정 잡음이 커짐 = 측정을 덜 신뢰
    double adjustedR = math.pow(accuracy / 10.0, 2).toDouble();
    _latFilter._r = adjustedR;
    _lngFilter._r = adjustedR;

    // 필터 업데이트
    _filteredLat = _latFilter.update(lat);
    _filteredLng = _lngFilter.update(lng);
    _updateCount++;

    // 처음 몇 번의 업데이트는 원시 GPS 값에 가중치 부여 (안정화 단계)
    if (_updateCount < 5) {
      double weight = 1.0 - (_updateCount / 5.0);
      _filteredLat = _filteredLat * (1 - weight) + lat * weight;
      _filteredLng = _filteredLng * (1 - weight) + lng * weight;
    }
  }

  // 현재 필터링된 위치 반환
  double get latitude => _filteredLat;
  double get longitude => _filteredLng;

  // 필터 재설정 (급격한 위치 변화 감지 시)
  void reset(double lat, double lng) {
    _latFilter = SimpleKalmanFilter(
      processNoise: 0.00001,
      measurementNoise: 0.001,
      estimateError: 1.0,
      initialValue: lat,
    );
    _lngFilter = SimpleKalmanFilter(
      processNoise: 0.00001,
      measurementNoise: 0.001,
      estimateError: 1.0,
      initialValue: lng,
    );
    _filteredLat = lat;
    _filteredLng = lng;
    _updateCount = 0;
  }
}

// 백그라운드 작업을 위한 헬퍼 함수
class _BackgroundTask {
  // 경로 최적화 계산 (백그라운드)
  static List<NLatLng> optimizeRoute(List<NLatLng> originalRoute) {
    if (originalRoute.length <= 100) return originalRoute;

    // 단순화 비율 계산 (최대 100개의 포인트로 제한)
    final int step = (originalRoute.length / 100).ceil();

    final List<NLatLng> optimized = [];
    // 시작점과 끝점은 항상 포함
    optimized.add(originalRoute.first);

    // 중간 포인트는 간격을 두고 추가
    for (int i = step; i < originalRoute.length - 1; i += step) {
      optimized.add(originalRoute[i]);
    }

    // 마지막 포인트 추가
    optimized.add(originalRoute.last);

    return optimized;
  }

  // 거리 계산 (백그라운드)
  static double calculateDistance(Map<String, double> params) {
    final double lat1 = params['lat1']!;
    final double lng1 = params['lng1']!;
    final double lat2 = params['lat2']!;
    final double lng2 = params['lng2']!;

    const double earthRadius = 6371000; // 지구 반경 (미터)
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // 각도를 라디안으로 변환
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // 경로 바운드 계산 (백그라운드)
  static Map<String, double> calculateRouteBounds(List<NLatLng> routeToUse) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in routeToUse) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }
}

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with WidgetsBindingObserver {
  // WidgetsBindingObserver mixin 추가
  NaverMapController? _mapController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  double _currentAltitude = 120;
  // double _distance = 3.7; // _currentTotalDistance 또는 _completedRouteDistanceKm 로 대체

  // 칼만 필터 인스턴스 추가
  GpsKalmanFilter? _gpsFilter;
  double _lastFilteredLat = 0.0;
  double _lastFilteredLng = 0.0;
  bool _isFilterInitialized = false;

  // 토스트 메시지 관련 변수 추가
  bool _showToast = false;
  String _toastMessage = '';
  Color _toastColor = Colors.green;
  Timer? _toastTimer;

  // 위치 초기화 및 거리 계산 관련 변수
  bool _isFirstLocationUpdateForUserPath = true; // _userPath 업데이트 전용 첫 위치 플래그
  DateTime? _lastLocationUpdateTimeForUserPath; // _userPath 업데이트 전용 마지막 시간
  static const double _maxReasonableSpeed = 5.0; // 최대 합리적 속도 (m/s), 약 18km/h
  // static const double _minSpeedForPathUpdate = 0.1; // 현재 직접 사용 안함

  // 새로운 이동 거리 계산 로직용 변수
  double _anchorPointLat = 0.0;
  double _anchorPointLng = 0.0;
  DateTime? _lastDistanceCalcTime;
  bool _isAnchorPointSet = false;
  int _accumulatedDistanceInMeters = 0;
  int _currentTotalDistance = 0; // UI 표시용 총 이동 거리 (m)

  // WatchConnectivity 인스턴스 추가
  final WatchConnectivity _watch = WatchConnectivity();
  bool _isWatchPaired = false;
  bool _isCheckingWatch = false;
  String _watchStatus = '워치 연결 확인이 필요합니다';
  int _steps = 0; // 걸음 수 변수 추가

  // 현재 위치 (처음 지도 로드 위치)
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  // 위치 트래킹 구독
  StreamSubscription<Position>? _positionStream;

  // 나침반 센서 구독
  StreamSubscription<CompassEvent>? _compassStream;

  // 디바이스 방향 (나침반 방향)
  double _deviceHeading = 0.0;
  double _lastAppliedHeading = 0.0; // 마지막으로 적용된 방향
  static const double _minHeadingChangeForUpdate =
      10.0; // 업데이트를 위한 최소 방향 변화 (도)

  // 현재 심박수
  int _currentHeartRate = 0; // _avgHeartRate에서 _currentHeartRate로 변경 및 초기값 설정

  // 최대/평균 심박수
  int _maxHeartRate = 0;
  int _avgHeartRate = 0;

  // 등산로 경로 데이터
  List<NLatLng> _routeCoordinates = [];

  // 사용자 이동 경로 기록
  final List<NLatLng> _userPath = [];

  // 페이지 상태
  final bool _isPaused = false;
  bool _isSheetExpanded = false;

  // 남은 거리 및 예상 시간 계산용 변수
  int _remainingDistance = 0;
  int _estimatedRemainingSeconds = 0;
  double _averageSpeedMetersPerSecond = 1.0; // 초당 평균 이동 속도 (미터)
  double _completedPercentage = 0.0; // 완료된 경로 비율

  // 경로 오버레이 및 마커 ID
  final String _routeOverlayId = 'hiking-route';
  final String _startPointMarkerId = 'start-point';
  final String _endPointMarkerId = 'end-point';

  // 네비게이션 모드 여부 (기본값을 true로 변경)
  bool _isNavigationMode = true;
  bool _isToggling = false; // 네비게이션 모드 토글 중인지 여부

  // 바텀 시트 컨트롤러
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // 위치 마커 유지를 위한 타이머
  Timer? _locationOverlayTimer;

  // 위치 버튼 클릭 처리를 위한 변수
  bool _isLocationButtonProcessing = false;
  int _pendingLocationClicks = 0; // 대기 중인 위치 버튼 클릭 수

  // 카메라 이동 중인지 확인하는 플래그
  bool _isMovingToCurrentLocation = false;

  // 목적지 도착 관련 변수
  bool _isDestinationReached = false;
  final double _destinationRadius = 50.0; // 도착 감지 반경 (미터)

  // 이전 기록 비교 관련 변수
  bool _isAheadOfRecord = false;
  int _distanceDifference = 0;
  double _pastDistanceAtCurrentTime = 0.0;
  // double _currentTotalDistance = 0.0; // 이 줄을 삭제하여 중복 선언을 제거합니다.

  // 현재 속도 관련 변수 추가
  double _currentSpeed = 0.0; // 현재 속도 (km/h)
  // DateTime? _lastSpeedUpdateTime; // Geolocator.speed 사용으로 불필요

  // 5초 전 좌표 및 시간 (속도 계산용) - 새 로직으로 대체되므로 제거
  // double _speedCalcPreviousLat = 0.0;
  // double _speedCalcPreviousLng = 0.0;
  // DateTime? _speedCalcPreviousTime;
  // static const int _speedCalcIntervalSeconds = 5;

  // 워치 알림 상태
  bool _hasNotifiedWatchForAhead = false;
  bool _hasNotifiedWatchForBehind = false;
  bool _hasNotifiedWatchForDestination = false;

  // ModeData 객체 저장 (이전 기록 및 경쟁자 정보 포함)
  ModeData? _modeData;

  // 경쟁자 데이터를 저장하기 위한 맵 추가
  Map<String, dynamic> _competitorData = {
    'name': '이전 기록',
    'distance': 0,
    'time': 0,
    'isAhead': false,
    'maxHeartRate': 0,
    'avgHeartRate': 0.0,
    'formattedRemainingTime': '0분 0초',
  };

  // 등산 기록 데이터 저장을 위한 변수들
  final List<Map<String, dynamic>> _trackingRecords = [];
  DateTime? _lastRecordTime;
  final int _recordIntervalSeconds = 1; // 1초마다 records에 기록 추가
  Timer? _recordTimer;
  final bool _isSavingEnabled = true; // 기록 저장 여부 (기본값: true)

  // 앱 생명주기 상태 저장을 위한 변수
  AppLifecycleState? _currentLifecycleState;

  // 페이스메이커 level 관련 변수 추가
  String? _previousPacemakerLevel;
  final bool _hasNotifiedWatchForPacemaker = false;
  String? _pacemakerMessage;
  String? _pacemakerLevel;

  // 워치 연결 상태 확인 타이머
  Timer? _watchConnectionTimer;

  // 기본 생성자 추가
  _LiveTrackingScreenState();

  // 워치에 ETA 정보를 보냈는지 여부를 추적하는 플래그
  bool _hasSentEtaToWatch = false;

  @override
  void initState() {
    super.initState();

    // WidgetsBindingObserver 등록
    WidgetsBinding.instance.addObserver(this);

    // 블루투스 권한 요청
    _requestBluetoothPermissions();

    // 워치 연결 상태 초기 확인
    _checkWatchConnection();

    // 경쟁자 데이터 초기화 - 기본값을 더 명확하게 설정
    _initCompetitorData();

    // 워치 연결 상태를 주기적으로 확인 (15초 간격으로 변경)
    _watchConnectionTimer =
        Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isCheckingWatch) {
        // 이미 확인 중이 아닐 때만 실행
        _checkWatchConnection();
      }
    });

    // (1) 워치 메시지 수신 리스너 등록
    _watch.messageStream.listen((Map<String, dynamic> message) {
      logger.d('워치 메시지 수신: $message');

      // 연결 상태가 false인데 메시지를 받은 경우, 연결 상태 재확인
      if (!_isWatchPaired) {
        _checkWatchConnection();
      }

      String path = message['path'];
      switch (path) {
        case '/SENSOR_DATA':
          // heartRate 데이터 타입 처리
          var hrData = message['heartRate'];
          logger.d('심박수 데이터: $hrData');
          int prevHeartRate = _currentHeartRate;

          if (hrData is int) {
            _currentHeartRate = hrData;
          } else if (hrData is double) {
            _currentHeartRate = hrData.toInt();
          } else if (hrData is String) {
            _currentHeartRate = int.tryParse(hrData) ?? _currentHeartRate;
          } else if (hrData == null && mounted) {
            _currentHeartRate = _currentHeartRate;
            logger.w("심박수 null 수신, 이전 값 유지");
          }
          _steps = message['steps'] ?? _steps;

          // 심박수가 변경되었을 때만 AppState 업데이트
          if (_currentHeartRate != prevHeartRate && mounted) {
            logger
                .d('심박수 업데이트: $_currentHeartRate bpm (이전: $prevHeartRate bpm)');

            // AppState 업데이트
            final appState = Provider.of<AppState>(context, listen: false);
            if (_currentHeartRate > 0) {
              if (_currentHeartRate > _maxHeartRate) {
                _maxHeartRate = _currentHeartRate;
                appState.updateTrackingData(maxHeartRate: _maxHeartRate);
              }

              // 평균 심박수 계산 로직은 이미 다른 곳에서 처리된다고 가정
              appState.updateTrackingData(avgHeartRate: _avgHeartRate);
            }
          }
          break;
        case '/STOP_TRACKING_CONFIRM':
          logger.i('워치로부터 /STOP_TRACKING_CONFIRM 메시지 수신');
          _finishTracking(true);
          break;
        case '/STOP_TRACKING_CANCEL':
          logger.i('워치로부터 /STOP_TRACKING_CANCEL 메시지 수신');
          _finishTracking(false);
          break;
      }
    }, onError: (err) {
      logger.e('메시지 수신 오류: $err');
    });

    // AppState에서 데이터 가져오기
    final appState = Provider.of<AppState>(context, listen: false);

    // 선택된 모드 정보 가져오기
    _loadModeData();

    // 지도 및 트래킹 초기화 로직 실행
    _initializeMapAndTracking(appState);

    _sheetController.addListener(_onSheetChanged);
  }

  void _onSheetChanged() {
    final isExpanded = _sheetController.size >= 0.5;
    if (isExpanded != _isSheetExpanded) {
      setState(() {
        _isSheetExpanded = isExpanded;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _cleanupAllResources();

    // 맵 컨트롤러 정리
    _mapController = null;

    // 앱 생명주기 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);

    // 시트 컨트롤러 정리
    try {
      _sheetController.dispose();
    } catch (e) {
      logger.e('시트 컨트롤러 정리 중 오류: $e');
    }

    super.dispose();
  }

  // 모든 리소스 정리 메서드 추가
  void _cleanupAllResources() {
    logger.i('모든 트래킹 리소스 정리 시작');

    // 타이머 정리
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      logger.d('메인 타이머 정리 완료');
    }

    if (_recordTimer != null) {
      _recordTimer!.cancel();
      _recordTimer = null;
      logger.d('기록 타이머 정리 완료');
    }

    if (_locationOverlayTimer != null) {
      _locationOverlayTimer!.cancel();
      _locationOverlayTimer = null;
      logger.d('위치 오버레이 타이머 정리 완료');
    }

    if (_toastTimer != null) {
      _toastTimer!.cancel();
      _toastTimer = null;
      logger.d('토스트 타이머 정리 완료');
    }

    if (_watchConnectionTimer != null) {
      _watchConnectionTimer!.cancel();
      _watchConnectionTimer = null;
      logger.d('워치 연결 타이머 정리 완료');
    }

    // 구독 취소
    if (_positionStream != null) {
      _positionStream!.cancel();
      _positionStream = null;
      logger.d('위치 스트림 구독 취소 완료');
    }

    if (_compassStream != null) {
      _compassStream!.cancel();
      _compassStream = null;
      logger.d('나침반 센서 구독 취소 완료');
    }

    // 컨트롤러 정리
    if (_sheetController.hasListeners) {
      _sheetController.removeListener(_onSheetChanged);
    }

    // 백그라운드 서비스 종료
    stopTrackingService();
    logger.d('백그라운드 서비스 종료 완료');

    logger.i('모든 트래킹 리소스 정리 완료');
  }

  // 유지해야 할 다른 코드는 여기서 제거하지 않도록 주의

  // 앱 생명주기 변경 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() {
      _currentLifecycleState = state;
    });
    logger.d('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.paused) {
      logger.i('[BG] 앱이 백그라운드로 진입했습니다. 백그라운드 로직 정상 동작 중인지 확인하세요.');
    } else if (state == AppLifecycleState.resumed) {
      logger.i('[BG] 앱이 포그라운드로 복귀했습니다.');
    }
  }

  // 트래킹 시작
  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        // mounted 체크 추가
        timer.cancel();
        return;
      }

      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds % 60 == 0) {
            _elapsedMinutes++;
          }
        });

        if (_elapsedSeconds % 10 == 0) {
          logger.d(
              '[BG] 타이머 동작 중: $_elapsedSeconds초 경과, 백그라운드 상태: $_currentLifecycleState');
        }

        // 이동 거리는 _startLocationTracking()에서 실시간으로 계산됨                _calculateRemainingDistanceAndTime();

        // 워치 연결되어 있는 경우 예상 도착시간과 남은 거리 정보 전송 (처음 한 번만)
        if (_isWatchPaired && !_hasSentEtaToWatch) {
          // 예상 도착 시간 계산 (현재 시간 + 남은 시간)
          String etaFormatted;
          final totalSeconds = _estimatedRemainingSeconds;
          // 현재 시간에 남은 시간을 더해 실제 도착 예상 시각 계산
          final now = DateTime.now();
          final estimatedArrivalTime = now.add(Duration(seconds: totalSeconds));

          /// "12시 03분" 형식으로 포맷팅
          final arrivalHour = estimatedArrivalTime.hour;
          final arrivalMinute = estimatedArrivalTime.minute;
          etaFormatted = '$arrivalHour시 $arrivalMinute분';
          final distanceInMeters = _remainingDistance;
          try {
            _watch.sendMessage({
              'path': '/ETA_DISTANCE',
              'eta': etaFormatted,
              'distance': distanceInMeters
            });
            logger.d('워치로 ETA/거리 정보 전송: $etaFormatted, $distanceInMeters미터');
            _hasSentEtaToWatch = true;
          } catch (e) {
            logger.e('워치 메시지(ETA/거리) 전송 실패: $e');
          }
        }

        if (_modeData?.opponent != null) {
          if (_elapsedSeconds % 5 == 0) {
            await _compareWithPastRecord(sendNotification: false);
          }
          // 30초마다 친구와 비교
          if (_elapsedSeconds % 30 == 0 && _elapsedSeconds > 0) {
            await _compareWithPastRecord(sendNotification: true);
          }
        }

        if (_elapsedSeconds % 3 == 0) {
          _checkDestinationReached();
        }

        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.updateTrackingData(
            elapsedSeconds: _elapsedSeconds,
            // distance: _currentTotalDistance // _currentTotalDistance는 _startLocationTracking에서 직접 관리/업데이트
          );
        }

        if (_elapsedSeconds % 10 == 0 && _elapsedSeconds > 0) {
          _sendDataToAIServer();
        }
      }
    });

    // 트래킹 시작 시 워치에 메시지 전송 (워치가 연결된 경우)
    if (_isWatchPaired) {
      try {
        _watch.sendMessage({
          'path': '/START_TRACKING',
        });
        logger.i('워치로 /START_TRACKING 메시지 전송됨');
      } catch (e) {
        logger.e('워치 메시지(/START_TRACKING) 전송 실패: $e');
      }
    } else {
      logger.w('백그라운드 상태: /START_TRACKING 메시지 전송 생략');
    }
  }

  // 심박수 업데이트 (실제 데이터 사용 또는 목데이터 백업)
  void _updateHeartRate() {
    // 워치가 연결된 경우만 실제 데이터 사용
    bool useRealData = _isWatchPaired;

    if (useRealData) {
      // 실제 데이터 사용 로직 (예: _currentHeartRate가 워치에서 직접 업데이트된다고 가정)
      // 이 부분은 워치 연동 방식에 따라 달라짐
      logger.d('현재 심박수 (워치): $_currentHeartRate');
      logger.d('심박수 업데이트: $_currentHeartRate bpm');
    } else {
      // 워치가 연결되지 않은 경우 심박수 값을 0으로 설정
      if (!_isWatchPaired) {
        _currentHeartRate = 0; // 워치 연결이 없는 경우 0으로 설정
        logger.w('워치 연결 없음: 심박수 0으로 설정');
      }
    }
  }

  // 포맷팅된 시간 문자열
  String get _formattedTime {
    final minutes = _elapsedMinutes;
    final seconds = _elapsedSeconds % 60;

    // 60분 이상일 경우 시간, 분, 초로 표시
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours시 $mins분 $seconds초';
    } else {
      return '$minutes분 $seconds초';
    }
  }

  // 지도에 등산로 경로 표시
  Future<void> _showRouteOnMap() async {
    if (_mapController == null) {
      logger.d('지도 컨트롤러가 초기화되지 않았습니다.');
      return;
    }

    if (_routeCoordinates.isEmpty) {
      logger.d('등산로 경로 데이터가 없습니다. AppState에서 데이터 확인 시도');

      // AppState에서 경로 데이터 직접 가져오기
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.routeCoordinates.isNotEmpty) {
        logger
            .d('AppState에서 경로 데이터 찾음: ${appState.routeCoordinates.length} 포인트');
        setState(() {
          _routeCoordinates = appState.routeCoordinates;
        });
      } else {
        logger.d('AppState에도 경로 데이터가 없습니다. 기본 경로를 설정합니다.');
        _setDefaultRoute();
        // 경로 데이터가 설정된 후 다시 호출
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showRouteOnMap();
        });
        return;
      }
    }

    try {
      logger.d('지도에 경로 표시 시작: ${_routeCoordinates.length} 포인트');

      // 경로 좌표 유효성 검사
      logger.d(
          '첫 번째 좌표: ${_routeCoordinates.first.latitude}, ${_routeCoordinates.first.longitude}');
      logger.d(
          '마지막 좌표: ${_routeCoordinates.last.latitude}, ${_routeCoordinates.last.longitude}');

      // (1) 기존 오버레이 모두 삭제 (위치 오버레이 제외)
      _mapController!.clearOverlays(type: NOverlayType.pathOverlay);
      _mapController!.clearOverlays(type: NOverlayType.marker);

      // 내 위치 오버레이는 별도로 유지
      final locOverlay = _mapController!.getLocationOverlay();
      locOverlay.setIconSize(const Size(64, 64)); // 크기를 더 크게 설정
      locOverlay.setCircleRadius(10); // 원 반경 설정

      // 3) 커스텀 위치 오버레이 아이콘 설정 - 화살표 모양 마커 사용
      try {
        // 화살표 모양의 위치 아이콘 설정 (기본적으로 북쪽을 향하는 화살표)
        final NOverlayImage arrowIcon =
            NOverlayImage.fromAssetImage('lib/assets/images/up-arrow.png');
        locOverlay.setIcon(arrowIcon);

        // 베어링 값 직접 설정 (현재 방향으로)
        locOverlay.setBearing(_deviceHeading);

        // 내 위치 오버레이 색상 설정
        locOverlay.setCircleColor(AppColors.primary.withAlpha(51));
        locOverlay.setCircleOutlineColor(AppColors.primary);

        // 위치 추적 모드 설정 (face 모드로 설정)
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
      } catch (e) {
        logger.e('위치 오버레이 아이콘 설정 오류: $e');
      }

      // 위치 오버레이를 보이게 설정하고 주기적으로 확인
      locOverlay.setIsVisible(true);

      // (2) 경로 오버레이·마커 그리기
      _mapController!.addOverlay(
        NPathOverlay(
          id: _routeOverlayId,
          coords: _routeCoordinates,
          color: AppColors.primary,
          width: 5,
          outlineWidth: 2,
          outlineColor: Colors.white,
          patternInterval: 30,
        ),
      );
      logger.d('경로 오버레이 추가됨');

      // 출발점 마커 추가
      _mapController!.addOverlay(
        NMarker(
          id: _startPointMarkerId,
          position: _routeCoordinates.first,
          caption: const NOverlayCaption(
            text: '출발점',
            textSize: 12,
          ),
        ),
      );
      logger.d('출발점 마커 추가됨');

      // 도착점 마커 추가
      _mapController!.addOverlay(
        NMarker(
          id: _endPointMarkerId,
          position: _routeCoordinates.last,
          caption: const NOverlayCaption(
            text: '도착점',
            textSize: 12,
          ),
        ),
      );
      logger.d('도착점 마커 추가됨');

      // 네비게이션 모드에 따라 카메라 설정 분기
      if (_isNavigationMode) {
        // 네비게이션 모드: 현재 위치 중심으로 카메라 설정
        _mapController!.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(_currentLat, _currentLng),
            zoom: 17,
            tilt: 50,
          ),
        );
        logger.d('네비게이션 모드로 카메라 설정됨');
      } else {
        // 전체 지도 모드: 경로 전체가 보이도록 카메라 설정
        try {
          final bounds = await compute(
              _BackgroundTask.calculateRouteBounds, _routeCoordinates);

          // 계산된 바운드로 카메라 이동
          _mapController!.updateCamera(
            NCameraUpdate.fitBounds(
              NLatLngBounds(
                southWest: NLatLng(bounds['minLat']!, bounds['minLng']!),
                northEast: NLatLng(bounds['maxLat']!, bounds['maxLng']!),
              ),
              padding: const EdgeInsets.all(50),
            ),
          );
          logger.d('전체 경로가 보이도록 카메라 설정됨');
        } catch (e) {
          logger.e('바운드 계산 오류: $e');
          // 오류 발생 시 현재 위치로 카메라 이동
          _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(_currentLat, _currentLng),
              zoom: 15,
            ),
          );
        }
      }
    } catch (e) {
      logger.e('등산로 경로 표시 중 오류 발생: $e');
    }
  }

  // 선택된 등산로 데이터 로딩
  void _loadSelectedRouteData() {
    final appState = Provider.of<AppState>(context, listen: false);
    final selectedRoute = appState.selectedRoute;

    logger.d('선택된 등산로: ${selectedRoute?.name}');

    if (selectedRoute != null && selectedRoute.path.isNotEmpty) {
      logger.d('경로 데이터 있음: ${selectedRoute.path.length} 포인트');
      try {
        // 경로 데이터 변환
        final pathPoints = selectedRoute.path
            .map((coord) {
              final lat = coord['latitude'];
              final lng = coord['longitude'];

              if (lat == null || lng == null) {
                logger.e('좌표 데이터 오류: $coord');
                return null;
              }

              return NLatLng(lat, lng);
            })
            .where((point) => point != null)
            .cast<NLatLng>()
            .toList();

        if (pathPoints.isEmpty) {
          logger.e('변환된 경로 데이터가 없습니다.');
          _setDefaultRoute();
          return;
        }

        // 백그라운드에서 경로 최적화 수행
        compute(_BackgroundTask.optimizeRoute, pathPoints)
            .then((optimizedPath) {
          if (!mounted) return;

          setState(() {
            _routeCoordinates = optimizedPath;

            // 거리와 시간 정보 설정
            _currentTotalDistance = selectedRoute.distance;
            _elapsedMinutes = selectedRoute.estimatedTime;

            // 시작 위치 설정 (경로의 첫 번째 포인트)
            if (_routeCoordinates.isNotEmpty) {
              _currentLat = _routeCoordinates.first.latitude;
              _currentLng = _routeCoordinates.first.longitude;
            }

            logger.d(
                '경로 데이터 로드 완료: $_currentTotalDistance km, $_elapsedMinutes 분');
          });

          // AppState에도 경로 데이터 업데이트
          final appState = Provider.of<AppState>(context, listen: false);
          appState.updateTrackingData(routeCoordinates: optimizedPath);
        });
      } catch (e) {
        logger.e('경로 데이터 처리 중 오류 발생: $e');
        _setDefaultRoute();
      }
    } else {
      logger.e('선택된 경로가 없거나 경로 데이터가 비어있습니다.');
      _setDefaultRoute();
    }
  }

  // 기본 경로 설정 (데이터가 없을 경우)
  void _setDefaultRoute() {
    logger.d('기본 경로 데이터를 사용합니다.');
    setState(() {
      _routeCoordinates = [
        NLatLng(37.5665, 126.9780),
        NLatLng(37.5690, 126.9800),
        NLatLng(37.5720, 126.9830),
        NLatLng(37.5760, 126.9876),
      ];

      // 시작 위치 업데이트
      if (_routeCoordinates.isNotEmpty) {
        _currentLat = _routeCoordinates.first.latitude;
        _currentLng = _routeCoordinates.first.longitude;
      }
    });
  }

  // 위치 권한 확인 및 요청
  Future<void> _checkLocationPermission() async {
    // 위치 서비스 활성화 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return; // 비동기 작업 후 mounted 체크

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.')),
      );
      return;
    }

    // 위치 권한 확인
    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (!mounted) return; // 비동기 작업 후 mounted 체크

    if (status.isDenied) {
      // 권한 요청
      status = await Permission.locationWhenInUse.request();
      if (!mounted) return; // 비동기 작업 후 mounted 체크
    }

    if (status.isPermanentlyDenied) {
      // 사용자가 영구적으로 거부한 경우 앱 설정으로 이동 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.'),
          action: SnackBarAction(
            label: '설정',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    if (status.isGranted) {
      _startLocationTracking();
    }
  }

  // 실시간 위치 추적 시작
  void _startLocationTracking() {
    // 거리 추적 관련 변수들 초기화
    _isAnchorPointSet = false;
    _accumulatedDistanceInMeters = 0;
    _currentTotalDistance = 0;
    _lastDistanceCalcTime = null;
    _anchorPointLat = 0.0;
    _anchorPointLng = 0.0;

    // 칼만 필터 초기화
    _gpsFilter = null;
    _isFilterInitialized = false;
    _lastFilteredLat = 0.0;
    _lastFilteredLng = 0.0;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // 1m 이상 이동 시 콜백 발생
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (!mounted) return;

      logger.d(
          '[BG] 위치 업데이트 수신: ${position.latitude}, ${position.longitude}, 백그라운드 상태: $_currentLifecycleState');
      // 현재 위치 기록
      final now = DateTime.now();
      final double newLat = position.latitude;
      final double newLng = position.longitude;
      final double newAltitude = position.altitude;
      final double currentAccuracy = position.accuracy;
      final double currentSpeedFromSensor = position.speed; // m/s 단위

      // GPS 정확도가 20m 이상이면 완전히 무시 (신뢰할 수 없는 데이터)
      if (currentAccuracy >= 20.0) {
        logger.d(
            'GPS 정확도 불량(${currentAccuracy.toStringAsFixed(1)}m)으로 위치 업데이트 무시');
        return; // 이 위치 업데이트는 완전히 무시하고 다음 업데이트를 기다림
      }

      // 칼만 필터 처리
      double filteredLat = newLat;
      double filteredLng = newLng;

      // 칼만 필터 초기화 또는 업데이트
      if (!_isFilterInitialized) {
        // 첫 위치 수신 시 필터 초기화 (정확도가 양호한 경우)
        if (currentAccuracy < 10.0) {
          _gpsFilter = GpsKalmanFilter(initialLat: newLat, initialLng: newLng);
          _isFilterInitialized = true;
          _lastFilteredLat = newLat;
          _lastFilteredLng = newLng;
          logger.d(
              '칼만 필터 초기화: 처음 위치(${newLat.toStringAsFixed(6)}, ${newLng.toStringAsFixed(6)})');
        } else {
          // 정확도가 낮은 경우 필터 초기화 미루기
          logger.d(
              '필터 초기화 대기 중: GPS 정확도 미달 (${currentAccuracy.toStringAsFixed(1)}m)');
        }
      } else if (_gpsFilter != null) {
        // 급격한 위치 변화 감지 (완전히 다른 위치로 이동한 경우, 예: 앱 재시작 등)
        int distance = _calculateDistanceSync({
          'lat1': _lastFilteredLat,
          'lng1': _lastFilteredLng,
          'lat2': newLat,
          'lng2': newLng,
        });

        if (distance > 100.0) {
          // 100m 이상 순간 이동은 필터 재설정
          logger.d('급격한 위치 변화 감지(${distance.toStringAsFixed(1)}m): 필터 재설정');
          _gpsFilter!.reset(newLat, newLng);
          _lastFilteredLat = newLat;
          _lastFilteredLng = newLng;
        } else {
          // 정상적인 필터 업데이트
          _gpsFilter!.update(newLat, newLng, currentAccuracy);
          filteredLat = _gpsFilter!.latitude;
          filteredLng = _gpsFilter!.longitude;

          // 필터링 효과 로깅 (10초마다)
          if (_elapsedSeconds % 10 == 0) {
            final rawToFilteredDistance = _calculateDistanceSync({
              'lat1': newLat,
              'lng1': newLng,
              'lat2': filteredLat,
              'lng2': filteredLng,
            });
            logger.d(
                '칼만 필터 적용: 원본(${newLat.toStringAsFixed(6)}, ${newLng.toStringAsFixed(6)}) → '
                '필터링(${filteredLat.toStringAsFixed(6)}, ${filteredLng.toStringAsFixed(6)}), '
                '필터 보정량: ${rawToFilteredDistance.toStringAsFixed(2)}m');
          }

          _lastFilteredLat = filteredLat;
          _lastFilteredLng = filteredLng;
        }
      }

      NLatLng? newUserPathPointForAppstate;

      // --- 1. 기준점 기반 5초 간격 이동 거리 계산 ---
      if (!_isAnchorPointSet) {
        // 첫 기준점 설정 (정확도 < 10m 조건)
        if (currentAccuracy < 10.0) {
          _anchorPointLat = filteredLat;
          _anchorPointLng = filteredLng;
          _lastDistanceCalcTime = now;
          _isAnchorPointSet = true;
          _accumulatedDistanceInMeters = 0; // 새 트래킹 시작 시 누적거리 초기화
          _currentTotalDistance = 0; // UI용 거리도 초기화
          logger.d(
              '이동 거리 계산 기준점 설정: Lat: ${_anchorPointLat.toStringAsFixed(6)}, Lng: ${_anchorPointLng.toStringAsFixed(6)} (정확도: ${currentAccuracy.toStringAsFixed(1)}m)');
        } else {
          logger.d(
              '기준점 설정 대기 중: GPS 정확도 미달 (${currentAccuracy.toStringAsFixed(1)}m). 현재 위치: $newLat, $newLng');
        }
      } else if (_lastDistanceCalcTime != null) {
        // 기준점 설정 후 더 실시간으로 거리 계산 (1초 간격)
        final timeSinceLastCalcSeconds =
            now.difference(_lastDistanceCalcTime!).inSeconds;

        if (timeSinceLastCalcSeconds >= 1) {
          // 1초 이상 간격으로 변경
          final int segmentDistanceMeters = _calculateDistanceSync({
            'lat1': _anchorPointLat,
            'lng1': _anchorPointLng,
            'lat2': filteredLat,
            'lng2': filteredLng,
          });

          // 시간에 비례한 최소/최대 합리적 이동 거리 설정
          final double minDeltaForUpdateMeters = 0.0; // 최소 이동 거리 제한 제거
          final double maxDeltaForUpdateMeters =
              _maxReasonableSpeed * timeSinceLastCalcSeconds; // 최대 5m/s * 경과 시간

          // 거리가 합리적 범위 내에 있는 경우만 추가
          if (segmentDistanceMeters >= minDeltaForUpdateMeters &&
              segmentDistanceMeters <= maxDeltaForUpdateMeters) {
            _accumulatedDistanceInMeters += segmentDistanceMeters;
            _currentTotalDistance = _accumulatedDistanceInMeters;

            // 로그 출력 줄이기 (5초 간격)
            if (timeSinceLastCalcSeconds >= 5 || _elapsedSeconds % 10 == 0) {
              logger.d(
                  '${timeSinceLastCalcSeconds}s 간격 이동 거리 추가: ${segmentDistanceMeters}m. 누적: ${_currentTotalDistance}m');
            }
          } else if (segmentDistanceMeters < minDeltaForUpdateMeters) {
            if (_elapsedSeconds % 30 == 0) {
              // 로그 간소화
              logger.d(
                  '이동 거리 무시 (너무 짧음): ${segmentDistanceMeters.toStringAsFixed(1)}m');
            }
          } else {
            // 비정상적으로 긴 거리인 경우
            logger.d(
                '이동 거리 이상 감지: ${segmentDistanceMeters.toStringAsFixed(1)}m / ${maxDeltaForUpdateMeters.toStringAsFixed(1)}m ($timeSinceLastCalcSeconds초)');
          }

          // 새 기준점으로 현재 위치 설정 및 시간 업데이트
          _anchorPointLat = filteredLat;
          _anchorPointLng = filteredLng;
          _lastDistanceCalcTime = now;
        }
      }

      // --- 2. _userPath 업데이트 로직 (사용자 GPS 경로 기록) ---
      if (_isFirstLocationUpdateForUserPath) {
        // UserPath의 첫 점은 정확도만 보고 추가 (최초 위치 설정)
        if (currentAccuracy < 15.0) {
          // UserPath 첫 점도 약간 더 엄격한 정확도
          final firstPoint = NLatLng(filteredLat, filteredLng);
          _userPath.add(firstPoint);
          newUserPathPointForAppstate = firstPoint;
          _isFirstLocationUpdateForUserPath = false;
          _lastLocationUpdateTimeForUserPath = now;
          logger.d(
              'UserPath 첫 점 추가: Lat: ${filteredLat.toStringAsFixed(6)}, Lng: ${filteredLng.toStringAsFixed(6)}');
        }
      } else if (_lastLocationUpdateTimeForUserPath != null &&
          _userPath.isNotEmpty) {
        final NLatLng prevUserPathPoint = _userPath.last;
        final int distanceSinceLastUserPathPoint = _calculateDistanceSync({
          'lat1': prevUserPathPoint.latitude,
          'lng1': prevUserPathPoint.longitude,
          'lat2': filteredLat,
          'lng2': filteredLng,
        });

        final timeDiffMillis =
            now.difference(_lastLocationUpdateTimeForUserPath!).inMilliseconds;

        if (timeDiffMillis > 0) {
          final double speedSinceLastUserPathPoint =
              distanceSinceLastUserPathPoint / (timeDiffMillis / 1000.0); // m/s
          const double minDistanceForUserPath =
              10.0; // UserPath 점 간 최소 이동 거리 (distanceFilter와 유사)

          if (speedSinceLastUserPathPoint <=
                  _maxReasonableSpeed && // 초당 5m 이하 속도
              distanceSinceLastUserPathPoint >=
                  minDistanceForUserPath && // 최소 10m 이상 이동
              currentAccuracy < 20.0) {
            // GPS 정확도 양호

            final newPoint = NLatLng(filteredLat, filteredLng);
            _userPath.add(newPoint);
            newUserPathPointForAppstate = newPoint;
            _lastLocationUpdateTimeForUserPath = now;
            logger.d(
                'UserPath에 점 추가 (${_userPath.length}): 직전점과의 거리 ${distanceSinceLastUserPathPoint.toStringAsFixed(1)}m, 속도 ${speedSinceLastUserPathPoint.toStringAsFixed(1)}m/s');
          } else {
            // 필터링 로그 (필요시 상세화)
            logger.d(
                'UserPath 점 추가 필터됨: 거리 ${distanceSinceLastUserPathPoint.toStringAsFixed(1)}m, 속도 ${speedSinceLastUserPathPoint.toStringAsFixed(1)}m/s');
          }
        }
      }

      // --- 3. 최종 상태 업데이트 (setState) ---
      if (mounted) {
        setState(() {
          _currentLat = filteredLat;
          _currentLng = filteredLng;
          _currentAltitude = newAltitude;
          _currentTotalDistance = _currentTotalDistance;

          // 현재 속도 계산 개선 (Position.speed 사용)
          double newSpeed = 0.0;

          // 1. GPS 속도 센서 값 사용 (m/s -> km/h 변환)
          if (currentSpeedFromSensor >= 0 && currentSpeedFromSensor <= 10.0) {
            // 최대 36km/h 속도 제한
            newSpeed = currentSpeedFromSensor * 3.6; // m/s -> km/h
          }
          // 2. GPS 속도 센서 값이 없거나 비정상적인 경우, 위치 변화로 속도 계산
          else if (_lastLocationUpdateTimeForUserPath != null &&
              _userPath.length > 1) {
            // 마지막 위치부터 현재 위치까지의 거리와 시간으로 속도 계산
            final timeDiffSeconds = now
                    .difference(_lastLocationUpdateTimeForUserPath!)
                    .inMilliseconds /
                1000.0;
            if (timeDiffSeconds > 0) {
              // 현재 위치와 마지막 위치 사이의 거리 계산
              final distanceMeters = _calculateDistanceSync({
                'lat1': _userPath.last.latitude,
                'lng1': _userPath.last.longitude,
                'lat2': filteredLat,
                'lng2': filteredLng,
              });

              // 속도 계산 (m/s)
              final calculatedSpeed = distanceMeters / timeDiffSeconds;

              // 합리적인 값인지 검증 (최대 5m/s = 18km/h)
              if (calculatedSpeed >= 0 &&
                  calculatedSpeed <= _maxReasonableSpeed) {
                newSpeed = calculatedSpeed * 3.6; // m/s -> km/h
                if (_elapsedSeconds % 10 == 0) {
                  logger.d(
                      'GPS 속도 센서 대체 계산: ${newSpeed.toStringAsFixed(1)}km/h (거리: ${distanceMeters.toStringAsFixed(1)}m, 시간: ${timeDiffSeconds.toStringAsFixed(1)}s)');
                }
              }
            }
          }

          // 3. 급격한 변화 방지를 위한 스무딩 적용 (이전 값과 가중 평균)
          if (_currentSpeed > 0 && newSpeed > 0) {
            // 이전 값에 70%, 새 값에 30% 가중치 부여
            _currentSpeed = (_currentSpeed * 0.7) + (newSpeed * 0.3);
          } else {
            // 첫 계산이거나 둘 중 하나가 0인 경우는 그대로 사용
            _currentSpeed = newSpeed;
          }

          // 4. 최종 속도가 합리적인 범위를 벗어나면 보정
          if (_currentSpeed < 0) _currentSpeed = 0.0;
          if (_currentSpeed > 20.0) _currentSpeed = 20.0; // 최대 20km/h로 제한
        });

        // AppState 업데이트 (currentLat/Lng, newUserPathPoint 등)
        final appState = Provider.of<AppState>(context, listen: false);
        appState.updateTrackingData(
          currentLat: filteredLat, // 항상 최신 GPS 위치로 업데이트
          currentLng: filteredLng,
          currentAltitude: newAltitude,
          distance: _currentTotalDistance, // 새로 계산된 거리 반영
          newUserPathPoint:
              newUserPathPointForAppstate, // _userPath에 추가된 경우에만 값 전달
          deviceHeading: _deviceHeading,
        );

        // 네비게이션 모드 시 카메라 업데이트
        if (_mapController != null && _isNavigationMode) {
          _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(filteredLat, filteredLng), // 항상 최신 GPS 위치로
              zoom: 17.0,
              bearing: _deviceHeading,
              tilt: 50.0,
            ),
          );
        }
      }
    });

    // 위치 추적 모드 활성화 (지도 컨트롤러가 있는 경우)
    if (_mapController != null) {
      _enableLocationTracking();
    }
  }

  // 위치 추적 모드 활성화
  void _enableLocationTracking() {
    // 이 메서드는 초기 설정 시에만 사용하고, 이후에는 재호출하지 않습니다.
    // _startLocationTracking() 메서드에서만 호출
    if (_mapController == null) return;

    try {
      // 모드에 따라 다른 추적 모드 설정
      if (_isNavigationMode) {
        // 네비게이션 모드는 face 모드로 설정 (방향에 따라 회전)
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
        logger.d('위치 추적 모드가 활성화되었습니다 (Face 모드)');
      } else {
        // 전체 맵 보기 모드는 NoFollow로 설정 (현재 위치는 표시하되 카메라는 이동하지 않음)
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.noFollow);
        logger.d('위치 추적 모드가 활성화되었습니다 (NoFollow 모드)');
      }
    } catch (e) {
      logger.e('위치 추적 모드 설정 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 네이버 지도 영역
          Container(
            padding: const EdgeInsets.only(bottom: 150),
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(_currentLat, _currentLng),
                  zoom: 17,
                  tilt: 50,
                ),
                mapType: NMapType.terrain,
                nightModeEnable: false,
                scrollGesturesEnable: true,
                zoomGesturesEnable: true,
                rotationGesturesEnable: true,
                tiltGesturesEnable: true,
                locationButtonEnable: false, // 기본 위치 버튼 비활성화
                contentPadding: const EdgeInsets.all(0),
                activeLayerGroups: [
                  NLayerGroup.mountain,
                  NLayerGroup.transit,
                  NLayerGroup.cadastral,
                ],
              ),
              onMapReady: (controller) async {
                logger.d('네이버 지도가 준비되었습니다.');
                _mapController = controller;

                // 1) 위치 추적 모드 활성화
                await controller.setLocationTrackingMode(
                    NLocationTrackingMode.face); // face 모드로 변경

                // 2) 내 위치 오버레이 보이게 설정
                final locOverlay = controller.getLocationOverlay();

                // 내 위치 오버레이 아이콘 설정
                try {
                  logger.d('위치 마커 설정 시작 (onMapReady)...');

                  // 아이콘 크기를 더 크게 설정 (64픽셀로 증가)
                  locOverlay.setIconSize(const Size(64, 64));

                  // 원의 반경을 설정 (완전히 사라지지 않게 약간의 크기 유지)
                  locOverlay.setCircleRadius(10);

                  // 화살표 모양의 위치 아이콘 설정 (기본적으로 북쪽을 향하는 화살표)
                  final NOverlayImage arrowIcon = NOverlayImage.fromAssetImage(
                      'lib/assets/images/up-arrow.png');
                  locOverlay.setIcon(arrowIcon);

                  // 베어링 값을 현재 디바이스 방향으로 설정
                  locOverlay.setBearing(_deviceHeading);

                  // 내 위치 오버레이 색상 설정
                  locOverlay.setCircleColor(AppColors.primary.withAlpha(51));
                  locOverlay.setCircleOutlineColor(AppColors.primary);

                  // 위치 추적 모드를 face로 설정 (아이콘이 항상 방향에 따라 회전하도록)
                  controller
                      .setLocationTrackingMode(NLocationTrackingMode.face);

                  logger.d('위치 마커 설정 완료 (onMapReady)!');
                } catch (e) {
                  logger.e('위치 오버레이 아이콘 설정 오류: $e');
                }

                // 위치 오버레이를 보이게 설정
                locOverlay.setIsVisible(true);
                logger.d('위치 오버레이 표시 설정 (onMapReady): ${locOverlay.isVisible}');

                // 위치 오버레이 항상 보이게 하기 위한 타이머 설정
                _locationOverlayTimer =
                    Timer.periodic(const Duration(seconds: 1), (_) {
                  if (_mapController == null) return;

                  try {
                    // 정기적으로 위치 오버레이가 보이는지 확인하고 필요하면 다시 표시
                    final locOverlay = _mapController!.getLocationOverlay();
                    if (!locOverlay.isVisible) {
                      logger.d('위치 오버레이가 보이지 않아 다시 표시합니다.');
                      locOverlay.setIsVisible(true);
                    }

                    // 모드에 따라 추적 모드 확인 및 재설정 (비동기 처리를 위해 별도 함수 호출)
                    if (!_isToggling) {
                      _checkAndUpdateTrackingMode();
                    }
                  } catch (e) {
                    logger.e('위치 오버레이/추적 모드 확인 중 오류: $e');
                  }
                });

                // 지도가 준비되면 경로 표시 (지연 시간 증가)
                Future.delayed(const Duration(milliseconds: 1000), () async {
                  if (mounted) {
                    logger.d('지도에 경로 표시 시도... (1초 지연 후)');

                    // 경로 데이터가 비어있으면 데이터 로드 재시도
                    if (_routeCoordinates.isEmpty) {
                      logger.d('경로 데이터가 비어있어 다시 로드합니다.');
                      _loadSelectedRouteData();
                      // 경로 데이터 로드 후 잠시 대기
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          logger.d('경로 데이터 로드 후 지도에 표시 시도...');
                          _showRouteOnMap();
                        }
                      });
                    } else {
                      await _showRouteOnMap();
                    }
                  }
                });
              },
              onMapTapped: (point, latLng) {
                logger.d('지도가 탭되었습니다: ${latLng.latitude}, ${latLng.longitude}');
              },
            ),
          ),

          // 네비게이션 모드 토글 버튼
          _buildNavigationToggleButton(),

          // 커스텀 위치 버튼 (좌측 하단)
          _buildLocationButton(),

          // 워치 연결 버튼 추가 (좌측 상단)
          _buildWatchButton(),

          // 토스트 메시지 (지도 상단 가운데)
          if (_showToast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _toastColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    _toastMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

          // 드래그 가능한 바텀 시트
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  // 네비게이션 모드 토글 버튼 위젯
  Widget _buildNavigationToggleButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: FloatingActionButton(
        heroTag: 'navToggle',
        onPressed: _isToggling ? null : _toggleNavigationMode, // 토글 중엔 비활성화
        mini: true,
        backgroundColor: _isNavigationMode
            ? AppColors.primary.withAlpha(_isToggling ? 125 : 255) // 토글 중엔 반투명
            : Colors.white.withAlpha(_isToggling ? 125 : 255),
        child: Icon(
          _isNavigationMode ? Icons.navigation : Icons.map,
          color: _isNavigationMode ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }

  // 드래그 가능한 바텀 시트 위젯
  Widget _buildDraggableBottomSheet() {
    return // 드래그 가능한 바텀 시트 위젯
        DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFEAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // 바텀 시트 핸들 - 고정 영역
              _buildBottomSheetHandle(),
              // 스크롤 가능한 내용 영역
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // 정보 패널
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 기본 정보 (항상 표시)
                          _buildBasicInfoSection(),

                          // 올려진 상태에서만 보이는 정보
                          if (_isSheetExpanded) _buildExpandedInfoSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 바텀 시트 핸들 위젯
  Widget _buildBottomSheetHandle() {
    return GestureDetector(
      onTap: () {
        // 터치 시 시트 확장/축소 전환
        final targetSize = _isSheetExpanded ? 0.25 : 0.9;
        _sheetController.animateTo(
          targetSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onVerticalDragEnd: (details) {
        // 드래그 방향에 따라 시트 확장/축소
        final velocity = details.primaryVelocity ?? 0;
        final targetSize =
            velocity < 0 ? 0.9 : 0.25; // 위로 드래그하면 확장, 아래로 드래그하면 축소
        _sheetController.animateTo(
          targetSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  // 기본 정보 섹션 위젯 - 색상 일관성 개선
  Widget _buildBasicInfoSection() {
    // 거리 변환: 미터를 km로 표시
    String distanceText = '';
    if (_remainingDistance < 1000) {
      // 1km 미만은 미터로 표시
      distanceText = '${_remainingDistance}m';
      logger.d('남은 거리: $distanceText');
    } else {
      // 1km 이상은 소수점 한 자리까지 km로 표시
      distanceText = '${(_remainingDistance / 1000).toStringAsFixed(1)}km';
      logger.d('남은 거리: $distanceText');
    }

    // 이동 거리 텍스트 포맷팅
    String movedDistanceText = '';
    if (_currentTotalDistance < 1000) {
      movedDistanceText = '${_currentTotalDistance.toInt()}m';
    } else {
      movedDistanceText =
          '${(_currentTotalDistance / 1000).toStringAsFixed(2)}km';
    }

    const Color badgeColor = Color(0xFF52A486);
    const Color textColor = Color.fromARGB(255, 58, 133, 106);
    const Color lightBadgeColor = Color.fromARGB(255, 190, 233, 203);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 현재 등반 상태 뱃지
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_chart_outlined,
                  size: 12,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '현재 등반 상태',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 첫 번째 줄 - 메인 정보 카드
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // 남은 거리 & 예상 시간
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 남은 거리
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: textColor
                                      .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.directions_walk,
                                  size: 16,
                                  color: badgeColor, // 아이콘 색상 변경
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '남은 거리',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            distanceText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 세로 구분선
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    // 예상 시간
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: textColor
                                        .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: badgeColor, // 아이콘 색상 변경
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '예상 시간',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formattedRemainingTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 구분선
              Container(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
              ),
              // 속도 & 고도
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 현재 속도
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: textColor
                                      .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.speed,
                                  size: 16,
                                  color: badgeColor, // 아이콘 색상 변경
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '현재 속도',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_currentSpeed.toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 세로 구분선
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    // 고도
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: textColor
                                        .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.terrain,
                                    size: 16,
                                    color: badgeColor, // 아이콘 색상 변경
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '현재 고도',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_currentAltitude.toStringAsFixed(1)}m',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 두 번째 줄 카드 - 등산 시간 & 이동 거리
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 등산 시간
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: textColor
                                  .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              size: 16,
                              color: badgeColor, // 아이콘 색상 변경
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '등산 시간',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                // 세로 구분선
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),
                // 이동 거리
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: textColor
                                    .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.straighten,
                                size: 16,
                                color: badgeColor, // 아이콘 색상 변경
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '이동 거리',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movedDistanceText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 심박수 카드
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isWatchPaired
                  ? Colors.red.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isWatchPaired
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isWatchPaired ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: _isWatchPaired ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 심박수',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isWatchPaired
                            ? const Color(0xFF666666)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isWatchPaired ? '$_currentHeartRate bpm' : '워치와 연동해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isWatchPaired ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_isWatchPaired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.watch_outlined,
                          size: 14,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '연결 중',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 페이스메이커 메시지 카드 - 여기도 동일한 색상 변경
        if (_pacemakerMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pacemakerLevel == '고강도'
                    ? Colors.red.withOpacity(0.3)
                    : _pacemakerLevel == '저강도'
                        ? Colors.blue.withOpacity(0.3)
                        : badgeColor.withOpacity(0.3), // 아이콘 색상 사용
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _pacemakerLevel == '고강도'
                          ? Colors.red.withOpacity(0.1)
                          : _pacemakerLevel == '저강도'
                              ? Colors.blue.withOpacity(0.1)
                              : textColor.withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _pacemakerLevel == '고강도'
                          ? Icons.directions_run
                          : _pacemakerLevel == '저강도'
                              ? Icons.directions_walk
                              : Icons.directions_bike,
                      size: 18,
                      color: _pacemakerLevel == '고강도'
                          ? Colors.red
                          : _pacemakerLevel == '저강도'
                              ? Colors.blue
                              : badgeColor, // 아이콘 색상 변경
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pacemakerLevel == '고강도'
                              ? '고강도 운동 중'
                              : _pacemakerLevel == '저강도'
                                  ? '저강도 운동 중'
                                  : '적정 페이스',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              _pacemakerMessage ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _pacemakerLevel == '고강도'
                                    ? Colors.red.shade700
                                    : _pacemakerLevel == '저강도'
                                        ? Colors.blue.shade700
                                        : badgeColor,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 이전 기록과 현재 기록 비교
  Future<void> _compareWithPastRecord({bool sendNotification = false}) async {
    if (_modeData == null || _modeData?.opponent == null) return;

    try {
      // ModeData의 opponent 확인 로그 출력
      logger.d('=== _compareWithPastRecord에서 ModeData 확인 ===');
      logger
          .d('ModeData.opponent: ${_modeData?.opponent != null ? '있음' : '없음'}');
      logger.d(
          'Path Distance: ${_modeData?.path.distance}km (${_modeData?.path.distance != null ? (_modeData!.path.distance * 1000).toInt() : 0}m)');

      if (_modeData?.opponent != null &&
          _modeData!.opponent!.records.isNotEmpty) {
        final recordsCount = _modeData!.opponent!.records.length;
        logger.d('Records 개수: $recordsCount');

        if (recordsCount > 0) {
          final lastRecord = _modeData!.opponent!.records.last;
          logger.d('마지막 레코드 distance: ${lastRecord.distance}m');
        }
      }

      // opponent의 records 배열에서 현재 시간에 해당하는 기록 찾기
      final opponentRecords = _modeData?.opponent?.records;

      if (opponentRecords == null || opponentRecords.isEmpty) {
        // 기록이 없는 경우 기본값 설정: 거리와 남은 시간을 0으로 유지
        logger.d('기록이 없거나 비어있어 거리와 남은 시간을 0으로 설정합니다.');

        setState(() {
          _competitorData['distance'] = 0; // 거리 0으로 설정
          _competitorData['time'] = 0; // 시간 0으로 설정
          _competitorData['formattedRemainingTime'] = '0분 0초'; // 남은 시간 0으로 설정
          _competitorData['maxHeartRate'] = 0;
          _competitorData['avgHeartRate'] = 0.0;
          _pastDistanceAtCurrentTime = 0.0; // 과거 거리도 0으로 설정
        });

        // 이후 로직은 실행하지 않고 종료
        return;
      } else {
        // records 배열을 사용하여 현재 시간에 해당하는 상대방 진행 거리 계산
        final currentElapsedTime = _elapsedSeconds;

        // 현재 시간보다 작거나 같은 마지막 기록과 큰 첫 번째 기록 찾기
        OpponentRecord? beforeRecord;
        OpponentRecord? afterRecord;

        for (var record in opponentRecords) {
          final recordTime = record.time;
          if (recordTime <= currentElapsedTime) {
            beforeRecord = record;
          } else {
            afterRecord = record;
            break;
          }
        }

        if (beforeRecord != null) {
          if (afterRecord != null) {
            // 두 기록 사이에 현재 시간이 있는 경우 보간
            final beforeTime = beforeRecord.time;
            final afterTime = afterRecord.time;
            final beforeDistance = beforeRecord.distance;
            final afterDistance = afterRecord.distance;

            // 시간 비율로 거리 보간
            final ratio =
                (currentElapsedTime - beforeTime) / (afterTime - beforeTime);
            _pastDistanceAtCurrentTime =
                beforeDistance + (afterDistance - beforeDistance) * ratio;
          } else {
            // 마지막 기록보다 현재 시간이 더 큰 경우, 마지막 기록 사용
            _pastDistanceAtCurrentTime = beforeRecord.distance;
          }
        } else if (afterRecord != null) {
          // 현재 시간이 첫 번째 기록보다 작은 경우, 첫 번째 기록의 비율로 계산
          final afterTime = afterRecord.time;
          final afterDistance = afterRecord.distance;
          final ratio = currentElapsedTime / afterTime;
          _pastDistanceAtCurrentTime = afterDistance * ratio;
        } else {
          _pastDistanceAtCurrentTime = 0.0;
        }

        // 경쟁자 데이터 처리 재호출 (심박수, 남은 시간 등 계산)
        _processOpponentData();

        // 디버깅용 로그
        logger.d(
            '상대 기록 분석: 현재 시간 $currentElapsedTime초, 진행 거리 ${_pastDistanceAtCurrentTime.toStringAsFixed(2)}m');
        logger.d(
            '상대 심박수 정보: 최대 ${_competitorData['maxHeartRate']}, 평균 ${_competitorData['avgHeartRate']?.toStringAsFixed(1)}');
      }

      // 현재 총 이동 거리는 이미 실시간으로 계산되어 _currentTotalDistance에 반영되어 있음
      // 현재 기록과 이전 기록 비교
      final oldAheadState = _isAheadOfRecord;
      _distanceDifference =
          (_currentTotalDistance - _pastDistanceAtCurrentTime).toInt();
      _isAheadOfRecord = _distanceDifference > 0;

      // 항상 _competitorData 업데이트
      _competitorData['isAhead'] = !_isAheadOfRecord; // 내가 앞서면 경쟁자는 뒤처짐

      logger.d(
          '기록 비교: 현재=${_currentTotalDistance.toStringAsFixed(2)}km, 이전=${_pastDistanceAtCurrentTime.toStringAsFixed(2)}km, 차이=${_distanceDifference.toStringAsFixed(2)}km');

      // 앞서거나 뒤처진 상태가 변경되었을 때 또는 sendNotification이 true일 때(30분 주기) 워치에 알림 전송
      if ((_isAheadOfRecord != oldAheadState || sendNotification) &&
          _isWatchPaired) {
        // 기존 알림
        if (_isAheadOfRecord) {
          _notifyWatch('ahead');
          _hasNotifiedWatchForAhead = true;
          _hasNotifiedWatchForBehind = false;
        } else {
          _notifyWatch('behind');
          _hasNotifiedWatchForAhead = false;
          _hasNotifiedWatchForBehind = true;
        }

        // 사용자가 요청한 새로운 형식의 메시지 전송
        // 차이 값 계산 (미터 단위의 절대값)
        int differenceInMeters = _distanceDifference.abs();

        // 앞서는지 뒤처지는지에 따라 메시지 타입 결정
        String progressType = _isAheadOfRecord ? "FAST" : "SLOW";

        // 토스트 메시지 표시
        String toastMessage = _isAheadOfRecord
            ? "이전 기록보다 ${differenceInMeters}m 앞서고 있습니다!"
            : "이전 기록보다 ${differenceInMeters}m 뒤처지고 있습니다!";
        _showToastMessage(toastMessage, isAhead: _isAheadOfRecord);

        // 새로운 형식으로 워치에 메시지 전송
        try {
          await _watch.sendMessage({
            'path': '/PROGRESS',
            'type': progressType,
            'difference': differenceInMeters
          });

          logger.d(
              '진행 상황 워치 메시지 전송 완료: $progressType, 차이: $differenceInMeters 미터');
        } catch (e) {
          logger.e('진행 상황 워치 메시지 전송 실패: $e');
        }
      }

      // 상태 업데이트 (UI 갱신)
      if (mounted) {
        setState(() {
          // 경쟁자 데이터 업데이트
          _competitorData['isAhead'] = !_isAheadOfRecord; // 내가 앞서면 경쟁자는 뒤처짐
        });
      }
    } catch (e) {
      logger.e('기록 비교 중 오류: $e');
    }
  }

  // 현재까지 이동한 총 거리는 _startLocationTracking() 메서드에서 실시간으로 계산하여
  // _currentTotalDistance에 저장됩니다. 기존의 _calculateTotalDistance() 함수는 삭제하였습니다.

  // 목적지 도착 감지
  void _checkDestinationReached() {
    if (_routeCoordinates.isEmpty || _isDestinationReached) return;

    try {
      // 목적지 좌표 (등산로의 마지막 지점)
      final destination = _routeCoordinates.last;

      // 현재 위치와 목적지 간의 거리 계산
      final params = {
        'lat1': _currentLat,
        'lng1': _currentLng,
        'lat2': destination.latitude,
        'lng2': destination.longitude,
      };

      // 거리 계산을 동기적으로 처리하여 지연 없이 즉시 확인
      final double distance = _calculateDistanceSync(params).toDouble();

      // 10초마다 현재 위치와 목적지 간 거리 로그 출력 (디버깅용)
      if (_elapsedSeconds % 10 == 0) {
        logger.d(
            '목적지까지 남은 거리: ${distance.toStringAsFixed(2)}m, 도착 반경: ${_destinationRadius}m');
      }

      // 목적지 반경 내에 있는지 확인
      if (distance <= _destinationRadius && !_isDestinationReached) {
        setState(() {
          _isDestinationReached = true;
        });

        logger.d('목적지 도착! 현재 위치와의 거리: ${distance.toStringAsFixed(2)}m');

        // 도착 알림 표시
        _showDestinationReachedDialog();

        // 워치에 도착 알림 전송 (이전에 알림 안 보냈을 경우)
        if (!_hasNotifiedWatchForDestination) {
          _notifyWatch('destination');
          _hasNotifiedWatchForDestination = true;

          // 워치가 연결된 경우 메시지 전송
          if (_isWatchPaired) {
            try {
              _watch.sendMessage({
                'path': '/REACHED',
              });
              logger.d('목적지 도착 메시지 (/REACHED) 워치로 전송됨');
            } catch (e) {
              logger.e('워치 메시지(/REACHED) 전송 실패: $e');
            }
          } else {
            logger.d('워치 연결 없음: 목적지 도착 메시지 전송 생략');
          }
        }
      }
    } catch (e) {
      logger.e('목적지 도착 감지 중 오류: $e');
    }
  }

  // 목적지 도착 다이얼로그
  void _showDestinationReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 아이콘 영역
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5EC),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    size: 40,
                    color: Color(0xFF52A486),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 타이틀
              Text(
                '목적지 도착',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),

              // 안내 텍스트
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '목적지에 성공적으로 도착했어요!\n등산을 종료하시겠어요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // 버튼 영역
              Row(
                children: [
                  // 계속 등산 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '계속 등산',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 종료 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // 기록 저장 여부를 묻는 다이얼로그 표시
                        _showSaveOptionDialog(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFF52A486),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Color(0xFF52A486).withOpacity(0.5),
                      ),
                      child: Text(
                        '등산 종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 워치에 알림 전송 (워치가 연결된 경우에만)
  void _notifyWatch(String status) {
    // 워치가 연결되어 있지 않으면 알림 전송 생략
    if (!_isWatchPaired) {
      logger.d('워치 연결 없음: 알림 전송 생략 ($status)');
      return;
    }

    // 워치 알림 메시지 구성
    String notificationTitle = '등산 상태 알림';
    String notificationBody = '';

    try {
      switch (status) {
        case 'ahead':
          notificationTitle = '앞서고 있습니다';
          notificationBody =
              '이전 기록보다 ${_distanceDifference.abs().toStringAsFixed(2)}km 앞서고 있습니다.';
          logger.d('[워치 알림 내용] $notificationBody');
          break;
        case 'behind':
          notificationTitle = '뒤처지고 있습니다';
          notificationBody =
              '이전 기록보다 ${_distanceDifference.abs().toStringAsFixed(2)}km 뒤처지고 있습니다.';
          logger.d('[워치 알림 내용] $notificationBody');
          break;
        case 'destination':
          notificationTitle = '목적지 도착';
          notificationBody = '목적지에 도착했습니다. 등산을 종료하시겠습니까?';
          logger.d('[워치 알림 내용] $notificationBody');
          break;
      }

      // 워치 앱에 알림 전송
      _sendWatchNotification(notificationTitle, notificationBody);
    } catch (e) {
      logger.e('워치 알림 전송 중 오류: $e');
    }
  }

  // 워치 알림 전송 메소드 (watch_connectivity 라이브러리 사용)
  void _sendWatchNotification(String title, String messageBody) async {
    try {
      logger.d('워치 알림 전송 시작: $title - $messageBody');

      // 필요한 초기 검사는 _notifyWatch에서 이미 수행했음

      // 워치가 연결되어 있는지 한번 더 확인
      if (!await _watch.isPaired) {
        logger.d('워치가 연결되어 있지 않습니다.');
        return;
      }

      // 워치에 전송할 알림 데이터
      final notificationData = {
        'type': 'notification',
        'title': title,
        'body': messageBody,
        'data': {
          'mountainName': _modeData?.mountain.name ?? '',
          'pathName': _modeData?.path.name ?? '',
          'elapsedTime': _formattedTime,
          'currentDistance': _currentTotalDistance.toStringAsFixed(2),
          'remainingDistance': _remainingDistance,
        }
      };

      // watch_connectivity를 사용하여 워치에 메시지 전송
      await _watch.sendMessage(notificationData);

      logger.d('워치 알림 전송 완료');
    } catch (e) {
      logger.e('워치 알림 전송 실패: $e');
    }
  }

  Widget _buildExpandedInfoSection() {
    // 일반 모드 여부 확인 (opponent가 없으면 일반 모드)
    final bool isGeneralMode = _modeData?.opponent == null;

    // 경쟁자의 남은 시간 포맷팅 (일반 모드가 아닌 경우만)
    String competitorTimeFormatted = '';
    if (!isGeneralMode) {
      // 새로운 시간 계산 로직 사용
      competitorTimeFormatted = _formatOpponentRemainingTime();
    }

    // 앱 테마 컬러 - 현재 등반 상태 뱃지와 동일한 색상으로 통일
    const Color badgeColor = Color(0xFF52A486); // 현재 등반 상태 뱃지의 아이콘 색상
    const Color textColor =
        Color.fromARGB(255, 58, 133, 106); // 현재 등반 상태 뱃지의 텍스트 색상
    const Color lightBadgeColor =
        Color.fromARGB(255, 190, 233, 203); // 현재 등반 상태 뱃지의 배경색

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 20),

        // 비교 모드 정보 (일반 모드가 아닐 때만 표시)
        if (!isGeneralMode) ...<Widget>[
          // 비교 정보 뱃지
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.15), // '현재 등반 상태'와 동일한 배경색
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 12,
                    color: badgeColor, // badgeColor 변수 사용
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '비교 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor, // textColor 변수 사용
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 경쟁 모드 헤더 카드
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // 6으로 변경하여 남은 거리 아이콘과 동일하게
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                    borderRadius:
                        BorderRadius.circular(8), // 8로 변경하여 남은 거리 아이콘과 동일하게
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    size: 16, // 16으로 변경하여 남은 거리 아이콘과 동일하게
                    color: badgeColor, // 아이콘 색상 변경
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기록 비교 모드',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getComparisonModeText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // 상대 남은 거리 & 남은 시간
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 상대 남은 거리
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6), // 6으로 변경
                                  decoration: BoxDecoration(
                                    color: textColor
                                        .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                    borderRadius:
                                        BorderRadius.circular(8), // 8로 변경
                                  ),
                                  child: Icon(
                                    Icons.straighten,
                                    size: 16, // 16으로 변경
                                    color: badgeColor, // 아이콘 색상 변경
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '상대의 이동 거리',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _competitorData['distance'] < 1000
                                  ? '${_competitorData['distance']}m'
                                  : '${(_competitorData['distance'] / 1000).toStringAsFixed(2)}km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 세로 구분선
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      // 상대 남은 시간
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6), // 6으로 변경
                                    decoration: BoxDecoration(
                                      color: textColor
                                          .withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                                      borderRadius:
                                          BorderRadius.circular(8), // 8로 변경
                                    ),
                                    child: Icon(
                                      Icons.timer_outlined,
                                      size: 16, // 16으로 변경
                                      color: badgeColor, // 아이콘 색상 변경
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '상대의 남은 시간',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                competitorTimeFormatted,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: competitorTimeFormatted == '도착했어요!'
                                      ? Color(0xFF333333)
                                      : Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 피드백 메시지 카드
          if (_distanceDifference != 0) _buildFeedbackMessage(),
        ]
        // 일반 모드 정보
        else ...<Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // 6으로 변경
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.15), // 텍스트 색상으로 배경색 변경
                    borderRadius: BorderRadius.circular(8), // 8로 변경
                  ),
                  child: Icon(
                    Icons.hiking,
                    size: 16, // 16으로 변경
                    color: badgeColor, // 아이콘 색상 변경
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '등산 모드',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '일반 등산 모드',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: badgeColor, // 아이콘 색상과 동일하게 변경
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // 등산 종료 버튼
        _buildEndTrackingButton(),

        // 여분의 공간 추가해서 스크롤이 잘 되도록 함
        SizedBox(height: 30),
      ],
    );
  }

  String _getComparisonModeText() {
    final appState = Provider.of<AppState>(context, listen: false);
    final String selectedMode = appState.selectedMode ?? '일반 등산';

    if (selectedMode == '나 vs 나') {
      return '나와의 대결';
    } else if (selectedMode == '나 vs 친구') {
      return '친구와의 대결';
    } else {
      // 기본값은 기존처럼 nickname 또는 '이전 기록'
      return _modeData?.opponent?.nickname ?? '이전 기록';
    }
  }

  // 피드백 메시지 위젯
  Widget _buildFeedbackMessage() {
    // 이전 기록이 있는 경우만 표시
    if (_modeData?.opponent == null ||
        _modeData?.opponent?.records == null ||
        _modeData!.opponent!.records.isEmpty) {
      return SizedBox.shrink();
    }

    final int absDistance =
        _distanceDifference < 0 ? -_distanceDifference : _distanceDifference;
    final String message = _isAheadOfRecord
        ? absDistance < 1000
            ? '${absDistance}m 앞서는 중!'
            : '${(absDistance / 1000).toStringAsFixed(2)}km 앞서는 중!'
        : absDistance < 1000
            ? '${absDistance}m 뒤처지는 중!'
            : '${(absDistance / 1000).toStringAsFixed(2)}km 뒤처지는 중!';

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isAheadOfRecord ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isAheadOfRecord ? Colors.green[800] : Colors.red[800],
            ),
          ),
          SizedBox(width: 4),
          Icon(
            _isAheadOfRecord ? Icons.arrow_upward : Icons.arrow_downward,
            color: _isAheadOfRecord ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }

  // 등산 종료 버튼 위젯
  Widget _buildEndTrackingButton() {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 30, bottom: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF52A486),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextButton.icon(
          onPressed: () {
            if (_isDestinationReached) {
              // 목적지 도달 시: 기존대로 저장 여부 선택 다이얼로그 표시
              _showSaveOptionDialog(context);
            } else {
              // 목적지 미도달 시: 경고 문구와 함께 바로 종료 확인 다이얼로그 표시 (저장 안 함)
              _showEndTrackingDialog(context, false, isEarlyExit: true);
            }
          },
          icon: Icon(
            _isPaused ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
          ),
          label: Text(
            '등산 종료',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showSaveOptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 아이콘 영역
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5EC),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    Icons.save_outlined,
                    size: 40,
                    color: Color(0xFF52A486),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 타이틀
              Text(
                '등산 기록 저장',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),

              // 안내 텍스트
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  '등산 기록을 저장하시겠어요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 8),

              // 기록 저장 설명 카드
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFDCEFE2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF52A486).withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF52A486),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            '저장하면 경험치를 얻고\n나중에 기록도 비교할 수 있어요',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // 버튼 영역
              Row(
                children: [
                  // 저장 안 함 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // 저장하지 않고 종료 확인 다이얼로그 표시
                        _showEndTrackingDialog(context, false);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '저장 안 함',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 저장 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // 저장하고 종료 확인 다이얼로그 표시
                        _showEndTrackingDialog(context, true);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFF52A486),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Color(0xFF52A486).withOpacity(0.5),
                      ),
                      child: Text(
                        '저장',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndTrackingDialog(BuildContext context, bool shouldSave,
      {bool isEarlyExit = false}) {
    // 색상 정의 - 색상을 초록색 계열로 변경 (빨간색에서 변경)
    final Color themeColor = Color(0xFF52A486); // 초록색으로 변경
    final Color lightThemeColor = Color(0xFFE8F5EC); // 연한 초록색 배경
    final Color borderThemeColor = Color(0xFFDCEFE2); // 초록색 테두리

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 아이콘 영역 - 초록색으로 변경
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: lightThemeColor, // 연한 초록색 배경
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    isEarlyExit
                        ? Icons.warning_rounded
                        : Icons.help_outline_rounded,
                    size: 40,
                    color: themeColor, // 초록색 아이콘
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 타이틀
              Text(
                '등산 종료',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),

              // 안내 텍스트
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  '정말로 등산을 종료하시겠어요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 8),

              // 저장 상태 표시 컨테이너
              Container(
                margin: EdgeInsets.symmetric(vertical: 4), // 8에서 4로 줄임
                padding: EdgeInsets.symmetric(
                    vertical: 6, horizontal: 16), // 10에서 6으로 줄임
                decoration: BoxDecoration(
                  color: shouldSave ? Color(0xFFF0F9F4) : Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: shouldSave ? Color(0xFFDCEFE2) : Color(0xFFDCEFE2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4), // 6에서 4로 줄임
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: shouldSave
                                ? themeColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        shouldSave ? Icons.save : Icons.do_not_disturb_alt,
                        color: shouldSave ? themeColor : themeColor,
                        size: 16, // 18에서 16으로 줄임
                      ),
                    ),
                    SizedBox(width: 8), // 12에서 8로 줄임
                    Expanded(
                      child: Text(
                        shouldSave ? '등산 기록이 저장돼요' : '등산 기록이 저장되지 않아요',
                        style: TextStyle(
                          fontSize: 12, // 크기는 그대로 유지
                          fontWeight: FontWeight.w500,
                          color: shouldSave ? themeColor : themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 목적지 미도달 시 경고 컨테이너
              if (isEarlyExit || (!shouldSave && !isEarlyExit))
                Container(
                  margin: EdgeInsets.only(top: 4, bottom: 8),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isEarlyExit
                        ? Colors.red.withOpacity(0.1)
                        : lightThemeColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEarlyExit
                          ? Colors.red.withOpacity(0.3)
                          : borderThemeColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    // crossAxisAlignment를 center로 변경하여 수직 중앙 정렬
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        // margin 제거 (불필요한 위치 조정 방지)
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isEarlyExit
                                  ? Colors.red.withOpacity(0.2)
                                  : themeColor.withOpacity(0.2),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          isEarlyExit
                              ? Icons.error_outline
                              : Icons.info_outline,
                          color: isEarlyExit ? Colors.red : themeColor,
                          size: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          // mainAxisSize 추가하여 컬럼이 필요한 높이만 차지하도록
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isEarlyExit)
                              Text(
                                '목적지에 도달하지 않았어요',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            // isEarlyExit이 true일 때만 간격 추가
                            if (isEarlyExit) SizedBox(height: 2),
                            Text(
                              isEarlyExit ? '경험치도 얻을 수 없어요' : '경험치도 얻을 수 없어요',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isEarlyExit ? Colors.red[700] : themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // 버튼 영역과의 간격 조정
              SizedBox(height: 12), // 16에서 12로 줄임

              // 버튼 영역
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 종료 버튼 - 초록색으로 변경
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _finishTracking(shouldSave,
                            showResultScreen: !isEarlyExit);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: themeColor, // 초록색 배경
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: themeColor.withOpacity(0.5), // 초록색 그림자
                      ),
                      child: Text(
                        '종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 등산 종료 처리 및 서버 전송
  Future<void> _finishTracking(bool shouldSave,
      {bool showResultScreen = true}) async {
    try {
      // 모든 리소스 정리 (백그라운드 서비스 포함)
      _cleanupAllResources();

      // 현재 상태의 데이터 저장
      _saveCurrentTrackingData();

      // AppState
      final appState = Provider.of<AppState>(context, listen: false);
      final token = appState.accessToken ?? '';

      // 선택된 산과 등산로
      final mountainId =
          _modeData?.mountain.id ?? (appState.selectedRoute?.mountainId ?? 0);
      final pathId = _modeData?.path.id ?? (appState.selectedRoute?.id ?? 0);

      // 대결 관련 설정
      final opponentId = _modeData?.opponent?.opponentId;
      final recordId = appState.recordId; // AppState에서 저장된 recordId를 가져옴

      // 선택된 모드 (서버 형식으로 변환)
      final String selectedMode = appState.selectedMode ?? '일반 등산';
      final String serverMode = _convertToServerMode(selectedMode);

      logger.d(
          '등산 종료 요청 준비: mountainId=$mountainId, pathId=$pathId, opponentId=$opponentId, recordId=$recordId, 기록 저장: $shouldSave, 모드: $serverMode');

      // 서버에 전송할 데이터
      // 기록 저장 여부에 관계없이 API는 항상 호출, isSave 값만 다르게 전달
      final modeService = ModeService();

      // 친구 기록 데이터 미리 저장 (endTracking 전에)
      final String? opponentRecordDate = appState.opponentRecordDate;
      final int? opponentRecordTime = appState.opponentRecordTime;
      final int? opponentMaxHeartRate = appState.opponentMaxHeartRate;
      final int? opponentAvgHeartRate = appState.opponentAvgHeartRate;

      // 디버그 로그 추가
      logger.d('[finishTracking] AppState에서 가져온 친구 기록 데이터:');
      logger.d('  - date: $opponentRecordDate');
      logger.d('  - time: $opponentRecordTime');
      logger.d('  - maxHeartRate: $opponentMaxHeartRate');
      logger.d('  - avgHeartRate: $opponentAvgHeartRate');

      logger.d('  - elapsedMinutes: $_elapsedMinutes');

      // 종료 API 호출
      final Map<String, dynamic> response = await modeService.endTracking(
        mountainId: mountainId.toInt(),
        pathId: pathId.toInt(),
        mode: serverMode,
        opponentId: opponentId,
        recordId: recordId,
        isSave: shouldSave, // 사용자 선택에 따라 저장 여부 설정
        finalLatitude: _currentLat,
        finalLongitude: _currentLng,
        finalTime: _elapsedMinutes,
        finalDistance: _currentTotalDistance.toInt(), // km -> m 변환
        records: _trackingRecords,
        token: token,
      );

      logger.d('등산 종료 요청 성공 (기록 저장: $shouldSave)');
      logger.d('종료 api 서버 응답 데이터: ${response['data']}');

      if (_isWatchPaired) {
        if (shouldSave) {
          _watch.sendMessage({
            "path": "/STOP_TRACKING_CONFIRM",
            "badge": response['data']['badge'],
            "averageHeartRate": response['data']['averageHeartRate'],
            "maxHeartRate": response['data']['maxHeartRate'],
            "timeDiff": response['data']['timeDiff'],
          });
          logger.d('워치에 메시지 전송: $response');
        } else {
          _watch.sendMessage({
            "path": "/STOP_TRACKING_CANCEL",
          });
          logger.d('워치에 메시지 전송: $response');
        }
      }

      // 종료 처리 (앱 상태 초기화)
      // appState.endTracking(); // isTracking = false, AppState 리스너들에게 알림

      // 결과 화면으로 이동 또는 홈으로 이동
      if (response['status'] == true &&
          mounted &&
          showResultScreen &&
          shouldSave) {
        // 저장하지 않는 경우 바로 홈화면으로 이동
        if (!shouldSave) {
          logger.d('기록 저장하지 않음: 바로 홈화면으로 이동합니다.');
          appState.endTracking(); // 트래킹 상태 초기화
          appState.changePage(0);
          return;
        }

        // shouldSave가 true일 때만 결과 화면 표시
        final int finalElapsedMinutes = _elapsedMinutes;
        final int finalDistanceMeters = _currentTotalDistance;
        // 이전 기록(AppState에 이미 설정된 값) 캡처
        final String? prevRecordDate = appState.previousRecordDate;
        final int? prevRecordTimeSeconds = appState.previousRecordTime;
        final int? prevMaxHeartRate = appState.previousMaxHeartRate;
        final int? prevAvgHeartRate = appState.previousAvgHeartRate;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TrackingResultScreen(
              resultData: response['data'],
              selectedMode: selectedMode, // 선택된 모드 전달
              opponentRecordDate: opponentRecordDate,
              opponentRecordTime: opponentRecordTime,
              opponentMaxHeartRate: opponentMaxHeartRate,
              opponentAvgHeartRate: opponentAvgHeartRate,
              currentElapsedMinutes: finalElapsedMinutes,
              currentDistanceMeters: finalDistanceMeters,
              previousRecordDate: prevRecordDate,
              previousRecordTimeSeconds: prevRecordTimeSeconds,
              previousMaxHeartRate: prevMaxHeartRate,
              previousAvgHeartRate: prevAvgHeartRate,
            ),
          ),
        );
      } else {
        // 결과 데이터가 없거나 실패했거나 showResultScreen이 false이거나 shouldSave가 false인 경우 홈 화면으로 이동
        appState.endTracking(); // 트래킹 상태 초기화
        appState.changePage(0);
      }
    } catch (e) {
      logger.e('등산 종료 요청 오류: $e');

      // 홈 화면으로 이동
      final appState = Provider.of<AppState>(context, listen: false);
      appState.endTracking();
      appState.changePage(0);
    }
  }

  // 네비게이션 모드 전환
  Future<void> _toggleNavigationMode() async {
    // 이미 토글 중이면 중복 실행 방지
    if (_isToggling) return;

    // 토글 시작
    setState(() {
      _isToggling = true;
    });

    try {
      // 모드 변경
      setState(() {
        _isNavigationMode = !_isNavigationMode;
      });

      // AppState 업데이트
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.updateTrackingData(isNavigationMode: _isNavigationMode);
      }

      if (_mapController != null) {
        if (_isNavigationMode) {
          logger.d('네비게이션 모드 활성화');

          // 카메라 이동 중 플래그 설정 - 방향 회전 방지
          _isMovingToCurrentLocation = true;

          // 위치 추적 모드를 face로 설정 (방향에 맞춰 회전)
          await _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.face);

          // 네비게이션 모드 활성화: 현재 위치 중심, 3D 기울기 적용
          // 현재 보고 있는 방향(디바이스 방향 또는 이동 방향) 적용
          await _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(_currentLat, _currentLng),
              zoom: 17.0,
              bearing: _deviceHeading,
              tilt: 50.0,
            ),
          );

          // 이동 완료 후 방향 기준점 재설정 및 이동 플래그 해제
          _lastAppliedHeading = _deviceHeading;
          _isMovingToCurrentLocation = false;

          // 모드 변경 후 일정 시간 후 다시 한번 추적 모드 확인
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapController != null && _isNavigationMode) {
              try {
                _mapController!
                    .setLocationTrackingMode(NLocationTrackingMode.face);
                logger.d('네비게이션 모드 추적 모드 재확인');
              } catch (e) {
                logger.e('추적 모드 재설정 오류: $e');
              }
            }
          });
        } else {
          // 위치 추적 모드를 noFollow로 설정 (방향 회전 없음)
          await _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.noFollow);

          // 네비게이션 모드 비활성화: 전체 경로 조망
          final bounds = await compute(
              _BackgroundTask.calculateRouteBounds, _routeCoordinates);

          if (!mounted) return;

          await _mapController!.updateCamera(
            NCameraUpdate.fitBounds(
              NLatLngBounds(
                southWest: NLatLng(bounds['minLat']!, bounds['minLng']!),
                northEast: NLatLng(bounds['maxLat']!, bounds['maxLng']!),
              ),
              padding: const EdgeInsets.all(50),
            ),
          );

          await _mapController!.updateCamera(
            NCameraUpdate.withParams(tilt: 0, bearing: 0),
          );
          logger.d('전체 지도 모드 카메라 설정 완료');

          // 모드 변경 후 일정 시간 후 다시 한번 추적 모드 확인
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapController != null && !_isNavigationMode) {
              try {
                _mapController!
                    .setLocationTrackingMode(NLocationTrackingMode.noFollow);
                logger.d('전체 맵 모드 추적 모드 재확인');
              } catch (e) {
                logger.e('추적 모드 재설정 오류: $e');
              }
            }
          });
        }
      }
    } catch (e) {
      logger.e('네비게이션 모드 전환 오류: $e');
      // 오류 발생 시 이동 플래그 초기화
      _isMovingToCurrentLocation = false;
    } finally {
      // 토글 완료
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  // 커스텀 위치 버튼 위젯
  Widget _buildLocationButton() {
    return Positioned(
      left: 11,
      bottom: 190, // 바텀 시트 위에 위치하도록 조정
      child: FloatingActionButton(
        onPressed: _onLocationButtonPressed,
        mini: true,
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: Colors.black54,
        ),
      ),
    );
  }

  // 위치 버튼 클릭 시 처리
  void _onLocationButtonPressed() {
    if (_mapController == null) return;

    // 이전 대기 중인 클릭 취소하고 새로운 클릭만 처리
    _pendingLocationClicks = 1;

    // 이미 처리 중이면 함수 종료 (대기 큐에 추가된 상태)
    if (_isLocationButtonProcessing) {
      logger.d('위치 버튼: 이미 처리 중, 마지막 클릭만 처리됩니다');
      return;
    }

    // 처리 시작
    _isLocationButtonProcessing = true;

    // 위치 추적 모드를 다시 설정
    _resetLocationTrackingMode();

    _moveToCurrentLocation();
  }

  // 위치 추적 모드 재설정
  void _resetLocationTrackingMode() {
    if (_mapController == null) return;

    try {
      // 현재 모드에 맞게 위치 추적 모드 설정
      if (_isNavigationMode) {
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
      } else {
        _mapController!.setLocationTrackingMode(NLocationTrackingMode.noFollow);
      }

      // 위치 오버레이 설정 재적용
      final locOverlay = _mapController!.getLocationOverlay();

      // 크기 및 스타일 설정
      locOverlay.setIconSize(const Size(64, 64));
      locOverlay.setCircleRadius(10);

      try {
        // 화살표 아이콘 설정
        final NOverlayImage arrowIcon =
            NOverlayImage.fromAssetImage('lib/assets/images/up-arrow.png');
        locOverlay.setIcon(arrowIcon);

        // 베어링 값 직접 설정 (현재 디바이스 방향)
        locOverlay.setBearing(_deviceHeading);
      } catch (e) {
        logger.e('아이콘 재설정 오류: $e');
      }

      // 색상 및 가시성 설정
      locOverlay.setCircleColor(AppColors.primary.withAlpha(51));
      locOverlay.setCircleOutlineColor(AppColors.primary);
      locOverlay.setIsVisible(true);

      logger.d('위치 추적 모드 재설정 완료');
    } catch (e) {
      logger.e('위치 추적 모드 재설정 오류: $e');
    }
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation() {
    if (_pendingLocationClicks <= 0) {
      _isLocationButtonProcessing = false;
      return;
    }

    try {
      // 카메라 이동 중 플래그 설정
      _isMovingToCurrentLocation = true;

      // logger.d('카메라를 현재 위치로 이동합니다: $_currentLat, $_currentLng');

      // 카메라를 현재 위치로 이동
      _mapController!
          .updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(_currentLat, _currentLng),
          zoom: 17,
          tilt: _isNavigationMode ? 50 : 0,
          bearing: _isNavigationMode ? _deviceHeading : 0,
        ),
      )
          .then((_) {
        // 이동이 완료되면 카운터 감소
        _pendingLocationClicks--;

        // 모든 클릭 처리 완료
        _isLocationButtonProcessing = false;

        // 이동이 완료되면 이동 중 플래그 해제
        _isMovingToCurrentLocation = false;

        // 이동 후에는 마지막 적용 방향을 현재 방향과 동기화 (움직이지 않는 효과)
        _lastAppliedHeading = _deviceHeading;
      }).catchError((error) {
        logger.e('카메라 업데이트 오류: $error');
        // 오류 발생 시 처리 완료
        _pendingLocationClicks = 0;
        _isLocationButtonProcessing = false;
        _isMovingToCurrentLocation = false;
      });
    } catch (e) {
      logger.e('위치 버튼 처리 중 오류: $e');
      // 오류 발생 시 처리 완료
      _pendingLocationClicks = 0;
      _isLocationButtonProcessing = false;
      _isMovingToCurrentLocation = false;
    }
  }

  // 나침반 센서 구독 시작
  void _startCompassTracking() {
    // 나침반 센서가 사용 가능한지 확인
    if (FlutterCompass.events != null) {
      _compassStream = FlutterCompass.events!.listen((CompassEvent event) {
        if (!mounted) return; // mounted 체크 추가

        // 유효한 방향 데이터가 있을 때만 업데이트
        if (event.heading != null) {
          // 현재 방향 저장
          final newHeading = event.heading!;

          // 방향 변화량 계산 (절대값)
          final double headingChange = (newHeading - _lastAppliedHeading).abs();
          // 360도 근처에서의 방향 변화 특별 처리 (예: 355도 -> 5도)
          final double circularHeadingChange =
              math.min(headingChange, 360 - headingChange);

          setState(() {
            _deviceHeading = newHeading;
          });

          // 위치 오버레이의 베어링을 직접 업데이트
          if (_mapController != null) {
            try {
              final locOverlay = _mapController!.getLocationOverlay();
              locOverlay.setBearing(newHeading);
            } catch (e) {
              logger.e('위치 오버레이 베어링 업데이트 오류: $e');
            }
          }

          // 네비게이션 모드이고 방향 변화가 충분할 때만 카메라 회전
          // 그리고 현재 위치로 이동 중이 아닐 때만 방향 갱신
          if (_isNavigationMode &&
              _mapController != null &&
              circularHeadingChange >= _minHeadingChangeForUpdate &&
              !_isMovingToCurrentLocation) {
            // 부드러운 카메라 회전을 위한 보간 적용
            // 현재 방향과 목표 방향 사이의 중간 값을 계산하여 부드럽게 이동
            final interpolatedHeading =
                _interpolateHeading(_lastAppliedHeading, newHeading);

            // 현재 위치에 초점을 맞추고 카메라를 디바이스 방향으로 회전
            _mapController!
                .updateCamera(
              NCameraUpdate.withParams(
                target: NLatLng(_currentLat, _currentLng),
                bearing: interpolatedHeading,
                tilt: 50,
              ),
            )
                .then((_) {
              // 성공적으로 적용된 경우 마지막 적용 방향 업데이트
              _lastAppliedHeading = newHeading;
            });
          }
        }
      });
      logger.d('나침반 센서 구독 시작');
    } else {
      logger.e('이 기기에서는 나침반 센서를 사용할 수 없습니다.');
    }
  }

  // 방향 보간 계산 함수
  double _interpolateHeading(double current, double target) {
    // 두 방향 사이의 최단 회전 방향 계산
    double diff = target - current;

    // 180도를 넘는 회전은 반대 방향으로 처리 (최단 경로)
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    // 부드러운 이동을 위한 보간 계수 (0.3 = 30% 이동)
    final interpolationFactor = 0.3;

    // 현재 방향에서 목표 방향으로 부분적으로 이동
    double newHeading = current + (diff * interpolationFactor);

    // 0-360 범위로 정규화
    if (newHeading < 0) {
      newHeading += 360;
    } else if (newHeading >= 360) {
      newHeading -= 360;
    }

    return newHeading;
  }

  // 위치 추적 모드를 확인하고 필요하면 업데이트하는 별도 함수
  Future<void> _checkAndUpdateTrackingMode() async {
    if (_mapController == null) return;

    try {
      final currentMode = await _mapController!.getLocationTrackingMode();
      if (_isNavigationMode) {
        // 네비게이션 모드인데 추적 모드가 face가 아니면 재설정
        // if (currentMode != NLocationTrackingMode.face) {
        //   _mapController!.setLocationTrackingMode(NLocationTrackingMode.face);
        //   debugPrint('네비게이션 모드로 추적 모드 재설정 (Face)');
        // }
      } else {
        // 전체 맵 모드인데 추적 모드가 noFollow가 아니면 재설정
        if (currentMode != NLocationTrackingMode.noFollow) {
          _mapController!
              .setLocationTrackingMode(NLocationTrackingMode.noFollow);
          logger.d('전체 맵 모드로 추적 모드 재설정 (NoFollow)');
        }
      }
    } catch (e) {
      logger.e('추적 모드 확인/재설정 중 비동기 오류: $e');
    }
  }

  // 모드 데이터 로드 (이전 기록 정보 포함)
  Future<void> _loadModeData() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // 앱 상태에서 이미 저장된 ModeData가 있으면 가져오기
      if (appState.modeData != null) {
        setState(() {
          _modeData = appState.modeData;
          logger.d('저장된 모드 데이터 로드: ${_modeData?.path.name}');

          // ModeData에서 opponent 정보 가져와서 경쟁자 데이터로 설정
          if (_modeData?.opponent != null) {
            _competitorData = {
              'name': _modeData?.opponent?.nickname ?? '이전 기록',
              'distance': _modeData?.path.distance ?? 0.0,
              'time': _modeData?.path.estimatedTime ?? 0,
              'isAhead': false,
              'maxHeartRate': appState.opponentMaxHeartRate ?? 0,
              'avgHeartRate': appState.opponentAvgHeartRate ?? 0.0,
              'formattedRemainingTime': '0분 0초', // 초기값
            };
            logger.d('경쟁자 데이터 설정: ${_competitorData['name']}');
            logger.d('경쟁자 거리: ${_competitorData['distance']}km');
            logger.d('경쟁자 시간: ${_competitorData['time']}분');
            logger.d('경쟁자 최고 심박수: ${_competitorData['maxHeartRate']}bpm');
            logger.d('경쟁자 평균 심박수: ${_competitorData['avgHeartRate']}bpm');

            // 경쟁자 데이터 처리
            _processOpponentData();
          }
        });
      } else {
        logger.d('저장된 모드 데이터가 없습니다.');
      }
    } catch (e) {
      logger.e('모드 데이터 로드 오류: $e');
    }
  }

  // 상대방 데이터 처리
  void _processOpponentData() {
    if (_modeData?.opponent == null || _modeData?.opponent?.records == null) {
      logger.d('상대방 데이터가 없거나 레코드가 없습니다.');

      // 상대방 데이터가 없을 때 기본값 설정 (남은 거리와 시간을 0으로 유지)
      setState(() {
        _competitorData = {
          'name': _modeData?.opponent?.nickname ?? '이전 기록',
          'distance': 0, // 거리 0으로 설정
          'time': 0, // 시간 0으로 설정
          'formattedRemainingTime': '0분 0초', // 남은 시간 0으로 설정
          'maxHeartRate': 0,
          'avgHeartRate': 0.0,
          'isAhead': false,
        };
      });

      return;
    }

    // ModeData의 opponent 내부의 records 확인
    logger.d('=== ModeData.opponent 데이터 확인 (로그 추가) ===');
    logger.d('Opponent ID: ${_modeData?.opponent?.opponentId}');
    logger.d('Opponent Nickname: ${_modeData?.opponent?.nickname}');
    logger.d('Records 개수: ${_modeData?.opponent?.records.length}');

    // 레코드가 비어있을 때도 기본값 설정
    if (_modeData?.opponent?.records.isEmpty ?? true) {
      logger.d('상대방 레코드가 비어있습니다.');

      setState(() {
        _competitorData = {
          'name': _modeData?.opponent?.nickname ?? '이전 기록',
          'distance': 0, // 거리 0으로 설정
          'time': 0, // 시간 0으로 설정
          'formattedRemainingTime': '0분 0초', // 남은 시간 0으로 설정
          'maxHeartRate': 0,
          'avgHeartRate': 0.0,
          'isAhead': false,
        };
      });

      return;
    }

    if (_modeData?.opponent?.records.isNotEmpty ?? false) {
      // 첫번째 레코드와 마지막 레코드 정보 출력
      final firstRecord = _modeData!.opponent!.records.first;
      final lastRecord = _modeData!.opponent!.records.last;

      logger.d(
          '첫번째 레코드 - 시간: ${firstRecord.time}초, 거리: ${firstRecord.distance}m, 심박수: ${firstRecord.heartRate}');
      logger.d(
          '마지막 레코드 - 시간: ${lastRecord.time}초, 거리: ${lastRecord.distance}m, 심박수: ${lastRecord.heartRate}');
    }

    try {
      final opponentRecords = _modeData!.opponent!.records;
      final totalPathLength = _modeData!.path.distance; // 전체 경로 길이(km)

      // 1. 상대의 진행 거리 (마지막 기록 사용) - m 단위로 변환하고 int로 캐스팅
      final lastRecord = opponentRecords[opponentRecords.length - 1];
      final int opponentDistance = lastRecord.distance.toInt(); // m 단위

      // 2. 상대의 최고 심박수 계산
      int maxHeartRate = 0;
      int totalHeartRate = 0;
      int validHeartRateCount = 0;

      for (var record in opponentRecords) {
        if (record.heartRate > 0) {
          // 0보다 큰 심박수만 고려
          if (record.heartRate > maxHeartRate) {
            maxHeartRate = record.heartRate;
          }
          totalHeartRate += record.heartRate;
          validHeartRateCount++;
        }
      }

      // 3. 상대의 평균 심박수 계산 (int로 변환)
      int avgHeartRate = 0;
      if (validHeartRateCount > 0) {
        avgHeartRate = (totalHeartRate / validHeartRateCount).round();
      }

      // 4. 상대의 평균 속도 및 예상 남은 시간 계산
      double opponentAvgSpeed = 0; // 미터/초
      int opponentRemainingSeconds = 0;

      if (lastRecord.time > 0) {
        // 평균 속도 계산 (m/초)
        opponentAvgSpeed = opponentDistance / lastRecord.time;

        // 남은 거리 계산 (m)
        int remainingDistance = (totalPathLength * 1000) - opponentDistance;
        if (remainingDistance < 0) remainingDistance = 0;

        // 남은 시간 계산 (초)
        if (opponentAvgSpeed > 0) {
          opponentRemainingSeconds =
              (remainingDistance / opponentAvgSpeed).round();
        }
      }

      // 5. 시간 형식 변환 (시:분:초)
      String formattedRemainingTime = _formatSeconds(opponentRemainingSeconds);

      // 6. UI 업데이트를 위한 데이터 저장
      setState(() {
        _competitorData = {
          'name': _modeData?.opponent?.nickname ?? '이전 기록',
          'distance': opponentDistance, // m 단위 int 값
          'time': lastRecord.time, // 초 단위
          'formattedRemainingTime': formattedRemainingTime,
          'maxHeartRate': maxHeartRate,
          'avgHeartRate': avgHeartRate,
          'isAhead': false, // 기본값, 실제 비교 후 업데이트
        };
      });

      logger.d('상대 데이터 처리 완료:');
      logger.d('- 진행 거리: ${opponentDistance}m');
      logger.d('- 예상 남은 시간: $formattedRemainingTime');
      logger.d('- 최고 심박수: $maxHeartRate bpm');
      logger.d('- 평균 심박수: $avgHeartRate bpm');
    } catch (e) {
      logger.e('상대 데이터 처리 중 오류 발생: $e');
    }
  }

  // 초를 시:분:초 형식으로 변환
  String _formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분 $seconds초';
    } else {
      return '$minutes분 $seconds초';
    }
  }

  // 남은 거리 및 예상 시간 계산 함수
  void _calculateRemainingDistanceAndTime() {
    logger.d(
        '_calculateRemainingDistanceAndTime 시작: 경로=${_routeCoordinates.length}개, 유저경로=${_userPath.length}개');
    if (_routeCoordinates.isEmpty) {
      logger.d('calculateRemainingDistance: 경로 좌표가 비어있음!');
      return;
    } // _userPath가 비어있어도 계산 진행

    try {
      // 1. 현재 위치에서 등산로 상의 가장 가까운 지점 찾기
      final currentPosition = NLatLng(_currentLat, _currentLng);
      int minDistance = 1000000; // 초기값을 무한대 대신 큰 숫자로 설정
      int closestPointIndex = 0;

      logger.d('현재 위치: 위도 ${_currentLat}, 경도 ${_currentLng}');

      for (int i = 0; i < _routeCoordinates.length; i++) {
        final params = {
          'lat1': currentPosition.latitude,
          'lng1': currentPosition.longitude,
          'lat2': _routeCoordinates[i].latitude,
          'lng2': _routeCoordinates[i].longitude,
        };

        final distance = _calculateDistanceSync(params);
        if (distance < minDistance) {
          minDistance = distance;
          closestPointIndex = i;
        }
      }

      logger.d('가장 가까운 경로 포인트 인덱스: $closestPointIndex, 거리: ${minDistance}m');

      // 2. 등산로의 총 거리 (pathLength) 활용
      // - 선택된 등산로가 AppState에 있을 경우, 그대로 사용
      // - 아닐 경우, 각 구간 별 거리의 합으로 계산
      double totalPathLength = 0.0;
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.selectedRoute != null) {
        totalPathLength = appState.selectedRoute!.distance * 1000; // km를 m로 변환
        if (_elapsedSeconds % 30 == 0) {
          // 30초마다 로그 출력
          logger.d('등산로 전체 길이(pathLength): ${totalPathLength}m');
        }
      } else {
        // 등산로 경로 좌표로부터 총 길이 계산
        for (int i = 0; i < _routeCoordinates.length - 1; i++) {
          final params = {
            'lat1': _routeCoordinates[i].latitude,
            'lng1': _routeCoordinates[i].longitude,
            'lat2': _routeCoordinates[i + 1].latitude,
            'lng2': _routeCoordinates[i + 1].longitude,
          };
          totalPathLength += _calculateDistanceSync(params);
        }
        if (_elapsedSeconds % 30 == 0) {
          // 30초마다 로그 출력
          logger.d('계산된 등산로 전체 길이: ${totalPathLength}m');
        }
      }

      // 3. 가장 가까운 지점부터 목적지(경로의 마지막 지점)까지의 거리 계산
      int remainingDistance = 0;
      if (closestPointIndex < _routeCoordinates.length - 1) {
        for (int i = closestPointIndex; i < _routeCoordinates.length - 1; i++) {
          final params = {
            'lat1': _routeCoordinates[i].latitude,
            'lng1': _routeCoordinates[i].longitude,
            'lat2': _routeCoordinates[i + 1].latitude,
            'lng2': _routeCoordinates[i + 1].longitude,
          };

          remainingDistance += _calculateDistanceSync(params);
        }
        logger.d(
            '남은 거리 계산값: ${remainingDistance}m (closestPointIndex: $closestPointIndex)');
      } else {
        logger.d('현재 위치가 경로의 마지막 지점이거나 그 이후입니다');
      }

      // 4. 경로 진행률 계산 (pathLength 활용)
      double completedDistance = totalPathLength - remainingDistance;

      // 5. 진행률이 음수가 되지 않도록 보정 (현재 위치가 경로 밖에 있는 경우 등)
      if (completedDistance < 0) completedDistance = 0;
      if (completedDistance > totalPathLength)
        completedDistance = totalPathLength;

      // 6. 진행률 계산 및 남은 거리 설정
      final oldCompletedPercentage = _completedPercentage;
      _completedPercentage = completedDistance / totalPathLength;
      _completedPercentage = _completedPercentage.clamp(0.0, 1.0); // 0~1 범위로 제한

      // 7. 남은 거리 설정 (킬로미터 단위로 변환)
      final oldRemainingDistance = _remainingDistance;
      _remainingDistance = remainingDistance;

      logger.i(
          '최종 남은 거리: ${_remainingDistance}m, 완료율: ${(_completedPercentage * 100).toStringAsFixed(1)}%');

      // 8. 현재까지의 평균 이동 속도 계산
      if (_elapsedSeconds > 0 && completedDistance > 0) {
        final avgSpeed = completedDistance / _elapsedSeconds;

        // 급격한 속도 변화 방지를 위한 가중 평균 (새 속도에 20% 가중치 부여)
        _averageSpeedMetersPerSecond =
            (_averageSpeedMetersPerSecond * 0.8 + avgSpeed * 0.2);

        // 너무 느리거나 빠른 속도 방지 (일반 등산 속도 기준으로 조정)
        _averageSpeedMetersPerSecond =
            math.max(_averageSpeedMetersPerSecond, 0.15); // 최소 초당 15cm
        _averageSpeedMetersPerSecond = math.min(
            _averageSpeedMetersPerSecond, 0.8); // 최대 초당 0.8m (약 2.88km/h)
      }

      // 9. 예상 남은 시간 계산 (초 단위)
      final oldEstimatedRemainingSeconds = _estimatedRemainingSeconds;
      if (_averageSpeedMetersPerSecond > 0) {
        _estimatedRemainingSeconds =
            (remainingDistance / _averageSpeedMetersPerSecond).round();

        // 경사도, 지형 난이도 등을 고려한 보정 (상향 보정)
        double difficultyFactor = 1.2; // 기본 보정 계수를 1.0에서 1.2로 증가 (20% 더 오래 걸림)

        // 남은 부분이 많을수록 더 많은 보정
        difficultyFactor +=
            0.3 * (1.0 - _completedPercentage); // 0.2에서 0.3으로 증가

        // 등산로 난이도에 따른 보정 (AppState에서 선택된 경로가 있는 경우)
        if (appState.selectedRoute != null) {
          switch (appState.selectedRoute!.difficulty) {
            case '상':
              difficultyFactor += 0.5; // 0.3에서 0.5로 증가
              break;
            case '중':
              difficultyFactor += 0.3; // 0.2에서 0.3으로 증가
              break;
            case '하':
              difficultyFactor += 0.15; // 0.1에서 0.15로 증가
              break;
          }
        }

        _estimatedRemainingSeconds =
            (_estimatedRemainingSeconds * difficultyFactor).round();
      }

      // 10. 값이 변경되었을 때만 setState 호출해서 UI 갱신 (불필요한 렌더링 방지)
      if (_completedPercentage != oldCompletedPercentage ||
          _remainingDistance != oldRemainingDistance ||
          _estimatedRemainingSeconds != oldEstimatedRemainingSeconds) {
        setState(() {
          // 이미 값은 변경되어 있으므로 UI 갱신만 수행
        });
      }

      // 디버그 로그 (10초마다 출력)
      if (_elapsedSeconds % 10 == 0) {
        logger.d(
            '남은 거리: ${(_remainingDistance / 1000).toStringAsFixed(2)}km (${_remainingDistance.toStringAsFixed(0)}m), '
            '예상 남은 시간: $_formattedRemainingTime, '
            '평균 속도: ${(_averageSpeedMetersPerSecond * 3.6).toStringAsFixed(1)}km/h, '
            '완료율: ${(_completedPercentage * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      logger.e('남은 거리 및 시간 계산 중 오류: $e');
    }
  }

  // 거리 계산 함수 (동기 버전)
  int _calculateDistanceSync(Map<String, double> params) {
    const double earthRadius = 6371000; // 지구 반경 (미터)
    final double lat1 = params['lat1']!;
    final double lng1 = params['lng1']!;
    final double lat2 = params['lat2']!;
    final double lng2 = params['lng2']!;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadius * c).round(); // 거리 (미터 단위)
  }

  // 각도를 라디안으로 변환 (BackgroundTask의 메서드와 동일)
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // 남은 시간 포맷팅
  String get _formattedRemainingTime {
    final totalSeconds = _estimatedRemainingSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours시 $minutes분 $seconds초';
    } else {
      return '$minutes분 $seconds초';
    }
  }

  // 등산 기록 저장 시작
  void _startTrackingRecords() {
    _recordTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        // mounted 체크 추가
        timer.cancel();
        return;
      }

      if (!_isPaused) {
        _saveCurrentTrackingData();
      }
    });
  }

  // 현재 등산 데이터 저장
  void _saveCurrentTrackingData() {
    // 현재 시간
    final now = DateTime.now();

    // 처음 기록하는 경우 lastRecordTime 초기화
    _lastRecordTime ??= now;

    // 1초마다 records에 데이터 추가
    final secondsSinceLastRecord = now.difference(_lastRecordTime!).inSeconds;
    if (secondsSinceLastRecord >= _recordIntervalSeconds) {
      // 추가할 기록 생성
      final record = {
        'time': _elapsedSeconds,
        'distance': _currentTotalDistance, // 이미 m 단위로 저장
        'latitude': _currentLat,
        'longitude': _currentLng,
        'heartRate': _currentHeartRate,
      };

      // 기록 추가
      _trackingRecords.add(record);
      _lastRecordTime = now;

      logger.d(
          '기록 저장: ${_trackingRecords.length}번째 기록 ($_elapsedSeconds초, ${(_currentTotalDistance / 1000).toStringAsFixed(2)}km)');
    }
  }

  // 블루투스 권한 요청
  Future<void> _requestBluetoothPermissions() async {
    try {
      // 블루투스 관련 권한 요청
      final status = await Permission.bluetooth.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final scanStatus = await Permission.bluetoothScan.request();

      logger.d('블루투스 권한 상태: $status');
      logger.d('블루투스 연결 권한 상태: $connectStatus');
      logger.d('블루투스 스캔 권한 상태: $scanStatus');
    } catch (e) {
      logger.e('블루투스 권한 요청 오류: $e');
    }
  }

  // 워치 연결 상태 확인
  Future<void> _checkWatchConnection() async {
    if (_isCheckingWatch) return;

    if (!mounted) return; // mounted 체크 추가

    setState(() {
      _isCheckingWatch = true;
      _watchStatus = '워치 연결 확인 중...';
    });

    try {
      // 1. 기본 연결 상태 확인
      final isPaired = await _watch.isPaired;

      if (!mounted) return; // mounted 체크 추가

      // 2. 실제 통신 가능 여부 확인을 위한 테스트 메시지 전송
      bool isActuallyConnected = false;
      if (isPaired) {
        try {
          await Future.delayed(const Duration(seconds: 1));
          await _watch.sendMessage({'path': '/PING'});
          isActuallyConnected = true;
        } catch (e) {
          logger.e('워치 통신 테스트 실패: $e');
          isActuallyConnected = false;
        }
      }

      if (!mounted) return; // mounted 체크 추가

      // 3. 최종 연결 상태 결정
      final finalConnectionState = isPaired && isActuallyConnected;

      setState(() {
        _isWatchPaired = finalConnectionState;
        _watchStatus =
            finalConnectionState ? '워치가 연결되어 있습니다' : '워치가 연결되어 있지 않습니다';
        _isCheckingWatch = false;
      });

      logger.d(
          '워치 연결 상태: ${finalConnectionState ? '연결됨' : '연결되지 않음'} (isPaired: $isPaired, isActuallyConnected: $isActuallyConnected)');

      // 4. 연결이 끊어진 경우 관련 기능 비활성화
      if (!finalConnectionState) {
        setState(() {
          _currentHeartRate = 0;
          _pacemakerMessage = null;
          _pacemakerLevel = null;
        });
      }
    } catch (e) {
      setState(() {
        _isWatchPaired = false;
        _watchStatus = '워치 연결 확인 중 오류 발생: $e';
        _isCheckingWatch = false;
        _currentHeartRate = 0;
        _pacemakerMessage = null;
        _pacemakerLevel = null;
      });
      logger.e('워치 연결 확인 중 오류: $e');
    }
  }

  // 워치에 메시지 전송 (watch_connectivity 사용)
  Future<void> _sendMessageToWatch() async {
    // 1. 연결 상태 재확인
    await _checkWatchConnection();

    if (!_isWatchPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워치가 연결되어 있지 않습니다.')),
      );
      return;
    }

    try {
      logger.d('워치에 메시지 전송 시도...');

      // 2. 메시지 전송 전 최종 연결 상태 확인
      if (!await _watch.isPaired) {
        throw Exception('워치 연결이 끊어졌습니다.');
      }

      // 3. 테스트 메시지 전송
      await _watch.sendMessage(
          {'path': '/PROGRESS', "type": "FAST", "difference": 300});

      logger.d('워치에 테스트 메시지 전송 완료');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워치에 메시지를 전송했습니다.')),
      );
    } catch (e) {
      logger.e('워치 메시지 전송 오류: $e');

      // 4. 오류 발생 시 연결 상태 재설정
      setState(() {
        _isWatchPaired = false;
        _watchStatus = '워치 연결이 끊어졌습니다';
        _currentHeartRate = 0;
        _pacemakerMessage = null;
        _pacemakerLevel = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('워치 메시지 전송 실패: $e')),
      );
    }
  }

  // 워치 연결 버튼 위젯
  Widget _buildWatchButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton(
            heroTag: 'watchConnect',
            onPressed: _isCheckingWatch
                ? null
                : () async {
                    await _checkWatchConnection();
                    if (_isWatchPaired) {
                      _sendMessageToWatch();
                    }
                  },
            mini: true,
            backgroundColor: _isWatchPaired ? Colors.green : Colors.grey,
            child: Icon(
              _isWatchPaired ? Icons.watch : Icons.watch_outlined,
              color: Colors.white,
            ),
          ),
          // 워치 상태 표시
          if (_isCheckingWatch || _watchStatus.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isCheckingWatch ? '확인 중...' : _watchStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 토스트 메시지 표시 함수
  void _showToastMessage(String message, {bool isAhead = true}) {
    setState(() {
      _showToast = true;
      _toastMessage = message;
      _toastColor = isAhead ? Colors.green.shade700 : Colors.red.shade700;
    });

    // 이전 타이머 취소
    _toastTimer?.cancel();

    // 3초 후 토스트 메시지 숨기기
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  // AI 서버로 데이터 전송
  Future<void> _sendDataToAIServer() async {
    try {
      final aiBaseUrl = dotenv.get('AI_BASE_URL');
      final url = Uri.parse('$aiBaseUrl/data_collection');
      final appState = Provider.of<AppState>(context, listen: false);
      final token = appState.accessToken ?? '';

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'heartRate': _currentHeartRate,
        'distance': _currentTotalDistance, // 이미 m 단위로 저장
        'speed': _currentSpeed, // km/h
        'time': _elapsedSeconds,
        'altitude': _currentAltitude,
      });

      logger.d('AI 서버로 데이터 전송 요청: $url, body: $body');
      logger.d('[BG] AI 서버 데이터 전송 시도, 백그라운드 상태: $_currentLifecycleState');

      final response = await http.post(url, headers: headers, body: body);

      logger.d('AI 서버 응답: ${response.statusCode}');
      // UTF-8로 디코딩하여 한글이 제대로 표시되도록 함
      logger.d('AI 서버 응답 데이터: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        // 1) UTF-8로 바이트 디코딩
        final decoded = utf8.decode(response.bodyBytes);

        // 2) JSON 파싱
        final Map<String, dynamic> data = jsonDecode(decoded);

        // 3) 필드 꺼내기
        final double score = data['score'];
        final String level = data['level'];
        final String message = data['message'];

        logger.d('score: $score');
        logger.d('level: $level');
        logger.d('message: $message');

        // 페이스메이커 level이 변경되었는지 확인
        if (_previousPacemakerLevel != level) {
          logger.d('페이스메이커 level 변경: $_previousPacemakerLevel -> $level');
          // 워치에 알람 전송 (앱이 백그라운드 상태가 아니거나 워치가 연결된 경우만)
          if (_isWatchPaired) {
            try {
              await _watch.sendMessage(
                  {"path": "/PACEMAKER", "level": level, "message": message});
              logger.d('페이스메이커 level 변경 알람 전송 완료');
            } catch (e) {
              logger.e('페이스메이커 level 변경 알람 전송 실패: $e');
            }
          } else {
            logger.d('워치 연결 없음 또는 백그라운드 상태: 페이스메이커 알람 전송 생략');
          }
          // 이전 level 업데이트
          _previousPacemakerLevel = level;
        }

        // 바텀시트에 메시지 표시
        setState(() {
          _pacemakerMessage = message;
          _pacemakerLevel = level;
        });
      } else {
        logger.e('Error: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('AI 서버 데이터 전송 중 오류 발생: $e');
    }
  }

  String _convertToServerMode(String mode) {
    switch (mode) {
      case '나 vs 나':
        return 'ME';
      case '나 vs 친구':
        return 'FRIEND';
      default:
        return 'GENERAL';
    }
  }

  // 등산 종료/결과 페이지 진입 시 서비스 완전 종료 함수 보강
  void stopTrackingService() {
    logger.d('트래킹 서비스 종료 요청');
    final FlutterBackgroundService service = FlutterBackgroundService();
    service.invoke('stop');
  }

  // 지도 및 트래킹 관련 초기화 함수
  Future<void> _initializeMapAndTracking(AppState appState) async {
    // 1. 현재 위치를 먼저 가져오기 시도 (지도 초기화용)
    try {
      PermissionStatus status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5)); // 5초 타임아웃
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;

            // 초기 위치로 칼만 필터 초기화
            if (position.accuracy < 20.0) {
              _gpsFilter = GpsKalmanFilter(
                  initialLat: position.latitude,
                  initialLng: position.longitude);
              _lastFilteredLat = position.latitude;
              _lastFilteredLng = position.longitude;
              _isFilterInitialized = true;
              logger.d(
                  '초기 위치로 칼만 필터 초기화: Lat: ${position.latitude}, Lng: ${position.longitude}, 정확도: ${position.accuracy}m');
            }

            logger.d('초기 위치 가져오기 성공: Lat: $_currentLat, Lng: $_currentLng');
          });
        }
      } else {
        logger.d('초기 위치 권한 거부됨, 기본값 또는 AppState 값 사용');
      }
    } catch (e) {
      logger.e('초기 위치 가져오기 실패: $e');
    }

    // 2. AppState의 트래킹 상태에 따라 데이터 로드 또는 새 트래킹 준비
    if (appState.isTracking) {
      // ModeData 확인 로그 추가
      if (appState.modeData != null) {
        logger.d('=== AppState에 저장된 ModeData 확인 ===');
        logger.d('ModeData: ${appState.modeData != null ? '있음' : '없음'}');
        logger.d('Mountain: ${appState.modeData?.mountain.name}');
        logger.d(
            'Path: ${appState.modeData?.path.name}, 거리: ${appState.modeData?.path.distance}km');

        if (appState.modeData?.opponent != null) {
          logger.d('Opponent: ${appState.modeData?.opponent?.nickname}');
          logger.d(
              'Opponent Records: ${appState.modeData?.opponent?.records.length}개');

          if (appState.modeData!.opponent!.records.isNotEmpty) {
            final lastRecord = appState.modeData!.opponent!.records.last;
            logger.d(
                '마지막 Record - 시간: ${lastRecord.time}초, 거리: ${lastRecord.distance}m');
          }
        } else {
          logger.d('Opponent: 없음 (일반 등산 모드)');
        }
      }

      final List<NLatLng> previousUserPath = List.from(appState.userPath);
      final List<NLatLng> previousRouteCoordinates =
          List.from(appState.routeCoordinates);
      final double prevLat = appState.currentLat;
      final double prevLng = appState.currentLng;
      final int prevDist = appState.distance;
      final double prevAltitude = appState.currentAltitude;
      final int prevElapsedSeconds = appState.elapsedSeconds;
      final int prevElapsedMinutes = appState.elapsedMinutes;
      final bool prevIsNavigationMode = appState.isNavigationMode;
      final double prevDeviceHeading = appState.deviceHeading;

      bool isPrevDataValid = (prevLat.abs() > 0.001 &&
          prevLng.abs() > 0.001 &&
          prevLat >= -90 &&
          prevLat <= 90 &&
          prevLng >= -180 &&
          prevLng <= 180 &&
          prevDist >= 0 &&
          prevDist < 10000);

      if (isPrevDataValid) {
        _userPath.addAll(previousUserPath);
        if (previousRouteCoordinates.isNotEmpty) {
          _routeCoordinates = previousRouteCoordinates;
        }
        if (!(await Geolocator.isLocationServiceEnabled()) ||
            await Permission.locationWhenInUse.isDenied) {
          _currentLat = prevLat;
          _currentLng = prevLng;
        }
        _anchorPointLat = _currentLat;
        _anchorPointLng = _currentLng;
        _isAnchorPointSet = true;
        _lastDistanceCalcTime = DateTime.now();
        _currentTotalDistance = prevDist;
        _accumulatedDistanceInMeters = _currentTotalDistance * 1000;
        _currentAltitude = prevAltitude;
        _elapsedSeconds = prevElapsedSeconds;
        _elapsedMinutes = prevElapsedMinutes;
        _isNavigationMode = prevIsNavigationMode;
        _deviceHeading = prevDeviceHeading;
        _calculateRemainingDistanceAndTime();
      } else {
        _userPath.clear();
        _routeCoordinates.clear();
        _loadSelectedRouteData();
        _anchorPointLat = 0.0;
        _anchorPointLng = 0.0;
        _isAnchorPointSet = false;
        _accumulatedDistanceInMeters = 0;
        _currentTotalDistance = 0;
        _currentAltitude = 0.0;
        _elapsedSeconds = 0;
        _elapsedMinutes = 0;
        _isNavigationMode = true;
        _deviceHeading = 0.0;
        _remainingDistance = 0;
        _estimatedRemainingSeconds = 0;
        _completedPercentage = 0.0;
        _hasSentEtaToWatch = false; // ETA 메시지 전송 플래그 초기화
      }
    } else {
      _loadSelectedRouteData();
      if (!(await Geolocator.isLocationServiceEnabled()) ||
          await Permission.locationWhenInUse.isDenied) {
        if (_routeCoordinates.isNotEmpty) {
          _currentLat = _routeCoordinates.first.latitude;
          _currentLng = _routeCoordinates.first.longitude;
        }
      }
      _anchorPointLat = 0.0;
      _anchorPointLng = 0.0;
      _isAnchorPointSet = false;
      _accumulatedDistanceInMeters = 0;
      _currentTotalDistance = 0;
      _currentAltitude = 0.0;
      _elapsedSeconds = 0;
      _elapsedMinutes = 0;
      _hasSentEtaToWatch = false; // ETA 메시지 전송 플래그 초기화
    }

    // 3. 나머지 트래킹 관련 기능 시작
    _checkLocationPermission();
    _startTracking();
    _startCompassTracking();
    _startTrackingRecords();
  }

  // 경쟁자 데이터 초기화 메서드
  void _initCompetitorData() {
    _competitorData = {
      'name': '이전 기록',
      'distance': 0,
      'time': 0,
      'isAhead': false,
      'maxHeartRate': 0,
      'avgHeartRate': 0.0,
      'formattedRemainingTime': '0분 0초',
    };
    logger.d('경쟁자 데이터 기본값 초기화 완료');
  }

  // 상대방의 최대 기록 시간을 가져오는 함수 추가
  int _getOpponentMaxTime() {
    if (_modeData?.opponent == null ||
        _modeData?.opponent?.records == null ||
        _modeData!.opponent!.records.isEmpty) {
      return 0;
    }

    // 상대방 기록 중 가장 큰 시간 값을 찾아 반환
    int maxTime = 0;
    for (var record in _modeData!.opponent!.records) {
      if (record.time > maxTime) {
        maxTime = record.time;
      }
    }
    return maxTime;
  }

  // 상대의 남은 시간을 계산하고 포맷팅하는 함수
  String _formatOpponentRemainingTime() {
    // 상대방의 최대 기록 시간
    int opponentMaxTime = _getOpponentMaxTime();

    // 현재 경과 시간과 비교하여 남은 시간 계산
    int remainingSeconds = opponentMaxTime - _elapsedSeconds;

    // 남은 시간이 음수이면 '도착'으로 표시
    if (remainingSeconds <= 0) {
      return '도착했어요!';
    }

    // 양수인 경우, 시간 형식으로 변환
    int hours = remainingSeconds ~/ 3600;
    int minutes = (remainingSeconds % 3600) ~/ 60;
    int seconds = remainingSeconds % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분 $seconds초';
    } else {
      return '$minutes분 $seconds초';
    }
  }
}
