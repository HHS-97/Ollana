import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/weather_data.dart';
import '../../services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:intl/intl.dart';


class FirstStatusInfo extends StatefulWidget {
  const FirstStatusInfo({super.key});
  @override
  State<FirstStatusInfo> createState() => _FirstStatusInfoState();
}

class _FirstStatusInfoState extends State<FirstStatusInfo> with WidgetsBindingObserver {
  late Future<List<WeatherData>> _weatherDataFuture;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 단일 초기화 함수만 호출
    _initializeData();
    _setupMidnightTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  
// 자정 타이머 설정
  void _setupMidnightTimer() {
    // 현재 시간
    final now = DateTime.now();
    
    // 다음 자정 계산
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);
    
    debugPrint('다음 자정까지 남은 시간: ${duration.inHours}시간 ${duration.inMinutes % 60}분');
    
    _midnightTimer = Timer(duration, () {
      debugPrint('자정이 되어 데이터 새로고침');
      _refreshData(forceRefresh: true);
      
      // 다음 자정 타이머 설정
      _setupMidnightTimer();
    });
  }
  
  // 앱 라이프사이클 관리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때 날짜 확인
      _checkDateAndRefresh();
    }
  }
  
  // 날짜 변경 확인 및 새로고침
  Future<void> _checkDateAndRefresh() async {
    final token = Provider.of<AppState>(context, listen: false).accessToken;
    final dateChanged = await WeatherService.checkAndUpdateIfNeeded(token);
    
    if (dateChanged) {
      setState(() {
        _weatherDataFuture = _loadWeatherData();
      });
    }
  }

  // 날씨 데이터 로드
  Future<List<WeatherData>> _loadWeatherData() async {
    try {
      final token = Provider.of<AppState>(context, listen: false).accessToken;
      return await WeatherService.fetchWeatherData(token);
    } catch (e) {
      debugPrint('데이터 로드 오류: $e');
      return []; // 오류 시 빈 리스트 반환
    }
  }

  // 초기 데이터 로드 - 자정 직후 한 번만 새로고침
Future<void> _initializeData() async {
  final token = Provider.of<AppState>(context, listen: false).accessToken;
  
  // 현재 시간 확인
  final now = DateTime.now();
  final hour = now.hour;
  debugPrint('현재 시간: ${now.toString()}, hour: $hour');
  
  // 자정 직후 시간대 확인
  final isPostMidnight = hour >= 0 && hour < 3;
  
  setState(() {
    _weatherDataFuture = Future(() async {
      try {
        if (isPostMidnight) {
          // 자정 직후에는 이미 갱신했는지 확인
          final prefs = await SharedPreferences.getInstance();
          final lastMidnightRefresh = prefs.getString('last_midnight_refresh');
          final today = DateFormat('yyyy-MM-dd').format(now);
          
          // 오늘 자정에 아직 갱신하지 않았다면
          if (lastMidnightRefresh != today) {
            debugPrint('자정 직후 첫 방문: 강제 새로고침');
            
            // 자정 갱신 기록 저장
            await prefs.setString('last_midnight_refresh', today);
            
            // 강제 새로고침으로 데이터 가져오기
            final weatherData = await WeatherService.fetchWeatherData(token, forceRefresh: true);
            await WeatherService.checkCachedData();
            return weatherData;
          } else {
            // 이미 오늘 자정에 갱신했다면 캐시 사용
            debugPrint('자정 직후 재방문: 이미 갱신했으므로 캐시 사용');
            final weatherData = await WeatherService.fetchWeatherData(token, forceRefresh: false);
            return weatherData;
          }
        } else {
          // 일반 시간대는 기존과 동일
          debugPrint('일반 시간대: 캐시 우선 사용');
          
          final dateChanged = await WeatherService.checkAndUpdateIfNeeded(token);
          
          if (dateChanged) {
            debugPrint('날짜 변경됨: 새 데이터 가져오기');
            return await WeatherService.fetchWeatherData(token, forceRefresh: true);
          } else {
            debugPrint('기존 날짜: 캐시된 데이터 사용');
            final weatherData = await WeatherService.fetchWeatherData(token, forceRefresh: false);
            await WeatherService.checkCachedData();
            return weatherData;
          }
        }
      } catch (e) {
        debugPrint('초기화 오류: $e');
        return <WeatherData>[];
      }
    });
  });
}
  
  // 데이터 새로고침 (UI에서 사용)
  Future<void> _refreshData({bool forceRefresh = false}) async {
    try {
      final token = Provider.of<AppState>(context, listen: false).accessToken;
      
      if (mounted) {
        setState(() {
          _weatherDataFuture = WeatherService.fetchWeatherData(token, forceRefresh: forceRefresh);
        });
      }
    } catch (e) {
      debugPrint('새로고침 오류: $e');
    }
  }

  // 모달창으로 날씨 정보 표시 (확인 버튼 제거 및 상단 닫기 버튼 추가)
