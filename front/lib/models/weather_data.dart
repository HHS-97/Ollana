// models/weather_data.dart 수정
import 'package:intl/intl.dart';

class WeatherData {
  final String time;
  final double score;
  final Map<String, String> details;

  WeatherData({
    required this.time,
    required this.score,
    required this.details,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    Map<String, String> details = {};
    json.forEach((key, value) {
      if (key != 'time' && key != 'score') {
        details[key] = value.toString();
      }
    });

    return WeatherData(
      time: json['time'],
      score: json['score']?.toDouble() ?? 0.0,
      details: details,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'time': time,
      'score': score,
    };
    json.addAll(details);
    return json;
  }

  // 시간 형식 변환 (2025-05-19 18:00 -> 18:00)
  // 항상 두 자리 형식으로 표시되도록 수정
  String getFormattedTime() {
    try {
      final dateTime = DateFormat('yyyy-MM-dd HH:mm').parse(time);
      return DateFormat('HH:mm').format(dateTime); // 항상 두 자리로 표시됨
    } catch (e) {
      // 파싱 오류 시 원본 시간에서 시간 부분만 추출
      final timeParts = time.split(' ');
      if (timeParts.length > 1) {
        final hourMin = timeParts[1].split(':');
        if (hourMin.length > 1) {
          // 시간과 분을 두 자리 숫자로 포맷팅
          final hour = hourMin[0].padLeft(2, '0');
          final minute = hourMin[1].padLeft(2, '0');
          return '$hour:$minute';
        }
      }
      return time; // 파싱 불가능한 경우 원본 반환
    }
  }

  // 날짜만 추출 (2025-05-19 18:00 -> 2025-05-19)
  String getFormattedDate() {
    try {
      final dateTime = DateFormat('yyyy-MM-dd HH:mm').parse(time);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      // 파싱 오류 시 원본 날짜에서 날짜 부분만 추출
      final dateParts = time.split(' ');
      if (dateParts.isNotEmpty) {
        return dateParts[0];
      }
      return time; // 파싱 불가능한 경우 원본 반환
    }
  }

  // 날짜와 시간 객체로 변환
  DateTime getDateTime() {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parse(time);
    } catch (e) {
      // 파싱 오류 시 현재 시간 반환
      return DateTime.now();
    }
  }

  // 현재 또는 미래 시간인지 확인
  bool isFutureOrCurrent() {
    final now = DateTime.now();
    final dataTime = getDateTime();
    return dataTime.isAfter(now) || isSameHour(dataTime, now);
  }

  // 같은 시간대인지 확인 (시, 분 비교)
  bool isSameHour(DateTime a, DateTime b) {
    return a.year == b.year && 
           a.month == b.month && 
           a.day == b.day && 
           a.hour == b.hour;
  }
}