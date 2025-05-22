// mountain_map_service.dart: 산 지도 정보를 가져오는 서비스
// - 서버에서 산 지도 정보 가져오기
// - 로컬 저장소에 데이터 저장 및 불러오기

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mountain_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class MountainMapService {
  final String _baseUrl = dotenv.get('BASE_URL');
  static const String _cachedMountainsKey = 'cached_mountains';

  // 서버에서 산 지도 정보 가져오기
  Future<List<MountainMap>> fetchMountainsFromApi(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mountain/map'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // UTF-8로 명시적 디코딩
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(decodedBody);

        if (responseData['status'] == true) {
          final List<dynamic> data = responseData['data'];
          final mountains =
              data.map((json) => MountainMap.fromJson(json)).toList();

          // 데이터를 로컬에 저장
          await _saveMountainsToLocal(mountains);

          return mountains;
        } else {
          throw Exception('API 요청 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API 요청 중 오류 발생: $e');
      throw Exception('API 요청 중 오류 발생: $e');
    }
  }

  // 로컬에서 산 지도 정보 가져오기
  Future<List<MountainMap>> getMountains(String token) async {
    final prefs = await SharedPreferences.getInstance();

    // 로컬에 저장된 데이터가 있는지 확인
    if (prefs.containsKey(_cachedMountainsKey)) {
      final String cachedData = prefs.getString(_cachedMountainsKey) ?? '[]';
      final List<dynamic> jsonData = json.decode(cachedData);
      return jsonData.map((json) => MountainMap.fromJson(json)).toList();
    } else {
      // 로컬에 데이터가 없으면 API에서 가져오기
      return await fetchMountainsFromApi(token);
    }
  }

  // 로컬에 산 지도 정보 저장
  Future<void> _saveMountainsToLocal(List<MountainMap> mountains) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData =
        json.encode(mountains.map((m) => m.toJson()).toList());
    await prefs.setString(_cachedMountainsKey, jsonData);
  }

  // 로컬 데이터 클리어 (필요시 사용)
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedMountainsKey);
  }
}
