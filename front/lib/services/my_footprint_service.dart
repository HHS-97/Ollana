import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/footprint_response.dart';
import '../models/footprint_detail_response.dart';
import '../models/path_detail.dart';
import '../models/compare_response.dart';
import '../models/battle_result.dart';
import '../utils/footprint_utils.dart';

class MyFootprintService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  MyFootprintService({http.Client? client}) : _client = client ?? http.Client();

  Future<FootprintResponse> getFootprints(String token, {int page = 0}) async {
    final uri = Uri.parse('$_baseUrl/footprint?page=$page');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    debugPrint('uri = $uri');
    debugPrint('headers = $headers');

    final res = await _client.get(uri, headers: headers);
    debugPrint('발자취 API 응답 코드: ${res.statusCode}');
    debugPrint('발자취 API 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(res.bodyBytes));
      return FootprintResponse.fromJson(jsonData);
    } else {
      throw Exception("발자취 API 호출 실패: ${res.statusCode}");
    }
  }

  Future<FootprintDetailResponse> getFootprintDetail(String token, int footprintId, {int page = 0}) async {
    final uri = Uri.parse('$_baseUrl/footprint/$footprintId?page=$page');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final res = await _client.get(uri, headers: headers);
    debugPrint('상세 API 응답 코드: ${res.statusCode}');
    debugPrint('상세 API 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(res.bodyBytes));
      return FootprintDetailResponse.fromJson(jsonData);
    } else {
      throw Exception('상세 발자취 조회 실패: ${res.statusCode}');
    }
  }

  Future<PathDetail> getFootprintPathDetail(
    String token,
    int footprintId,
    int pathId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final query = <String, String>{};
    if (start != null) query['start'] = formatDateForApi(start);
    if (end != null) query['end'] = formatDateForApi(end);
    final uri = Uri.parse('$_baseUrl/footprint/$footprintId/path/$pathId').replace(queryParameters: query);

    debugPrint('Calling API: $uri');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('API Response Status: ${response.statusCode}');
    debugPrint('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint('Parsed JSON: $jsonData');
      if (jsonData['data'] == null) {
        throw Exception('API response does not contain "data" field');
      }
      return PathDetail.fromJson(jsonData['data'], pathId: pathId);
    } else {
      throw Exception('Failed to load path detail: ${response.statusCode}');
    }
  }

  Future<CompareResponse> getCompareData(String token, int footprintId, Set<int> recordIds) async {
    final recordIdsQuery = recordIds.map((id) => 'recordIds=$id').join('&');
    final uri = Uri.parse('$_baseUrl/footprint/$footprintId/compare?$recordIdsQuery');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    debugPrint('비교 API 호출 URI: $uri');
    final res = await _client.get(uri, headers: headers);
    debugPrint('비교 API 응답 코드: ${res.statusCode}');
    debugPrint('비교 API 응답 본문: ${res.body}');

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(res.bodyBytes));
      debugPrint('비교 API 응답 데이터: ${jsonData.toString()}');
      return CompareResponse.fromJson(jsonData);
    } else {
      throw Exception('비교 데이터 로드 실패: ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getBattleResults(String token, {int page = 0}) async {
    final uri = Uri.parse('$_baseUrl/footprint/battle?page=$page');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    debugPrint('대결 결과 API 호출 URI: $uri');
    final res = await _client.get(uri, headers: headers);
    debugPrint('대결 결과 API 응답 코드: ${res.statusCode}');
    debugPrint('대결 결과 API 응답 본문: ${res.body}');

    final decoded = utf8.decode(res.bodyBytes);
    final jsonData = jsonDecode(decoded);

    if (res.statusCode == 200) {
      return {
        'battleResults': (jsonData['data']['list'] as List).map((e) => BattleResult.fromJson(e)).toList(),
        'isLast': jsonData['data']['last'] as bool,
        'totalElements': jsonData['data']['totalElements'] as int,
      };
    } else {
      throw Exception('대결 결과 API 호출 실패: ${res.statusCode}');
    }
  }
}