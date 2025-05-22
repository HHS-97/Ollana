import '../../models/path_detail.dart';
import 'package:intl/intl.dart';

String formatDate(dynamic date) {
  // DateTime 객체인 경우
  if (date is DateTime) {
    return '${date.year % 100}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  } 
  // 문자열인 경우 (예: "2025-05-21")
  else if (date is String) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${int.parse(parts[0]) % 100}/${parts[1].padLeft(2, '0')}/${parts[2].padLeft(2, '0')}';
      }
    } catch (e) {
      // 파싱 실패 시 원본 반환
      print('날짜 포맷 변환 실패: $e');
    }
    return date;
  }
  // 알 수 없는 타입
  return '날짜 정보 없음';
}

String formatDateForApi(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String displayDate(DateTime? date) {
  if (date == null) return '선택';
  return DateFormat('yyyy-MM-dd').format(date);
}

double getMaxValue(PathDetail path) {
  double maxHeartRate = 0;
  double maxTime = 0;

  for (var record in path.records) {
    if (record.maxHeartRate > maxHeartRate) {
      maxHeartRate = record.maxHeartRate.toDouble();
    }
    if (record.time > maxTime) {
      maxTime = record.time.toDouble();
    }
  }

  return maxHeartRate > maxTime ? maxHeartRate : maxTime;
}

String formatGrowthStatus(String status) {
  switch (status) {
    case 'IMPROVING':
      return '기록이 성장했어요!';
    case 'REGRESSING':
      return '기록이 떨어졌어요!';
    case 'STABLE':
      return '기록이 비슷해요!';
    default:
      return status;
  }
}