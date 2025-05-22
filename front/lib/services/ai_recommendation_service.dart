import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../utils/ai_utils.dart';

class AiRecommendationService {
  Future<Map<String, dynamic>> fetchRecommendation(BuildContext context) async {
    debugPrint('▶ AiRecommendationService.fetchRecommendation: 시작');
    final app = context.read<AppState>();
    final userId = app.userId;
    final token = app.accessToken;
    debugPrint('   userId=$userId, token=${token?.substring(0, 10)}...');

    if (userId == null || token == null) {
      debugPrint('⚠️ 인증 정보 없음');
      throw Exception('로그인 정보가 없습니다.');
    }

    final urlStr = '${dotenv.get('AI_BASE_URL')}/recommend/$userId';
    debugPrint('   요청 URL: $urlStr');
    final resp = await http.post(
      Uri.parse(urlStr),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('⚠️ 요청 타임아웃');
      throw TimeoutException('요청 시간이 초과되었습니다.');
    });
    debugPrint('   HTTP 상태 코드: ${resp.statusCode}');

    if (resp.statusCode != 200) {
      debugPrint('⚠️ 서버 오류: ${resp.statusCode}');
      throw Exception('서버 오류 (${resp.statusCode})');
    }

    final bodyString = utf8.decode(resp.bodyBytes);
    printFullBody(bodyString);

    debugPrint('   compute() 호출 전');
    final data = await compute(parseJson, bodyString);
    debugPrint('   compute() 호출 후, data.keys=${data.keys}');

    if (data['recommendations'] == null || (data['recommendations'] as List).isEmpty) {
      debugPrint('⚠️ 추천 데이터 없음, message=${data['message']}');
      throw Exception(data['message'] ?? '추천된 산이 없습니다.');
    }

    debugPrint('▶ AiRecommendationService.fetchRecommendation: 완료, cluster=${data['cluster']}');
    return data;
  }
}