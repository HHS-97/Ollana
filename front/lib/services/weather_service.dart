import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/weather_data.dart';

class WeatherService {
  static const String CACHE_KEY_DATA = 'weather_data';
  static const String CACHE_KEY_DATE = 'weather_date';

  static Future<List<WeatherData>> fetchWeatherData(String? token, {bool forceRefresh = false}) async {
  // token이 null인 경우 빈 리스트 반환
  if (token == null) {
    return [];
  }

  // 현재 날짜와 시간 확인
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final currentHour = now.hour;
  
  // SharedPreferences 인스턴스 가져오기
  final prefs = await SharedPreferences.getInstance();
  
  // 밤 9시(21시)부터 자정 직전까지는 API가 빈 배열 반환하므로 특별 처리
  final isApiUnavailableTime = currentHour >= 21 && currentHour <= 23;
  
  // 강제 새로고침이 아닌 경우에만 캐시 확인
  if (!forceRefresh) {
    final cachedDataStr = prefs.getString(CACHE_KEY_DATA);
    final cachedDateStr = prefs.getString(CACHE_KEY_DATE);
    
    // 캐시된 데이터가 있고, 날짜가 오늘과 같은지 확인
    if (cachedDataStr != null && cachedDateStr == today) {
      debugPrint('오늘 날짜의 캐시된 데이터 사용');
      try {
        // 캐시된 데이터 파싱
        final decodedData = json.decode(cachedDataStr);
        List<WeatherData> weatherDataList = [];
        
        // Map인 경우와 List인 경우 모두 처리
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('today_weather')) {
          final weatherList = decodedData['today_weather'] as List<dynamic>;
          weatherDataList = weatherList
              .map((data) => WeatherData.fromJson(data))
              .toList();
        } else if (decodedData is List<dynamic>) {
          weatherDataList = decodedData
              .map((data) => WeatherData.fromJson(data))
              .toList();
        }
        
        // 데이터가 있으면 반환
        if (weatherDataList.isNotEmpty) {
          return weatherDataList;
        }
      } catch (e) {
        debugPrint('캐시된 데이터 파싱 오류: $e');
      }
    }
  } else {
    debugPrint('강제 새로고침 요청으로 캐시 무시');
  }
  
  // API 응답이 빈 배열을 반환하는 시간대인 경우, 캐시된 데이터 검사
  if (isApiUnavailableTime) {
    debugPrint('API 비가용 시간대 (21시~23시): 캐시된 데이터 사용');
    final cachedDataStr = prefs.getString(CACHE_KEY_DATA);
    final cachedDateStr = prefs.getString(CACHE_KEY_DATE);
    
    if (cachedDataStr != null && cachedDateStr == today) {
      try {
        final decodedData = json.decode(cachedDataStr);
        List<WeatherData> weatherDataList = [];
        
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('today_weather')) {
          final weatherList = decodedData['today_weather'] as List<dynamic>;
          weatherDataList = weatherList
              .map((data) => WeatherData.fromJson(data))
              .toList();
        } else if (decodedData is List<dynamic>) {
          weatherDataList = decodedData
              .map((data) => WeatherData.fromJson(data))
              .toList();
        }
        
        return weatherDataList;
      } catch (e) {
        debugPrint('캐시된 데이터 파싱 오류: $e');
      }
    }
    
