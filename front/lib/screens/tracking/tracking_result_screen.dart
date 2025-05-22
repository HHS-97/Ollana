import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../utils/app_colors.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../screens/home_screen.dart';
import 'package:logger/logger.dart';

class TrackingResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final String? selectedMode;
  final String? opponentRecordDate;
  final int? opponentRecordTime;
  final int? opponentMaxHeartRate;
  final int? opponentAvgHeartRate;
  final int? currentElapsedMinutes;
  final int? currentDistanceMeters;
  final String? previousRecordDate;
  final int? previousRecordTimeSeconds;
  final int? previousMaxHeartRate;
  final int? previousAvgHeartRate;

  const TrackingResultScreen({
    super.key,
    required this.resultData,
    this.selectedMode,
    this.opponentRecordDate,
    this.opponentRecordTime,
    this.opponentMaxHeartRate,
    this.opponentAvgHeartRate,
    this.currentElapsedMinutes,
    this.currentDistanceMeters,
    this.previousRecordDate,
    this.previousRecordTimeSeconds,
    this.previousMaxHeartRate,
    this.previousAvgHeartRate,
  });

  @override
  State<TrackingResultScreen> createState() => _TrackingResultScreenState();
}

class _TrackingResultScreenState extends State<TrackingResultScreen> {
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

  @override
  void initState() {
    super.initState();
    // 결과 페이지 진입 시 백그라운드 서비스와 알림 완전 종료
    _cleanupAllResources();
  }

  // 모든 리소스 정리
  void _cleanupAllResources() {
    logger.i('결과 화면에서 모든 트래킹 리소스 정리 시작');
    _stopBackgroundService();
    _cancelAllNotifications();
    logger.i('결과 화면에서 모든 트래킹 리소스 정리 완료');
  }

  // 백그라운드 서비스 종료
  void _stopBackgroundService() {
    try {
      // FlutterBackgroundService를 통해 서비스 종료
      final service = FlutterBackgroundService();
      service.invoke('stop');
      logger.i('백그라운드 서비스 종료');
    } catch (e) {
      logger.e('백그라운드 서비스 종료 중 오류: $e');
    }
  }

  // 모든 알림 종료
  void _cancelAllNotifications() {
    try {
      // 로컬 알림 종료 로직
      logger.i('모든 알림 종료 시도');
      // 더 간단한 방식으로 처리
    } catch (e) {
      logger.e('알림 종료 중 오류: $e');
    }
  }

