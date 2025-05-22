import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/me_vs_me.dart';
import '../models/friend.dart';
import '../models/mode_data.dart';

class ModeService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  ModeService({http.Client? client}) : _client = client ?? http.Client();

  /// 이전 등산 기록 목록 조회
  Future<List<Map<String, dynamic>>> getMyTrackingOptions({
    required int mountainId,
    required int pathId,
    required String token,
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/tracking/options?mountainId=$mountainId&pathId=$pathId');

    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        debugPrint('등산 기록 목록 응답: ${jsonData['status']}');

        if (jsonData['status'] == true &&
            jsonData['data'] != null &&
            jsonData['data']['records'] != null) {
          final List<dynamic> records =
              jsonData['data']['records'] as List<dynamic>;
          return records.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      debugPrint('등산 기록 목록 없음: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('등산 기록 목록 조회 오류: $e');
      return [];
    }
  }

  /// 등산 시작 요청
  Future<ModeData> startTracking({
    required int mountainId,
    required int pathId,
    required String mode,
    int? opponentId,
    int? recordId,
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/tracking/start');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'mountainId': mountainId,
        'pathId': pathId,
        'mode': mode,
        'opponentId': opponentId,
        'recordId': recordId,
        'latitude': latitude,
        'longitude': longitude,
      });

      debugPrint(
          '등산 시작 요청 데이터: mountainId=$mountainId, pathId=$pathId, mode=$mode, recordId=$recordId');

      // Request 객체를 생성하여 GET 요청 with body 구현
      final request = http.Request('GET', uri);
      request.headers.addAll(headers);
      request.body = body;

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      // 응답 본문이 비어있는지 확인
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('응답 본문 길이: ${decodedBody.length}');

      if (decodedBody.isEmpty) {
        throw Exception('서버 응답이 비어 있습니다. 상태 코드: ${response.statusCode}');
      }

      // JSON 파싱 전에 유효한 JSON인지 확인
      try {
        final jsonData = jsonDecode(decodedBody);
        debugPrint('등산 시작 응답: ${response.statusCode}, ${jsonData['status']}');
        debugPrint('등산 시작 데이터: ${jsonData['data']}');

        if (response.statusCode == 200 && jsonData['status'] == true) {
          // data 필드에서 ModeData 객체 생성
          if (jsonData['data'] == null) {
            throw Exception('응답에 data 필드가 없습니다');
          }
          return ModeData.fromJson(jsonData['data']);
        } else {
          final errorMessage = jsonData['message'] ?? '등산 시작 요청 실패';
          throw Exception('$errorMessage (${response.statusCode})');
        }
      } catch (jsonError) {
        debugPrint('JSON 파싱 오류: $jsonError');
        debugPrint('잘못된 응답 본문: $decodedBody');
        throw Exception('서버 응답을 파싱할 수 없습니다: $jsonError');
      }
    } catch (e) {
      debugPrint('등산 시작 요청 오류: $e');
      throw Exception('등산 시작 요청 중 오류 발생: $e');
    }
  }

  /// 나 vs 나 모드를 위한 이전 기록 조회
  Future<MeVsMe?> getMeVsMeRecord(num mountainId, num pathId,
      [String? token]) async {
    final uri =
        Uri.parse('$_baseUrl/tracking/me/mountain/$mountainId/path/$pathId');

    try {
      final headers = {
        'Accept': 'application/json',
      };

      // 토큰이 있으면 인증 헤더 추가
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        return MeVsMe.fromJson(jsonData['data']);
      } else {
        debugPrint('MeVsMe API 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('MeVsMe 기록 조회 오류: $e');
      return null;
    }
  }

  /// 친구 모드에서 친구 검색
  Future<List<Friend>> searchFriends(String query, String token,
      {required num mountainId, required num pathId}) async {
    final uri = Uri.parse(
        '$_baseUrl/tracking/friends?mountainId=$mountainId&pathId=$pathId&nickname=$query');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        debugPrint('친구 검색 응답: $jsonData');

        if (jsonData['status'] == true && jsonData['data'] != null) {
          // users 배열을 처리
          if (jsonData['data'] is Map && jsonData['data']['users'] is List) {
            final List<dynamic> users =
                jsonData['data']['users'] as List<dynamic>;
            return users
                .map((item) => Friend.fromJson({
                      'id': item['userId'],
                      'nickname': item['nickname'],
                      'isPossible': item['isPossible'],
                      'profileImg': item['profileImg'],
                    }))
                .toList();
          }
        }
      }

      debugPrint('친구 검색 결과 없음: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('친구 검색 오류: $e');
      return [];
    }
  }

  /// 등산 종료 요청
  Future<Map<String, dynamic>> endTracking({
    required int mountainId,
    required int pathId,
    required String mode,
    int? opponentId,
    int? recordId,
    required bool isSave,
    required double finalLatitude,
    required double finalLongitude,
    required int finalTime,
    required int finalDistance,
    required List<Map<String, dynamic>> records,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/tracking/finish');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'mountainId': mountainId,
        'pathId': pathId,
        'mode': mode,
        'opponentId': opponentId,
        'recordId': recordId,
        'isSave': isSave,
        'finalLatitude': finalLatitude,
        'finalLongitude': finalLongitude,
        'finalTime': finalTime,
        'finalDistance': finalDistance,
        'records': records,
      });

      debugPrint(
          '등산 종료 요청 데이터: mountainId=$mountainId, pathId=$pathId, mode=$mode');
      debugPrint('등산 종료 요청 데이터: $body');

      final response = await _client.post(
        uri,
        headers: headers,
        body: body,
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(decodedBody);

      debugPrint('등산 종료 응답: ${response.statusCode}, ${jsonData['status']}');

      if (response.statusCode == 200) {
        return jsonData;
      } else {
        final errorMessage = jsonData['message'] ?? '등산 종료 요청 실패';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('등산 종료 요청 오류: $e');
      throw Exception('등산 종료 요청 중 오류 발생: $e');
    }
  }

  /// 사용자의 현재 트래킹 상태 확인
  Future<ModeData?> checkActiveTracking(String token) async {
    final uri = Uri.parse('$_baseUrl/tracking/status');

    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(uri, headers: headers);

      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(decodedBody);

      debugPrint('트래킹 상태 확인 응답: ${response.statusCode}, ${jsonData['status']}');

      if (response.statusCode == 200 && jsonData['status'] == true) {
        // 활성화된 트래킹이 있는 경우
        if (jsonData['data'] != null &&
            jsonData['data']['isTracking'] == true) {
          debugPrint('활성화된 트래킹 발견');
          return ModeData.fromJson(jsonData['data']);
        } else {
          debugPrint('활성화된 트래킹 없음');
          return null;
        }
      } else {
        debugPrint('트래킹 상태 확인 실패: ${jsonData['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('트래킹 상태 확인 오류: $e');
      return null;
    }
  }

  /// 친구의 이전 등산 기록 목록 조회
  Future<List<Map<String, dynamic>>> getFriendTrackingOptions({
    required int mountainId,
    required int pathId,
    required int opponentId,
    required String token,
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/tracking/options?mountainId=$mountainId&pathId=$pathId&opponentId=$opponentId');

    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);

        debugPrint('친구 등산 기록 목록 응답: ${jsonData['status']}');

        if (jsonData['status'] == true &&
            jsonData['data'] != null &&
            jsonData['data']['records'] != null) {
          final List<dynamic> records =
              jsonData['data']['records'] as List<dynamic>;
          return records.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      debugPrint('친구 등산 기록 목록 없음: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('친구 등산 기록 목록 조회 오류: $e');
      return [];
    }
  }

  /// Client 자원 정리
  void dispose() {
    _client.close();
  }
}
