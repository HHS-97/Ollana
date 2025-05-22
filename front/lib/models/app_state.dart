// lib/models/app_state.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import './hiking_route.dart';
import './friend.dart';
import './mode_data.dart';
import '../services/mode_service.dart';

/// 트래킹 단계를 나타내는 열거형
enum TrackingStage {
  search, // 산 검색
  routeSelect, // 등산로 선택
  modeSelect, // 모드 선택
  tracking // 트래킹 중
}

/// 앱의 전역 상태를 관리하는 클래스
class AppState extends ChangeNotifier {
  // ===== 상수 및 초기값 =====
  static const _storage = FlutterSecureStorage();
  static const _defaultLatitude = 37.5665;
  static const _defaultLongitude = 126.9780;
  static const _defaultAltitude = 120.0;

  // ===== 인증 관련 상태 =====
  bool _isLoggedIn = false;
  String? _accessToken;
  String? _profileImageUrl;
  String? _nickname;
  bool? _social;
  String? _userId;
  bool _surveyCompleted = false;

  // ===== 네비게이션 상태 =====
  int _currentPageIndex = 0;

  // ===== 트래킹 관련 상태 =====
  TrackingStage _trackingStage = TrackingStage.search;
  bool _isTracking = false;
  String? _selectedMountain;
  HikingRoute? _selectedRoute;
  String? _selectedMode;

  // ===== 트래킹 데이터 =====
  List<NLatLng> _routeCoordinates = [];
  final List<NLatLng> _userPath = [];
  double _currentLat = _defaultLatitude;
  double _currentLng = _defaultLongitude;
  double _currentAltitude = _defaultAltitude;
  int _elapsedSeconds = 0;
  int _elapsedMinutes = 0;
  int _distance = 0;
  int _maxHeartRate = 0;
  int _avgHeartRate = 0;
  bool _isNavigationMode = true;
  double _deviceHeading = 0;
  int? _climbingIndex;

  // ===== 모드 데이터 =====
  ModeData? _modeData;
  int? _recordId;

  // ===== 친구 기록 데이터 =====
  String? _opponentRecordDate;
  int? _opponentRecordTime;
  int? _opponentMaxHeartRate;
  int? _opponentAvgHeartRate;

  // ===== 현재 기록 데이터 =====
  String? _currentRecordDate;
  int? _currentRecordTime;

  // ====== 이전 기록 데이터 =====
  String? _previousRecordDate;
  int? _previousRecordTime;
  int? _previousMaxHeartRate;
  int? _previousAvgHeartRate;

  // ===== 생성자 =====
  AppState() {
    _initAuth();
  }

  // ===== Getters =====
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get profileImageUrl => _profileImageUrl;
  String? get nickname => _nickname;
  bool? get social => _social;
  String? get userId => _userId;
  bool get surveyCompleted => _surveyCompleted;

  int get currentPageIndex => _currentPageIndex;
  TrackingStage get trackingStage => _trackingStage;
  bool get isTracking => _isTracking;
  String? get selectedMountain => _selectedMountain;
  HikingRoute? get selectedRoute => _selectedRoute;
  String? get selectedMode => _selectedMode;

  List<NLatLng> get routeCoordinates => _routeCoordinates;
  List<NLatLng> get userPath => _userPath;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  double get currentAltitude => _currentAltitude;
  int get elapsedSeconds => _elapsedSeconds;
  int get elapsedMinutes => _elapsedMinutes;
  int get distance => _distance;
  bool get isNavigationMode => _isNavigationMode;
  double get deviceHeading => _deviceHeading;
  ModeData? get modeData => _modeData;
  int? get climbingIndex => _climbingIndex;
  int? get recordId => _recordId;

  // 친구 기록 데이터 getters
  String? get opponentRecordDate => _opponentRecordDate;
  int? get opponentRecordTime => _opponentRecordTime;
  int? get opponentMaxHeartRate => _opponentMaxHeartRate;
  int? get opponentAvgHeartRate => _opponentAvgHeartRate;

  // ===== 현재 기록 데이터 getters =====
  String? get currentRecordDate => _currentRecordDate;
  int? get currentRecordTime => _currentRecordTime;