  // 분을 시간 문자열로 변환 (예: 90 -> "1시간 30분")
  String _formatMinutes(int minutes) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '$hours시간 $remainingMinutes분';
    } else {
      return '$remainingMinutes분';
    }
  }

  String _formatSeconds(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    if (seconds < 60) {
      return '$remainingSeconds초';
    } else if (seconds < 3600) {
      return '$minutes분 $remainingSeconds초';
    } else {
      return '$hours시간 $minutes분 $remainingSeconds초';
    }
  }

  // 날짜를 "YY.MM.DD" 형식으로 포맷팅
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      // 날짜가 없는 경우 오늘 날짜 사용
      final now = DateTime.now();
      return '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    }

    try {
      // 서버에서 받은 날짜 형식 파싱 (예: "2025-05-10" -> "25.05.10")
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final year = parts[0].substring(2); // "2025" -> "25"
        final month = parts[1];
        final day = parts[2];
        return '$year.$month.$day';
      }

      // 다른 형식이면 그대로 반환
      return dateString;
    } catch (e) {
      logger.e('날짜 변환 오류: $e');
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // 위젯에서 전달된 모드를 우선 사용하고, 없으면 AppState에서 가져옴
    final selectedMode = widget.selectedMode ?? appState.selectedMode;
    final isVsMode = selectedMode == '나 vs 나' || selectedMode == '나 vs 친구';

    // 산 이름 가져오기
    final String mountainName = appState.selectedMountain ?? '등산';

    // 디버깅을 위한 로그 추가
    logger.i('TrackingResultScreen - 선택된 모드: $selectedMode');
    logger.i('TrackingResultScreen - 결과 데이터: ${widget.resultData}');
    logger.i('TrackingResultScreen - 산 이름: $mountainName');

    // 등산 결과 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0, // 스크롤 시 엘리베이션 변화 방지
        title: Text(
          '$mountainName 등산 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildResultContent(selectedMode, mountainName),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(String? selectedMode, String mountainName) {
    // 어떤 모드인지에 따라 다른 결과 화면 표시
    // 디버깅 로그 추가
    logger.i('_buildResultContent - 모드: $selectedMode');

    if (selectedMode == '나 vs 나') {
      logger.i('나 vs 나 결과 화면 빌드');
      return _buildVsMeResult(mountainName);
    } else if (selectedMode == '나 vs 친구') {
      logger.i('나 vs 친구 결과 화면 빌드');
      return _buildVsFriendResult(mountainName);
    } else {
      logger.i('일반 등산 결과 화면 빌드');
      return _buildGeneralResult(mountainName);
    }
  }

  Widget _buildVsMeResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);
    final timeDiff = widget.resultData['timeDiff'];
    final String timeDiffText = timeDiff != null
        ? timeDiff < 0
            ? "${timeDiff.abs()}분 단축"
            : timeDiff > 0
                ? "$timeDiff분 증가"
                : "변화 없음" // timeDiff가 0인 경우
        : "";

    // 현재/이전 기록
    final int currMaxHr = (widget.resultData['maxHeartRate'] is double)
        ? (widget.resultData['maxHeartRate'] as double).round()
        : widget.resultData['maxHeartRate'] ?? 0;
    final int currAvgHr = (widget.resultData['averageHeartRate'] is double)
        ? (widget.resultData['averageHeartRate'] as double).round()
        : widget.resultData['averageHeartRate'] ?? 0;
    final int prevTime = widget.previousRecordTimeSeconds ?? 0;
    final int prevMaxHr = widget.opponentMaxHeartRate ?? 0;
    final int prevAvgHr = widget.opponentAvgHeartRate ?? 0;

    // badge URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 색상 정의 - 더 세련된 컬러 스킴
    final Color primaryColor = Color(0xFF53A487);
    final Color previousColor = Color(0xFF8E9EAB); // 부드러운 청회색
    final Color currentColor = Color(0xFF3A8A6E); // 진한 녹색
    final Color positiveColor = Color(0xFF53A487); // 긍정적 변화 (녹색)
    final Color negativeColor = Color(0xFFE57373); // 부정적 변화 (빨간색)
    final Color neutralColor = Color(0xFF9E9E9E); // 중립적 색상 (회색)
    final Color cardColor = Colors.white;
    final Color bgColor = Color(0xFFF8F9FA);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션 - 더 세련된 디자인 (아이콘과 박스 크기 축소)
            Container(
              margin: EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8), // 패딩 축소
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10), // 모서리 반경 축소
                    ),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      size: 18, // 아이콘 크기 축소
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '나의 기록 비교',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // 날짜 비교 카드 - 심플한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 이전 날짜
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: previousColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(appState.previousRecordDate ?? ''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: previousColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // VS 표시 - 심플한 스타일
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // 현재 날짜
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: currentColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(appState.currentRecordDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: currentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 통합 비교 카드 - 더 심플하고 모던한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 등산 시간 비교
                  _buildModernComparisonItem(
                    title: '총 등산 시간',
                    icon: Icons.timer_outlined,
                    iconColor: primaryColor, // 아이콘 색상 통일
                    previousValue: _formatMinutes(prevTime),
                    currentValue: _formatMinutes(appState.elapsedMinutes),
                    changeText: timeDiffText,
                    isPositive: timeDiff != null && timeDiff < 0,
                    previousColor: previousColor,
                    currentColor: currentColor,
                    showDivider: true,
                    iconBgColor: primaryColor.withOpacity(0.1), // 배경색 통일
                  ),

                  // 최고 심박수 비교
                  _buildModernComparisonItem(
                    title: '최고 심박수',
                    icon: Icons.monitor_heart_rounded,
                    iconColor: primaryColor, // 아이콘 색상 통일
                    previousValue: '$prevMaxHr bpm',
                    currentValue: '$currMaxHr bpm',
                    changeText: currMaxHr > prevMaxHr
                        ? '${currMaxHr - prevMaxHr} bpm 증가'
                        : currMaxHr < prevMaxHr
                            ? '${prevMaxHr - currMaxHr} bpm 감소'
                            : '변화 없음',
                    isPositive: currMaxHr < prevMaxHr,
                    previousColor: previousColor,
                    currentColor: currentColor,
                    showDivider: true,
                    iconBgColor: primaryColor.withOpacity(0.1), // 배경색 통일
                  ),

                  // 평균 심박수 비교
                  _buildModernComparisonItem(
                    title: '평균 심박수',
                    icon: Icons.favorite_border_rounded,
                    iconColor: primaryColor, // 아이콘 색상 통일
                    previousValue: '$prevAvgHr bpm',
                    currentValue: '$currAvgHr bpm',
                    changeText: currAvgHr > prevAvgHr
                        ? '${currAvgHr - prevAvgHr} bpm 증가'
                        : currAvgHr < prevAvgHr
                            ? '${prevAvgHr - currAvgHr} bpm 감소'
                            : '변화 없음',
                    isPositive: currAvgHr < prevAvgHr,
                    previousColor: previousColor,
                    currentColor: currentColor,
                    showDivider: false,
                    iconBgColor: primaryColor.withOpacity(0.1), // 배경색 통일
                  ),
                ],
              ),
            ),

            // 뱃지 표시 - "획득 뱃지" 제거하고 더 큰 뱃지로 수정
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 여백 추가하여 전체적으로 아래로 내림
                    SizedBox(height: 30),

                    // 뱃지 이미지 (뱃지 외곽선에서 바로 후광이 나오는 효과)
                    Center(
                      child: Container(
                        width: 160, // 크기 증가
                        height: 160, // 크기 증가
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 후광 효과 레이어
                            Container(
                              width: 200, // 크기 증가
                              height: 200, // 크기 증가
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  // 바깥쪽 후광 (넓게 퍼지는 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[100]!.withOpacity(0.9),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                  // 중간 후광 (선명한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[200]!.withOpacity(0.8),
                                    blurRadius: 30,
                                    spreadRadius: 12,
                                  ),
                                  // 안쪽 후광 (강한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[300]!.withOpacity(0.7),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                            // 뱃지 이미지
                            Container(
                              width: 160, // 크기 증가
                              height: 160, // 크기 증가
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber[200]!, // 더 은은한 노란색
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: badgeUrl.isNotEmpty
                                    ? Image.network(
                                        badgeUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.amber[50], // 더 은은한 배경색
                                          child: Icon(
                                            Icons.emoji_events_rounded,
                                            size: 80, // 크기 증가
                                            color:
                                                Colors.amber[500], // 더 은은한 노란색
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.amber[50], // 더 은은한 배경색
                                        child: Icon(
                                          Icons.emoji_events_rounded,
                                          size: 80, // 크기 증가
                                          color: Colors.amber[500], // 더 은은한 노란색
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 뱃지 아래에 텍스트와 아이콘 추가
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 축하하는 아이콘
                        Icon(
                          Icons.celebration_rounded, // 축하 아이콘
                          color: Colors.amber[400],
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "뱃지를 획득했어요!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333), // 짙은 회색
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // 추가 여백
                    SizedBox(height: 20),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

// 더 깔끔하고 모던한 비교 아이템 위젯 (아이콘 박스 크기 축소 및 색상 파라미터 추가)
  Widget _buildModernComparisonItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String previousValue,
    required String currentValue,
    required String changeText,
    required bool isPositive,
    required Color previousColor,
    required Color currentColor,
    required bool showDivider,
    required Color iconBgColor, // 아이콘 배경색 파라미터 추가
  }) {
    final Color positiveColor = Color(0xFF53A487);
    final Color negativeColor = Color(0xFFE57373);
    final Color neutralColor = Color(0xFF9E9E9E);

    Color getChangeColor() {
      if (isPositive) return positiveColor;
      if (!isPositive && changeText != '변화 없음') return negativeColor;
      return neutralColor;
    }

    final changeColor = getChangeColor();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 타이틀과 아이콘 (아이콘 박스 크기 축소)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8), // 패딩 축소
                    decoration: BoxDecoration(
                      color: iconBgColor, // 배경색 파라미터 사용
                      borderRadius: BorderRadius.circular(10), // 모서리 반경 축소
                    ),
                    child: Icon(
                      icon,
                      size: 18, // 아이콘 크기 축소
                      color: iconColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),

                  // 변화량 표시 (우측 정렬)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_downward_rounded
                              : changeText != '변화 없음'
                                  ? Icons.arrow_upward_rounded
                                  : Icons.remove_rounded,
                          size: 14,
                          color: changeColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          changeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // 값 비교 - 깔끔한 레이아웃
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 이전 값
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이전 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: previousColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          previousValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: previousColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 화살표 아이콘
                  Icon(
                    Icons.east_rounded,
                    size: 20,
                    color: Colors.grey[300],
                  ),

                  // 현재 값
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '현재 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          currentValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: currentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 구분선 (마지막 항목이 아닐 경우에만)
        if (showDivider)
          Divider(
            color: Colors.grey[100],
            thickness: 2,
            height: 1,
          ),
      ],
    );
  }

// 나 vs 친구 모드 결과 화면 - 수정된 디자인
  Widget _buildVsFriendResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);
    final modeData = appState.modeData;
    final timeDiff = widget.resultData['timeDiff'];
    final String timeDiffText = timeDiff != null
        ? timeDiff < 0
            ? "${timeDiff.abs()}분 단축"
            : timeDiff > 0
                ? "$timeDiff분 증가"
                : "변화 없음" // timeDiff가 0인 경우
        : "";

    // badge URL 가져오기
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 친구 기록 정보 - 위젯에서 가져오기
    final String friendDate = _formatDate(widget.opponentRecordDate) ?? '기본값';
    final int friendTimeMinutes = widget.opponentRecordTime ?? 0;
    final int friendMaxHeartRate =
        widget.opponentMaxHeartRate ?? widget.resultData['maxHeartRate'] ?? 0;
    final double friendAvgHeartRate = widget.opponentAvgHeartRate ??
        widget.resultData['averageHeartRate'] ??
        0.0;

    // 현재 기록 정보
    final int currTimeSeconds = widget.currentElapsedMinutes ?? 0;
    final now = DateTime.now();
    final String currentDate =
        '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 심박수 차이 계산 및 코멘트 생성
    final int maxHrDiff = (widget.resultData['maxHeartRate'] is double)
        ? (widget.resultData['maxHeartRate'] as double).round() -
            friendMaxHeartRate
        : (widget.resultData['maxHeartRate'] ?? 0) - friendMaxHeartRate;
    final double avgHrDiff = (widget.resultData['averageHeartRate'] is double)
        ? (widget.resultData['averageHeartRate'] as double) - friendAvgHeartRate
        : (widget.resultData['averageHeartRate'] ?? 0.0) - friendAvgHeartRate;

    String maxHrComment = '';
    if (maxHrDiff > 0) {
      maxHrComment = '최고 심박수 ${maxHrDiff}bpm 증가';
    } else if (maxHrDiff < 0) {
      maxHrComment = '최고 심박수 ${maxHrDiff.abs()}bpm 감소';
    } else {
      maxHrComment = '최고 심박수 변화 없음';
    }

    String avgHrComment = '';
    if (avgHrDiff > 0) {
      avgHrComment = '평균 심박수 ${avgHrDiff.toStringAsFixed(1)}bpm 증가';
    } else if (avgHrDiff < 0) {
      avgHrComment = '평균 심박수 ${(avgHrDiff.abs()).toStringAsFixed(1)}bpm 감소';
    } else {
      avgHrComment = '평균 심박수 변화 없음';
    }

    // 색상 정의 - VsMe와 동일한 컬러 스킴이지만 위치 변경
    final Color primaryColor = Color(0xFF53A487);
    final Color friendColor =
        Color(0xFF8E9EAB); // 친구 기록 색상 (청회색) - previousColor와 동일
    final Color myColor =
        Color(0xFF3A8A6E); // 내 기록 색상 (진한 녹색) - currentColor와 동일
    final Color positiveColor = Color(0xFF53A487); // 긍정적 변화 (녹색)
    final Color negativeColor = Color(0xFFE57373); // 부정적 변화 (빨간색)
    final Color neutralColor = Color(0xFF9E9E9E); // 중립적 색상 (회색)
    final Color cardColor = Colors.white;
    final Color bgColor = Color(0xFFF8F9FA);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션 - VsMe와 동일한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.people_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '친구와의 기록 비교',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // 날짜 비교 카드 - VsMe와 동일한 디자인 (위치만 변경)
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 친구 날짜 (왼쪽)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: friendColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          friendDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: friendColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // VS 표시 - VsMe와 동일한 디자인
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // 내 날짜 (오른쪽)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: myColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          currentDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: myColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 통합 비교 카드 - VsMe와 유사한 디자인 (위치만 변경)
            Container(
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 등산 시간 비교
                  _buildComparisonItem(
                    title: '총 등산 시간',
                    icon: Icons.timer_outlined,
                    iconColor: primaryColor,
                    friendValue: _formatMinutes(friendTimeMinutes),
                    myValue: _formatMinutes(currTimeSeconds),
                    changeText: timeDiffText,
                    isPositive: timeDiff != null && timeDiff < 0,
                    friendColor: friendColor,
                    myColor: myColor,
                    showDivider: true,
                    iconBgColor: primaryColor.withOpacity(0.1),
                  ),

                  // 최고 심박수 비교
                  _buildComparisonItem(
                    title: '최고 심박수',
                    icon: Icons.monitor_heart_rounded,
                    iconColor: primaryColor,
                    friendValue: '$friendMaxHeartRate bpm',
                    myValue: '${widget.resultData['maxHeartRate'] ?? 0} bpm',
                    changeText: maxHrDiff > 0
                        ? '${maxHrDiff} bpm 증가'
                        : maxHrDiff < 0
                            ? '${maxHrDiff.abs()} bpm 감소'
                            : '변화 없음',
                    isPositive: maxHrDiff < 0,
                    friendColor: friendColor,
                    myColor: myColor,
                    showDivider: true,
                    iconBgColor: primaryColor.withOpacity(0.1),
                  ),

                  // 평균 심박수 비교
                  _buildComparisonItem(
                    title: '평균 심박수',
                    icon: Icons.favorite_border_rounded,
                    iconColor: primaryColor,
                    friendValue: '${friendAvgHeartRate.round()} bpm',
                    myValue:
                        '${widget.resultData['averageHeartRate'] is double ? (widget.resultData['averageHeartRate'] as double).toInt() : widget.resultData['averageHeartRate'] ?? 0} bpm',
                    changeText: avgHrDiff > 0
                        ? '${avgHrDiff.toStringAsFixed(1)} bpm 증가'
                        : avgHrDiff < 0
                            ? '${avgHrDiff.abs().toStringAsFixed(1)} bpm 감소'
                            : '변화 없음',
                    isPositive: avgHrDiff < 0,
                    friendColor: friendColor,
                    myColor: myColor,
                    showDivider: false,
                    iconBgColor: primaryColor.withOpacity(0.1),
                  ),
                ],
              ),
            ),

            // 뱃지 표시 - VsMe와 동일한 디자인
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 여백 추가하여 전체적으로 아래로 내림
                    SizedBox(height: 30),

                    // 뱃지 이미지 (뱃지 외곽선에서 바로 후광이 나오는 효과)
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 후광 효과 레이어
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  // 바깥쪽 후광 (넓게 퍼지는 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[100]!.withOpacity(0.9),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                  // 중간 후광 (선명한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[200]!.withOpacity(0.8),
                                    blurRadius: 30,
                                    spreadRadius: 12,
                                  ),
                                  // 안쪽 후광 (강한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[300]!.withOpacity(0.7),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                            // 뱃지 이미지
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber[200]!,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: badgeUrl.isNotEmpty
                                    ? Image.network(
                                        badgeUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.amber[50],
                                          child: Icon(
                                            Icons.emoji_events_rounded,
                                            size: 80,
                                            color: Colors.amber[500],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.amber[50],
                                        child: Icon(
                                          Icons.emoji_events_rounded,
                                          size: 80,
                                          color: Colors.amber[500],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 뱃지 아래에 텍스트와 아이콘 추가
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 축하하는 아이콘
                        Icon(
                          Icons.celebration_rounded,
                          color: Colors.amber[400],
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "뱃지를 획득했어요!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // 추가 여백
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// 나 vs 친구용 비교 아이템 위젯 (위치만 변경)
  Widget _buildComparisonItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String friendValue,
    required String myValue,
    required String changeText,
    required bool isPositive,
    required Color friendColor,
    required Color myColor,
    required bool showDivider,
    required Color iconBgColor,
  }) {
    final Color positiveColor = Color(0xFF53A487);
    final Color negativeColor = Color(0xFFE57373);
    final Color neutralColor = Color(0xFF9E9E9E);

    Color getChangeColor() {
      if (isPositive) return positiveColor;
      if (!isPositive && changeText != '변화 없음') return negativeColor;
      return neutralColor;
    }

    final changeColor = getChangeColor();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 타이틀과 아이콘
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),

                  // 변화량 표시 (우측 정렬)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_downward_rounded
                              : changeText != '변화 없음'
                                  ? Icons.arrow_upward_rounded
                                  : Icons.remove_rounded,
                          size: 14,
                          color: changeColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          changeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // 값 비교 - 깔끔한 레이아웃 (위치 변경)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 친구 값 (왼쪽)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '친구 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: friendColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          friendValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: friendColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 화살표 아이콘
                  Icon(
                    Icons.east_rounded,
                    size: 20,
                    color: Colors.grey[300],
                  ),

                  // 내 값 (오른쪽)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '내 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: myColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          myValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: myColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 구분선 (마지막 항목이 아닐 경우에만)
        if (showDivider)
          Divider(
            color: Colors.grey[100],
            thickness: 2,
            height: 1,
          ),
      ],
    );
  }