void _showWeatherModal(BuildContext context, WeatherData data) {
  final score = data.score.round();
  final scoreColor = score < 50
      ? const Color(0xFFE53935)
      : score < 80
          ? const Color(0xFFFF9800)
          : const Color(0xFF52A486);
          
  // AppState에 선택된 등산지수 업데이트
  final appState = Provider.of<AppState>(context, listen: false);
  appState.updateClimbingIndex(score);
  
  // 시간 자연스럽게 변환 (06:00 -> 6시)
  final hour = int.parse(data.time.substring(11, 13));
  final timeText = '$hour시';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 모달 헤더 및 닫기 버튼 추가
          Stack(
            children: [
              // 정보 배지 스타일
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF52A486),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data.getFormattedTime(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Container(
                          height: 16,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.grey[300],
                        ),
                        const Text(
                          "등산지수",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 오른쪽 위 닫기 버튼 추가
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          
          const Divider(
            height: 30,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
          
          // 등산지수 표시 - 침범 문제 해결
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 원형 프로그레스 (침범 문제 해결)
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 외부 원형 배경
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                    ),
                    // 프로그레스 표시기
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // 중앙 흰색 원 (텍스트 배경)
                    Container(
                      width: 65,
                      height: 65,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // 점수 및 등산지수 텍스트
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '등산지수',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 날씨 상태 설명
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 첫 번째 줄: X시의 등산지수는 XX점!
                      Text(
                        '$timeText의 등산지수는 ${score}점!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // 두 번째 줄: 기존 메시지
                      Text(
                        _getScoreMessage(score),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // 날씨 세부정보 제목 - 가운데 정렬
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 20, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECF8F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '날씨 상세정보',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52A486),
                ),
              ),
            ),
          ),
          
          // 세부 정보를 ListView로 변경하여 스크롤 가능하도록 함
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: (data.details.length / 2).ceil(),
              itemBuilder: (context, rowIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // 첫 번째 항목
                      if (rowIndex * 2 < data.details.length)
                        _buildDetailItem(data.details.entries.elementAt(rowIndex * 2)),
                      
                      const SizedBox(width: 8),
                      
                      // 두 번째 항목 (있는 경우)
                      if (rowIndex * 2 + 1 < data.details.length)
                        _buildDetailItem(data.details.entries.elementAt(rowIndex * 2 + 1))
                      else
                        Expanded(child: Container()),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // 하단 여백 추가 (확인 버튼 제거)
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
  
  // 세부 정보 항목 위젯 (재사용을 위해 분리)
  Widget _buildDetailItem(MapEntry<String, String> entry) {
    final key = entry.key;
    final value = entry.value;
    final formattedValue = _formatDetailValue(value);
    final category = _getDetailCategory(value);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF64B792).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getIconForWeatherDetail(key),
                size: 14,
                color: const Color(0xFF64B792),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    key,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          formattedValue,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(category),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 시간표 부분의 오버플로우 에러 수정

@override
Widget build(BuildContext context) {
  return FutureBuilder<List<WeatherData>>(
    future: _weatherDataFuture,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B792)),
            ),
          ),
        );
      }
      
      // 에러 발생 시 메시지 표시
      if (snap.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red[400],
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                '날씨 정보를 불러오지 못했습니다',
                style: TextStyle(
                  color: Colors.red[400], 
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B792),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('새로고침', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        );
      }
      
      // 데이터가 없는 경우 (API 호출 실패 또는 21시~자정 사이) 메시지 표시
      if (!snap.hasData || snap.data!.isEmpty) {
        // 현재 시간이 21시~자정 사이인지 확인
        final now = DateTime.now();
        final currentHour = now.hour;
        final isNightTime = currentHour >= 21 && currentHour <= 23;
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 심플한 헤더 유지
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEFE2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 12,
                        color: const Color(0xFF52A486),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '등산지수 시간표',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF52A486),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 시간대에 따른 메시지 표시
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(
                        isNightTime ? Icons.nightlight_round : Icons.error_outline,
                        color: isNightTime ? const Color(0xFF78909C) : Colors.amber,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isNightTime 
                            ? '아직 시간표가 나올 시간이 아니에요' 
                            : '등산지수 정보를 불러오지 못했습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: isNightTime ? const Color(0xFF78909C) : Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isNightTime) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64B792),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('새로고침'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final weatherDataList = snap.data!;
      
      // 시간 목록과 제목 표시 (오버플로우 수정)
      return 
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 심플한 헤더
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEFE2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 12,
                      color: const Color(0xFF52A486),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '등산지수 시간표',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF52A486),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 지나간 시간에 취소선 추가
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: weatherDataList.length,
                  itemBuilder: (context, index) {
                    final data = weatherDataList[index];
                    final hour = data.time.substring(11, 13);
                    final minute = data.time.substring(14, 16);
                    final formattedTime = '$hour:$minute';
                    
                    // 현재 시간 가져오기
                    final now = DateTime.now();
                    
                    // 날씨 데이터의 시간만 추출하여 간단하게 비교
                    int weatherHour = 0;
                    int weatherMinute = 0;
                    
                    try {
                      weatherHour = int.parse(hour);
                      weatherMinute = int.parse(minute);
                    } catch (e) {
                      print("시간 파싱 오류: $e");
                    }
                    
                    // 날짜는 무시하고 시간만 비교
                    final currentHour = now.hour;
                    final currentMinute = now.minute;
                    
                    // 단순하게 시간만 비교 (같은 날짜라고 가정)
                    final isPastTime = (weatherHour < currentHour) || 
                                      (weatherHour == currentHour && weatherMinute < currentMinute);
                    
                    return InkWell(
                      onTap: () => _showWeatherModal(context, data),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isPastTime 
                              ? const Color(0xFFF5F5F5) // 지나간 시간은 회색 배경
                              : const Color(0xFFF5F9F7), // 미래 시간은 연한 민트 배경
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isPastTime 
                                ? const Color(0xFFE0E0E0) // 지나간 시간은 회색 테두리
                                : const Color(0xFFE0EDE7), // 미래 시간은 연한 민트 테두리
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: isPastTime 
                                  ? const Color(0xFF9E9E9E) // 지나간 시간은 회색 텍스트
                                  : const Color(0xFF407A6B), // 미래 시간은 민트 텍스트
                              decoration: isPastTime 
                                  ? TextDecoration.lineThrough // 지나간 시간에 취소선 추가
                                  : TextDecoration.none,
                              decorationColor: const Color(0xFF9E9E9E), // 취소선 색상
                              decorationThickness: 1.5, // 취소선 두께
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  
  // 점수에 따른 메시지 반환
  String _getScoreMessage(int score) {
    if (score < 50) return '최악의 등산 날씨예요';
    if (score < 80) return '무난한 등산 날씨예요';
    return '최고의 등산 날씨예요';
  }
  
  // 세부정보 값 포맷팅 (괄호 내용 제거)
  String _formatDetailValue(String value) {
    final regex = RegExp(r'(.*?)\s*\([^)]*\)');
    final match = regex.firstMatch(value);
    return match != null ? match.group(1)! : value;
  }
  
  // 세부정보 카테고리 추출 (괄호 안의 내용)
  String _getDetailCategory(String value) {
    final regex = RegExp(r'\(([^)]*)\)');
    final match = regex.firstMatch(value);
    return match != null ? match.group(1)! : '';
  }
  
  // 날씨 세부정보 항목에 맞는 아이콘 반환
  IconData _getIconForWeatherDetail(String key) {
    switch (key) {
      case '체감온도':
        return Icons.thermostat_outlined;
      case '풍속':
        return Icons.air_outlined;
      case '습도':
        return Icons.water_drop_outlined;
      case '구름':
        return Icons.cloud_outlined;
      case '미세먼지':
        return Icons.air;
      case '초미세먼지':
        return Icons.air;
      default:
        return Icons.info_outline;
    }
  }
  
  // 카테고리에 따른 색상 반환
  Color _getCategoryColor(String category) {
    switch (category.trim()) {
      case '좋음':
        return Colors.green;
      case '보통':
        return Colors.blue;
      case '나쁨':
        return Colors.orange;
      case '매우나쁨':
        return Colors.red;
      case '많음':
        return Colors.blueGrey;
      case '적음':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }
}

// SecondStatusInfo 클래스는 변경 불필요
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 두 번째 페이지: 등산 기록 (스타일 통일 및 아이콘 변경)
class SecondStatusInfo extends StatefulWidget {
  const SecondStatusInfo({super.key});
  @override
  State<SecondStatusInfo> createState() => _SecondStatusInfoState();
}

class _SecondStatusInfoState extends State<SecondStatusInfo> {
  late Future<Map<String, dynamic>?> _growthFuture;

  @override
  void initState() {
    super.initState();
    _growthFuture = fetchGrowth();
  }

  Future<Map<String, dynamic>?> fetchGrowth() async {
    final baseUrl = dotenv.env['BASE_URL']!;
    final url = Uri.parse('$baseUrl/footprint/main');
    final token = Provider.of<AppState>(context, listen: false).accessToken;

    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(utf8.decode(resp.bodyBytes));
      return body['status'] == true
          ? body['data']['growth'] as Map<String, dynamic>?
          : throw Exception(body['message']);
    }
    throw Exception('성장 정보 조회 실패 (HTTP ${resp.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _growthFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B792)),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  '성장 정보를 불러올 수 없습니다',
                  style: TextStyle(
                    color: Colors.red[400], 
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final growth = snap.data;
        
        // 케이스 3: 등산 기록이 없는 경우 (growth가 null)
        if (growth == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52A486).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.landscape_outlined,
                    size: 36,
                    color: Color(0xFF52A486),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '등산 기록이 없어요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // 등산 기록이 있는 경우 (케이스 1, 2)
        return _buildClimbingRecord(growth);
      },
    );
  }

  // 등산 기록이 있는 경우의 UI (케이스 1, 2) - 스타일 통일 및 아이콘 변경
  Widget _buildClimbingRecord(Map<String, dynamic> growth) {
    final hasPast = growth['pastTime'] != null;
    final name = growth['mountainName'] as String;
    final date = growth['date'] as String;
    final recent = growth['recentTime'] as int;
    final past = hasPast ? growth['pastTime'] as int : 0;
    
    // 시간 차이 계산 (hasPast인 경우만)
    final bool hasTimeDiff = hasPast && (recent != past);
    final int timeDiff = hasTimeDiff ? (past - recent).abs() : 0;
    final bool isImproved = hasTimeDiff && (recent < past);
    
    // 날짜와 시간 텍스트 스타일 
    final textStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey[800],
    );
    
    return SizedBox(
      height: 130,
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 산 이름
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.terrain,
                      size: 16,
                      color: Color(0xFF52A486),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52A486),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 날짜 
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined, 
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: textStyle, // 공통 스타일 적용
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 시간 정보 
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_outlined, 
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    
                    // 케이스에 따른 시간 표시 
                    if (hasPast) ...[
                      // pastTime이 있는 경우
                      Text(
                        '$past분',
                        style: textStyle, 
                      ),
                      const SizedBox(width: 4),
                      
                      // 화살표
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey[400], 
                      ),
                      const SizedBox(width: 4),
                      
                      // 현재 시간
                      Text(
                        '$recent분',
                        style: textStyle, 
                      ),
                    ] else ...[
                      // pastTime이 null인 경우 (현재 시간만 표시)
                      Text(
                        '$recent분',
                        style: textStyle, 
                      ),
                    ],
                  ],
                ),

                // 첫 등산 메시지 또는 시간 차이 표시 
                if (hasPast && hasTimeDiff) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 22), 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isImproved 
                              ? const Color(0xFFE8F5E9) // 연한 초록 배경
                              : const Color(0xFFFFEBEE), // 연한 빨강 배경
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isImproved ? '${timeDiff}분 단축되었어요!' : '${timeDiff}분 증가했어요!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isImproved 
                                ? const Color(0xFF4CAF50) 
                                : const Color(0xFFE57373),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (!hasPast) ...[
                  // pastTime이 null인 경우 첫 등산 메시지
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 22), 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // 연한 초록 배경
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '이 코스는 첫 등산이네요!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