  // ===== 이전 기록 데이터 getters =====
  String? get previousRecordDate => _previousRecordDate;
  int? get previousRecordTime => _previousRecordTime;
  int? get previousMaxHeartRate => _previousMaxHeartRate;
  int? get previousAvgHeartRate => _previousAvgHeartRate;

  // ===== 인증 관련 메서드 =====

  /// 앱 시작 시 인증 정보 복원
  Future<void> _initAuth() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      final profileImage = await _storage.read(key: 'profileImageUrl');
      final nickname = await _storage.read(key: 'nickname');
      final social = await _storage.read(key: 'social');
      final storedUserId = await _storage.read(key: 'userId');
      final storedSurvey = await _storage.read(key: 'surveyCompleted');

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _profileImageUrl = profileImage;
        _nickname = nickname;
        _social = social != null ? social.toLowerCase() == 'true' : null;
        _userId = storedUserId;
        _isLoggedIn = true;
        _surveyCompleted = storedSurvey?.toLowerCase() == 'true';

        debugPrint('SecureStorage에서 인증 정보 복원 완료');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('인증 정보 복원 오류: $e');
    }
  }

  /// 로그인 상태 토글 (테스트용)
  void toggleLogin() {
    _isLoggedIn = !_isLoggedIn;
    debugPrint('로그인 상태 변경: $_isLoggedIn');
    notifyListeners();
  }

  /// 토큰 및 사용자 정보 설정 및 저장
  Future<void> setToken(
    String token, {
    required String userId,
    String? profileImageUrl,
    String? nickname,
    bool? social,
  }) async {
    _accessToken = token;
    _isLoggedIn = true;
    _profileImageUrl = profileImageUrl;
    _nickname = nickname;
    _social = social;
    _userId = userId;

    try {
      await _saveToSecureStorage({
        'accessToken': token,
        'profileImageUrl': profileImageUrl,
        'nickname': nickname,
        'social': social?.toString(),
        'userId': userId,
      });
      debugPrint('SecureStorage에 인증 정보 저장 완료');
    } catch (e) {
      debugPrint('SecureStorage 저장 오류: $e');
    }

    // 설문 상태 조회
    await fetchSurveyStatus();
    notifyListeners();
  }

  /// 로그아웃: 인증 정보 삭제
  Future<void> clearAuth() async {
    _accessToken = null;
    _profileImageUrl = null;
    _nickname = null;
    _social = null;
    _userId = null;
    _isLoggedIn = false;

    try {
      final keysToDelete = [
        'accessToken',
        'profileImageUrl',
        'nickname',
        'social',
        'userId'
      ];
      await Future.wait(keysToDelete.map((key) => _storage.delete(key: key)));
      debugPrint('SecureStorage에서 인증 정보 삭제 완료');
    } catch (e) {
      debugPrint('SecureStorage 삭제 오류: $e');
    }

    notifyListeners();
  }

  /// SecureStorage에 여러 항목을 저장하는 헬퍼 메서드
  Future<void> _saveToSecureStorage(Map<String, String?> items) async {
    final futures = <Future>[];

    items.forEach((key, value) {
      if (value != null) {
        futures.add(_storage.write(key: key, value: value));
      }
    });

    await Future.wait(futures);
  }

  // ===== 설문 관련 메서드 =====

  /// 설문 완료 상태 설정
  Future<void> setSurveyCompleted(bool completed) async {
    _surveyCompleted = completed;

    try {
      await _storage.write(
        key: 'surveyCompleted',
        value: completed.toString(),
      );
      debugPrint('SecureStorage에 surveyCompleted 저장: $completed');
    } catch (e) {
      debugPrint('SecureStorage에 surveyCompleted 저장 오류: $e');
    }

    notifyListeners();
  }

  /// 서버에서 설문 상태 조회
  Future<void> fetchSurveyStatus() async {
    if (_accessToken == null || _userId == null) {
      debugPrint('fetchSurveyStatus: accessToken 또는 userId가 없습니다');
      return;
    }

    try {
      final aiBaseUrl = dotenv.get('AI_BASE_URL');
      final urlStr = '$aiBaseUrl/has_survey/$_userId';

      final resp = await http.get(
        Uri.parse(urlStr),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $_accessToken',
        },
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        _surveyCompleted = body['has_survey'] as bool;
        debugPrint('설문 상태: $_surveyCompleted');
        notifyListeners();
      } else {
        debugPrint('fetchSurveyStatus 실패: statusCode=${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('fetchSurveyStatus 오류: $e');
    }
  }

  void updateClimbingIndex(int index) {
    _climbingIndex = index;
    notifyListeners();
  }

  // AppState의 fetchClimbingIndex 메서드 수정
  Future<void> fetchClimbingIndex() async {
    if (!_isLoggedIn || _accessToken == null) return;

    try {
      debugPrint('등산지수 가져오기 시작');
      final baseUrl = dotenv.env['AI_BASE_URL']!;
      final url = Uri.parse('$baseUrl/weather');

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $_accessToken',
        },
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final score = data['score'];
        if (score is num) {
          _climbingIndex = score.toInt();
          debugPrint('등산지수 설정됨: $_climbingIndex');
          notifyListeners();
        } else {
          debugPrint('등산지수가 숫자가 아님: $score');
        }
      } else {
        debugPrint('등산지수 조회 실패: HTTP ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('등산지수 조회 오류: $e');
    }
  }

  // ===== 네비게이션 관련 메서드 =====

  /// 페이지 변경
  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  // ===== 트래킹 관련 메서드 =====

  /// 산 선택
  void selectMountain(String name) {
    _selectedMountain = name;
    _trackingStage = TrackingStage.routeSelect;
    notifyListeners();
  }

  /// 등산로 선택 및 단계 전환
  void selectRoute(HikingRoute route) {
    debugPrint('등산로 설정: id=${route.id}, name=${route.name}');
    _selectedRoute = route;
    _trackingStage = TrackingStage.modeSelect;
    notifyListeners();
  }

  /// 등산로 미리 선택 (단계 전환 없이)
  void preSelectRoute(HikingRoute route) {
    _selectedRoute = route;
    debugPrint('사전 등산로 선택: ${route.name}');
    notifyListeners();
  }

  /// 트래킹 단계 초기화
  void resetTrackingStage() {
    if (!_isTracking) {
      _trackingStage = TrackingStage.search;
      _selectedMountain = null;
      _selectedRoute = null;
      _selectedMode = null;
      notifyListeners();
    }
  }

  /// 등산로 선택 화면으로 돌아가기
  void backToRouteSelect() {
    if (!_isTracking) {
      _trackingStage = TrackingStage.search;
      notifyListeners();
    }
  }

  /// 모드 선택 및 트래킹 시작
  Future<void> startTracking(String mode,
      {int? opponentId, int? recordId}) async {
    _selectedMode = mode;
    _recordId = recordId;

    // 디버그 로그 추가 - 트래킹 시작 시 전달받은 값들
    debugPrint('===== 트래킹 시작 정보 =====');
    debugPrint('선택된 모드: $mode');
    debugPrint('레코드 ID: $recordId');
    debugPrint('상대방 ID: $opponentId');
    if (_previousRecordTime != null) {
      debugPrint('저장된 이전 기록 시간(분): $_previousRecordTime');
      if (_previousRecordTime! > 60) {
        final hrs = (_previousRecordTime! / 60).floor();
        final mins = (_previousRecordTime! % 60).toInt();
        debugPrint('시간 변환: $hrs시간 $mins분');
      } else {
        debugPrint('시간 변환: $_previousRecordTime분');
      }
    }
    debugPrint('==========================');

    try {
      if (_selectedRoute == null) {
        debugPrint('선택된 경로 없음');
        return;
      }

      final serverMode = _convertToServerMode(mode);
      final modeOpponentId = _determineOpponentId(mode, opponentId);
      final modeRecordId = _determineRecordId(mode, recordId);

      final modeService = ModeService();
      final result = await modeService.startTracking(
        mountainId: _selectedRoute!.mountainId.toInt(),
        pathId: _selectedRoute!.id.toInt(),
        mode: serverMode,
        opponentId: modeOpponentId,
        recordId: modeRecordId,
        latitude: _currentLat,
        longitude: _currentLng,
        token: _accessToken ?? '',
      );

      // 모드 데이터 저장
      _modeData = result;
      debugPrint('모드 데이터 저장: ${result.mountain.name}, ${result.path.name}');

      // 상대방 심박수 정보 저장
      if (result.opponent != null) {
        if (result.opponent!.maxHeartRate != null) {
          _opponentMaxHeartRate = result.opponent!.maxHeartRate;
          debugPrint('상대방 최대 심박수: $_opponentMaxHeartRate');
        }

        if (result.opponent!.averageHeartRate != null) {
          _opponentAvgHeartRate = result.opponent!.averageHeartRate?.toInt();
          debugPrint('상대방 평균 심박수: $_opponentAvgHeartRate');
        }
      }

      // 트래킹 상태로 변경
      _isTracking = true;
      _trackingStage = TrackingStage.tracking;

      // 트래킹 데이터 초기화
      if (_elapsedSeconds == 0 && _elapsedMinutes == 0) {
        _resetTrackingData();
        _setRouteCoordinates(result);
      }

      notifyListeners();
      debugPrint('트래킹 시작: $mode');
    } catch (e) {
      debugPrint('트래킹 시작 오류: $e');
    }
  }

  /// 모드값을 서버 형식으로 변환
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

  /// 모드에 따른 상대방 ID 결정
  int? _determineOpponentId(String mode, int? opponentId) {
    if (mode == '나 vs 친구') {
      return opponentId;
    }
    return null;
  }

  /// 모드에 따른 기록 ID 결정
  int? _determineRecordId(String mode, int? recordId) {
    if (mode == '나 vs 나' && recordId != null) {
      return recordId;
    }
    return null;
  }

  /// 경로 좌표 설정
  void _setRouteCoordinates(ModeData data) {
    List<Map<String, dynamic>> path;

    if (data.path.path.isNotEmpty) {
      path = data.path.path;
    } else if (_selectedRoute?.path.isNotEmpty ?? false) {
      path = _selectedRoute!.path;
    } else {
      return;
    }

    final pathPoints = path
        .map((coord) =>
            NLatLng(coord['latitude'] ?? 0.0, coord['longitude'] ?? 0.0))
        .toList();

    if (pathPoints.isNotEmpty) {
      _routeCoordinates = pathPoints;
      debugPrint('경로 좌표 설정 완료 (${pathPoints.length} 포인트)');
    }
  }

  /// 트래킹 데이터 초기화
  void _resetTrackingData() {
    _userPath.clear();
    _elapsedSeconds = 0;
    _elapsedMinutes = 0;
    _distance = _selectedRoute?.distance ?? 0;
    _maxHeartRate = 0;
    _avgHeartRate = 0;

    if (_selectedRoute != null && _selectedRoute!.path.isNotEmpty) {
      final first = _selectedRoute!.path.first;
      _currentLat = first['latitude'] ?? _currentLat;
      _currentLng = first['longitude'] ?? _currentLng;
      _userPath.add(NLatLng(_currentLat, _currentLng));
    }
  }

  /// 트래킹 데이터 업데이트
  void updateTrackingData({
    List<NLatLng>? routeCoordinates,
    NLatLng? newUserPathPoint,
    double? currentLat,
    double? currentLng,
    double? currentAltitude,
    int? elapsedSeconds,
    int? distance,
    int? maxHeartRate,
    int? avgHeartRate,
    bool? isNavigationMode,
    double? deviceHeading,
  }) {
    bool changed = false;

    if (routeCoordinates != null) {
      _routeCoordinates = routeCoordinates;
      changed = true;
    }
    if (newUserPathPoint != null) {
      _userPath.add(newUserPathPoint);
      changed = true;
    }
    if (currentLat != null) {
      _currentLat = currentLat;
      changed = true;
    }
    if (currentLng != null) {
      _currentLng = currentLng;
      changed = true;
    }
    if (currentAltitude != null) {
      _currentAltitude = currentAltitude;
      changed = true;
    }
    if (elapsedSeconds != null) {
      _elapsedSeconds = elapsedSeconds;
      _elapsedMinutes = elapsedSeconds ~/ 60;
      changed = true;
    }
    if (distance != null) {
      _distance = distance;
      changed = true;
    }
    if (maxHeartRate != null) {
      _maxHeartRate = maxHeartRate;
      changed = true;
    }
    if (avgHeartRate != null) {
      _avgHeartRate = avgHeartRate;
      changed = true;
    }
    if (isNavigationMode != null) {
      _isNavigationMode = isNavigationMode;
      changed = true;
    }
    if (deviceHeading != null) {
      _deviceHeading = deviceHeading;
      changed = true;
    }

    if (changed) notifyListeners();
  }

  /// 앱 시작 시 등산 상태 확인
  Future<bool> checkTrackingStatus() async {
    try {
      if (_accessToken == null || _accessToken!.isEmpty) {
        debugPrint('트래킹 상태 확인: 토큰이 없습니다');
        return false;
      }

      final modeService = ModeService();
      final trackingData = await modeService.checkActiveTracking(_accessToken!);

      if (trackingData == null) {
        debugPrint('트래킹 상태 확인: 활성화된 등산이 없습니다');
        return false;
      }

      // 등산 중 상태 복원
      _restoreTrackingData(trackingData);
      return true;
    } catch (e) {
      debugPrint('트래킹 상태 확인 오류: $e');
      return false;
    }
  }

  /// 등산 중 상태 복원
  void _restoreTrackingData(ModeData data) {
    _selectedMountain = data.mountain.name;
    _selectedRoute = data.path;
    _modeData = data;

    // 모드 정보 복원
    if (data.opponent != null) {
      _selectedMode = data.opponent?.opponentId == null ? '나 vs 나' : '나 vs 친구';
    } else {
      _selectedMode = '일반 등산';
    }

    _isTracking = true;
    _trackingStage = TrackingStage.tracking;

    // 경로 좌표 설정
    _setRouteCoordinates(data);

    notifyListeners();
    debugPrint('트래킹 상태 복원 완료: ${data.mountain.name}, ${data.path.name}');
  }

  /// 친구 기록 데이터 설정
  void setOpponentRecordData({
    required String date,
    required int time,
    int? maxHeartRate,
    int? avgHeartRate,
  }) {
    _opponentRecordDate = date;
    _opponentRecordTime = time;
    _opponentMaxHeartRate = maxHeartRate;
    _opponentAvgHeartRate = avgHeartRate;
    notifyListeners();
  }

  /// 이전 기록 데이터 설정
  void setPreviousRecordData({
    required String date,
    required int time,
    int? maxHeartRate,
    int? avgHeartRate,
  }) {
    // 디버그 로그 추가
    debugPrint('===== setPreviousRecordData 호출됨 =====');
    debugPrint('날짜: $date');
    debugPrint('원본 시간 값(분): $time');
    if (time > 60) {
      final hrs = (time / 60).floor();
      final mins = (time % 60).toInt();
      debugPrint('시간 변환: $hrs시간 $mins분');
    } else {
      debugPrint('시간 변환: $time분');
    }
    debugPrint('====================================');

    // 상태 변경을 마이크로태스크로 지연시켜 빌드 중에 발생하지 않도록 함
    Future.microtask(() {
      _previousRecordDate = date;
      _previousRecordTime = time;
      _previousMaxHeartRate = maxHeartRate;
      _previousAvgHeartRate = avgHeartRate;
      notifyListeners();
    });
  }

  /// 트래킹 종료
  void endTracking() {
    _isTracking = false;
    _trackingStage = TrackingStage.search;
    _selectedMountain = null;
    _selectedRoute = null;
    _selectedMode = null;
    _modeData = null;
    _recordId = null;
    // 친구 기록 데이터도 초기화
    _opponentRecordDate = null;
    _opponentRecordTime = null;
    _opponentMaxHeartRate = null;
    _opponentAvgHeartRate = null;
    _resetTrackingData();
    notifyListeners();
  }
}