// 일반 등산 모드 결과 화면 - 색상 일관성 개선 및 간결한 디자인
  Widget _buildGeneralResult(String mountainName) {
    final appState = Provider.of<AppState>(context, listen: false);
    final String badgeUrl = widget.resultData['badge'] ?? '';

    // 현재 날짜 포맷팅
    final now = DateTime.now();
    final String currentDate =
        '${now.year.toString().substring(2)}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 등산 데이터
    final int timeSeconds = appState.elapsedSeconds;
    final String timeFormatted = _formatSeconds(timeSeconds);
    final int maxHeartRate = (widget.resultData['maxHeartRate'] is double)
        ? (widget.resultData['maxHeartRate'] as double).round()
        : widget.resultData['maxHeartRate'] ?? 0;
    final int avgHeartRate = (widget.resultData['averageHeartRate'] is double)
        ? (widget.resultData['averageHeartRate'] as double).round()
        : widget.resultData['averageHeartRate'] ?? 0;
    final int distance = appState.distance;
    logger.d('distance: $distance');
    final String distanceFormatted =
        distance < 1000 ? '${distance}m' : '${distance.toStringAsFixed(1)}km';

    // 색상 정의 - VsMe/VsFriend와 동일한 컬러 스킴
    final Color primaryColor = Color(0xFF53A487);
    final Color textColor = Color(0xFF2D3748); // 일반 텍스트 색상
    final Color valueColor = Color(0xFF3A8A6E); // 값 표시 색상 (진한 녹색)
    final Color cardColor = Colors.white;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션 - VsMe/VsFriend와 동일한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.hiking_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '나의 기록',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // 날짜 카드 - VsMe/VsFriend와 유사한 디자인
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: valueColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    currentDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),

            // 등산 정보 카드 - 통합형 간결한 디자인 (한 줄에 2개씩 항목 배치 + 긴 구분선 추가)
            Container(
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 첫 번째 줄: 거리와 시간
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // 거리 정보
                          Expanded(
                            child: _buildCompactInfoItemHalf(
                              title: '총 산행 거리',
                              icon: Icons.straighten,
                              iconColor: primaryColor,
                              value: distanceFormatted,
                              valueColor: Color(0xFF444444), // 값 텍스트를 회색 계열로 변경
                              iconBgColor: primaryColor.withOpacity(0.1),
                            ),
                          ),

                          // 중앙 수직 구분선
                          VerticalDivider(
                            width: 32,
                            thickness: 1,
                            color: Colors.grey[200],
                          ),

                          // 시간 정보
                          Expanded(
                            child: _buildCompactInfoItemHalf(
                              title: '총 등산 시간',
                              icon: Icons.timer_outlined,
                              iconColor: primaryColor,
                              value: timeFormatted,
                              valueColor: Color(0xFF444444), // 값 텍스트를 회색 계열로 변경
                              iconBgColor: primaryColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 수평 구분선
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[100],
                  ),

                  // 두 번째 줄: 최고 심박수와 평균 심박수
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // 최고 심박수
                          Expanded(
                            child: _buildCompactInfoItemHalf(
                              title: '최고 심박수',
                              icon: Icons.monitor_heart_rounded,
                              iconColor: primaryColor,
                              value: '$maxHeartRate bpm',
                              valueColor: Color(0xFF444444), // 값 텍스트를 회색 계열로 변경
                              iconBgColor: primaryColor.withOpacity(0.1),
                            ),
                          ),

                          // 중앙 수직 구분선
                          VerticalDivider(
                            width: 32,
                            thickness: 1,
                            color: Colors.grey[200],
                          ),

                          // 평균 심박수
                          Expanded(
                            child: _buildCompactInfoItemHalf(
                              title: '평균 심박수',
                              icon: Icons.favorite_border_rounded,
                              iconColor: primaryColor,
                              value: '$avgHeartRate bpm',
                              valueColor: Color(0xFF444444), // 값 텍스트를 회색 계열로 변경
                              iconBgColor: primaryColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 뱃지 표시 - VsMe/VsFriend와 동일한 디자인
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 여백 추가하여 전체적으로 아래로 내림
                    SizedBox(height: 30),

                    // 뱃지 이미지 (뱃지 외곽선에서 바로 후광이 나오는 효과)
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 후광 효과 레이어
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  // 바깥쪽 후광 (넓게 퍼지는 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[100]!.withOpacity(0.9),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                  // 중간 후광 (선명한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[200]!.withOpacity(0.8),
                                    blurRadius: 30,
                                    spreadRadius: 12,
                                  ),
                                  // 안쪽 후광 (강한 빛) - 더 은은하고 밝은 노란색
                                  BoxShadow(
                                    color: Colors.amber[300]!.withOpacity(0.7),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                            // 뱃지 이미지
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber[200]!,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: badgeUrl.isNotEmpty
                                    ? Image.network(
                                        badgeUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.amber[50],
                                          child: Icon(
                                            Icons.emoji_events_rounded,
                                            size: 80,
                                            color: Colors.amber[500],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.amber[50],
                                        child: Icon(
                                          Icons.emoji_events_rounded,
                                          size: 80,
                                          color: Colors.amber[500],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 뱃지 아래에 텍스트와 아이콘 추가
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 축하하는 아이콘
                        Icon(
                          Icons.celebration_rounded,
                          color: Colors.amber[400],
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "뱃지를 획득했어요!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // 추가 여백
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// 일반 등산 모드용 2열 배치를 위한 반쪽 크기 정보 아이템 위젯
  Widget _buildCompactInfoItemHalf({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required Color iconBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘과 타이틀 행
        Row(
          children: [
            // 아이콘 영역
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            SizedBox(width: 10),

            // 타이틀
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // 값 영역 (아이콘 아래에 정렬)
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  // 확인 버튼 개선
  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: () async {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.endTracking();
          _stopBackgroundService();
          _cancelAllNotifications();
          // 홈 화면으로 이동 (currentPageIndex를 0으로 설정하고 루트 경로로 이동)
          appState.changePage(0);
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF52A486),
          minimumSize: Size(double.infinity, 56),
          shadowColor: Color(0xFF52A486).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '완료',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
