import 'dart:convert';
import 'package:flutter/foundation.dart';

void printFullBody(String body) {
  const int chunkSize = 800;
  for (var i = 0; i < body.length; i += chunkSize) {
    final end = (i + chunkSize < body.length) ? i + chunkSize : body.length;
    debugPrint(body.substring(i, end));
  }
}

Map<String, dynamic> parseJson(String body) {
  debugPrint('🔧 [parseJson] isolate 파싱 시작');
  final result = jsonDecode(body);
  debugPrint('🔧 [parseJson] isolate 파싱 완료');
  return result;
}

// String? formatImageUrl(String? rawImg) {
//   if (rawImg == null || rawImg.isEmpty) return null;
//   return (rawImg.startsWith('http://') || rawImg.startsWith('https://')) 
//       ? rawImg.replaceFirst('https://', 'http://') // HTTPS를 HTTP로 변경
//       : 'http://$rawImg';  // HTTPS 대신 HTTP 사용
// }

String? formatImageUrl(String? rawImg) {
  if (rawImg == null || rawImg.isEmpty) return null;
  
  // URL에 프로토콜이 있는지 확인
  if (rawImg.startsWith('http://') || rawImg.startsWith('https://')) {
    return rawImg; // 원본 URL 그대로 반환
  } else {
    // 프로토콜이 없는 경우 https:// 추가
    return 'https://$rawImg';
  }
}

class ImageUtils {
  // 특정 도메인 이미지인지 확인
  static bool isRestrictedDomain(String? url) {
    if (url == null || url.isEmpty) return false;
    
    return url.contains('devin.aks.ac.kr') || 
           url.contains('devin.aks.ac');
  }
  
  // 이미지 URL 포맷팅 및 필터링 (제한된 도메인 이미지는 null 반환)
  static String? getProcessedImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    
    // 제한된 도메인인 경우 null 반환
    if (isRestrictedDomain(rawUrl)) {
      print("제한된 도메인 감지 ($rawUrl): 기본 이미지 사용");
      return null;
    }
    
    // URL 포맷팅
    final String? formattedUrl = formatImageUrl(rawUrl);
    if (formattedUrl != null) {
      print("이미지 URL 처리: $rawUrl -> $formattedUrl");
    }
    return formattedUrl;
  }
}