    // 21시 이후에 오늘 캐시된 데이터가 없으면 빈 배열 반환
    debugPrint('21시 이후 캐시된 데이터 없음: 빈 배열 반환');
    return [];
  }
  
  // API 호출 (캐시된 데이터가 없거나, 강제 새로고침인 경우)
  debugPrint('API 호출: 새로운 데이터 가져오기');
  final baseUrl = dotenv.env['AI_BASE_URL']!;
  final url = Uri.parse('$baseUrl/weather');
  
  try {
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final decodedResponse = utf8.decode(resp.bodyBytes);
      final data = json.decode(decodedResponse);
      
      if (!data.containsKey('today_weather') || data['today_weather'] == null) {
        debugPrint('API 응답에 today_weather 키가 없거나 null입니다.');
        return [];
      }
      
      final weatherList = data['today_weather'] as List<dynamic>;
      debugPrint('등산지수 조회 결과: ${weatherList.length}개 시간대');
      
      // 날씨 데이터 파싱
      List<WeatherData> weatherDataList = weatherList
          .map((item) => WeatherData.fromJson(item))
          .toList();
      
      // 디코딩된 데이터 캐싱
      await prefs.setString(CACHE_KEY_DATA, decodedResponse); 
      await prefs.setString(CACHE_KEY_DATE, today);
      
      return weatherDataList;
    }
    
    // 오류 발생 시 빈 리스트 반환
    debugPrint('API 오류: ${resp.statusCode}');
    return [];
  } catch (e) {
    debugPrint('날씨 데이터 가져오기 오류: $e');
    return [];
  }
}

  // 다음날로 변경 시 새벽 0시에 데이터 캐싱을 위한 메서드
  static Future<bool> checkAndUpdateIfNeeded(String? token) async {
    if (token == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final cachedDateStr = prefs.getString(CACHE_KEY_DATE);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    
    // 캐시된 날짜가 없거나 오늘과 다르면 업데이트
    if (cachedDateStr == null || cachedDateStr != today) {
      debugPrint('날짜가 변경되어 데이터 업데이트: $cachedDateStr -> $today');
      
      try {
        // 현재 시간이 21시 이후인지 확인
        final currentHour = now.hour;
        if (currentHour >= 21) {
          debugPrint('21시 이후이므로 캐시 날짜만 업데이트');
          // 날짜만 업데이트 (21시 이후에는 API가 데이터를 반환하지 않음)
          await prefs.setString(CACHE_KEY_DATE, today);
          return false;
        }
        
        // API 호출 및 캐싱
        await fetchWeatherData(token, forceRefresh: true);
        return true;
      } catch (e) {
        debugPrint('날짜 변경 데이터 업데이트 오류: $e');
        return false;
      }
    }
    
    return false;
  }

  // 필터링 함수 제거 (불필요)
  
  // 캐시 삭제 함수
  static Future<void> clearCache() async {
    debugPrint('캐시 삭제');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CACHE_KEY_DATA);
    await prefs.remove(CACHE_KEY_DATE);
  }

  // 캐싱된 데이터 확인 함수 (디버깅용)
  static Future<void> checkCachedData() async {
    // SharedPreferences 인스턴스 가져오기
    final prefs = await SharedPreferences.getInstance();
    
    // 캐시된 데이터와 날짜 가져오기
    final cachedDataStr = prefs.getString(CACHE_KEY_DATA);
    final cachedDateStr = prefs.getString(CACHE_KEY_DATE);
    
    if (cachedDataStr != null && cachedDateStr != null) {
      try {
        // 캐시된 데이터 파싱 - JSON 구조 확인
        final decodedData = json.decode(cachedDataStr);
        List<WeatherData> weatherDataList = [];
        
        // Map인 경우와 List인 경우 모두 처리
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('today_weather')) {
          // Map에서 today_weather 키의 리스트 추출
          final weatherList = decodedData['today_weather'] as List<dynamic>;
          weatherDataList = weatherList
              .map((data) => WeatherData.fromJson(data))
              .toList();
        } else if (decodedData is List<dynamic>) {
          // 직접 리스트인 경우
          weatherDataList = decodedData
              .map((data) => WeatherData.fromJson(data))
              .toList();
        } else {
          debugPrint('캐시된 데이터 형식이 예상과 다릅니다: ${decodedData.runtimeType}');
        }
        
        // 디버그 출력 - 세부 데이터 포함 (필터링 없음)
        debugPrint('캐시된 날짜: $cachedDateStr');
        debugPrint('캐시된 데이터:');
        for (var data in weatherDataList) {
          debugPrint('  시간: ${data.getFormattedTime()}');
          debugPrint('  등산지수: ${data.score}');
          debugPrint('  세부정보: ${data.details}');
        }
      } catch (e) {
        debugPrint('캐시된 데이터 파싱 오류: $e');
      }
    } else {
      debugPrint('캐시된 데이터가 없습니다.');
    }
  }
  
  // 자정에 데이터 가져오기 (골든타임)
  static Future<void> fetchMidnightData(String? token) async {
    if (token == null) return;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // 자정 직후 시간인지 확인 (0시~2시)
    if (hour >= 0 && hour < 3) {
      debugPrint('자정 직후 시간에 데이터 가져오기 시도');
      await fetchWeatherData(token, forceRefresh: true);
    }
  }
}