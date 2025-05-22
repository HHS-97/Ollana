// lib/services/mountain_service.dart
// - 산 및 등산로 데이터 서비스

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';

/// 산 및 등산로 데이터를 묶어 반환하는 모델
class MountainWithRoutes {
  final Mountain mountain;
  final List<HikingRoute> routes;
  final String? location;

  MountainWithRoutes({
    required this.mountain,
    required this.routes,
    required this.location,
  });
}

/// JSON 파싱을 백그라운드로 처리하는 헬퍼 함수 (getNearby용)
Future<MountainWithRoutes> _parseNearby(String body) async {
  final Map<String, dynamic> jsonData = jsonDecode(body);
  if (jsonData['status'] != true || jsonData['data'] == null) {
    throw FormatException('Nearby API: 예상치 못한 응답 구조');
  }
  final data = jsonData['data'] as Map<String, dynamic>;

  // 산 데이터에서 필요한 필드들이 없을 수 있으므로 먼저 기본값으로 채워진 맵 생성
  final Map<String, dynamic> mountainData = {
    'mountainId': 0,
    'mountainName': '',
    'location': '',
    'height': 0.0,
  };

  // 응답에서 받은 실제 데이터로 덮어쓰기
  if (data['mountain'] != null && data['mountain'] is Map<String, dynamic>) {
    mountainData.addAll(data['mountain'] as Map<String, dynamic>);
  }

  final mountain = Mountain.fromJson(mountainData);

  final List paths = data['paths'] as List<dynamic>;

  // 등산로 데이터 변환 시 mountainId 명시적 설정
  final routes = paths.map((e) {
    // 원본 데이터 보존
    final Map<String, dynamic> pathData =
        Map<String, dynamic>.from(e as Map<String, dynamic>);

    // mountainId 명시적 추가
    if (!pathData.containsKey('mountainId') || pathData['mountainId'] == null) {
      pathData['mountainId'] = mountain.id;
      debugPrint('_parseNearby: mountainId(${mountain.id})를 등산로 데이터에 추가');
    }

    return HikingRoute.fromJson(pathData);
  }).toList();

  return MountainWithRoutes(mountain: mountain, routes: routes, location: '');
}

/// JSON 파싱을 백그라운드로 처리하는 헬퍼 함수 (getAll용)
Future<MountainWithRoutes> _parseAll(String body) async {
  final Map<String, dynamic> jsonData = jsonDecode(body);
  if (jsonData['status'] != true || jsonData['data'] == null) {
    throw FormatException('All API: 예상치 못한 응답 구조');
  }
  final data = jsonData['data'] as Map<String, dynamic>;

  // 산 데이터에서 필요한 필드들이 없을 수 있으므로 먼저 기본값으로 채워진 맵 생성
  final Map<String, dynamic> mountainData = {
    'mountainId': 0,
    'mountainName': '',
    'location': '',
    'height': 0.0,
  };

  // 응답에서 받은 실제 데이터로 덮어쓰기
  if (data['mountain'] != null && data['mountain'] is Map<String, dynamic>) {
    mountainData.addAll(data['mountain'] as Map<String, dynamic>);
  }

  final mountain = Mountain.fromJson(mountainData);

  final List paths = data['paths'] as List<dynamic>;

  // 등산로 데이터 변환 시 mountainId 명시적 설정
  final routes = paths.map((e) {
    // 원본 데이터 보존
    final Map<String, dynamic> pathData =
        Map<String, dynamic>.from(e as Map<String, dynamic>);

    // mountainId 명시적 추가
    if (!pathData.containsKey('mountainId') || pathData['mountainId'] == null) {
      pathData['mountainId'] = mountain.id;
      debugPrint('_parseAll: mountainId(${mountain.id})를 등산로 데이터에 추가');
    }

    return HikingRoute.fromJson(pathData);
  }).toList();

  return MountainWithRoutes(
      mountain: mountain, routes: routes, location: mountain.location);
}

class MountainService {
  final String _baseUrl = dotenv.get('BASE_URL');
  final http.Client _client;

  MountainService({http.Client? client}) : _client = client ?? http.Client();

  /// 주변 산 및 등산로 조회
  Future<MountainWithRoutes> getNearbyMountains(
      double latitude, double longitude,
      [String? token]) async {
    final uri = Uri.parse(
        '$_baseUrl/tracking/mountains/nearby?lat=$latitude&lng=$longitude');
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
        return compute(_parseNearby, body);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw Exception('Nearby JSON 오류: $e');
    } catch (e) {
      throw Exception('주변 산 데이터 불러오기 실패: $e');
    }
  }

  /// 전체 산 및 등산로 조회
  Future<MountainWithRoutes> getMountainRoutes([String? token]) async {
    final uri = Uri.parse('$_baseUrl/tracking/mountains');
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
        return compute(_parseAll, body);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw Exception('All JSON 오류: $e');
    } catch (e) {
      throw Exception('산 및 등산로 데이터 불러오기 실패: $e');
    }
  }

  /// 산 이름으로 검색 (토큰을 인자로 받도록 수정된 부분)
  Future<List<Mountain>> searchMountains(String query, String token) async {
    // 시그니처에 token 추가
    if (query.isEmpty) {
      return [];
    }

    final uri = Uri.parse('$_baseUrl/tracking/search?mtn=$query');
    debugPrint('[searchMountains] URI: $uri');
    debugPrint('[searchMountains] Token: $token');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // 헤더에 토큰 사용
        },
      );

      debugPrint('★ [searchMountains] Status: ${response.statusCode}'); // ★
      debugPrint('★ [searchMountains] Body: ${response.body}'); // ★

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body);
        debugPrint('jsonData: $jsonData');

        if (jsonData['status'] == true && jsonData['data'] != null) {
          // 데이터 형식 체크
          if (jsonData['data'] is List) {
            // 리스트 형태일 경우
            final List<dynamic> data = jsonData['data'] as List<dynamic>;
            return data.map((item) => Mountain.fromJson(item)).toList();
          } else if (jsonData['data'] is Map) {
            // 맵 형태일 경우, 맵의 값들을 리스트로 변환
            final Map<String, dynamic> data =
                jsonData['data'] as Map<String, dynamic>;

            // 'mountains' 키가 있는 경우 (응답 구조에 맞춤)
            if (data.containsKey('mountains') && data['mountains'] is List) {
              final List<dynamic> mountains =
                  data['mountains'] as List<dynamic>;

              // mountainId, mountainName, mountainHeight, mountainLoc 필드를 적절히 매핑
              return mountains
                  .map((item) => Mountain(
                        id: item['mountainId'],
                        name: item['mountainName'] ?? '',
                        height:
                            (item['mountainHeight'] as num?)?.toDouble() ?? 0.0,
                        location: item['mountainLoc'] ?? '',
                      ))
                  .toList();
            }
            // 결과가 하나만 있거나 배열이 아닌 객체 형태로 온 경우
            else if (data.containsKey('mountain')) {
              final mountainData = data['mountain'];
              if (mountainData != null) {
                return [Mountain.fromJson(mountainData)];
              }
            }

            // 다른 형태의 맵 처리
            try {
              // 맵의 각 값을 개별 산으로 처리
              List<Mountain> mountains = [];
              data.forEach((key, value) {
                if (value is Map<String, dynamic>) {
                  try {
                    mountains.add(Mountain.fromJson(value));
                  } catch (e) {
                    debugPrint('산 객체 변환 오류: $e');
                  }
                }
              });
              return mountains;
            } catch (e) {
              debugPrint('맵 처리 오류: $e');
              return [];
            }
            // 기타 Map 처리 생략...
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('[searchMountains] Exception: $e');
      return [];
    }
  }

  /// Client 자원 정리
  void dispose() {
    _client.close();
  }

  /// 선택한 산의 상세 정보 및 등산로 조회 (기존 로직 유지)
  Future<MountainWithRoutes> getMountainByName(String mountainName,
      [String? token]) async {
    if (mountainName.isEmpty) {
      throw Exception('산 이름이 비어있습니다');
    }

    final uri =
        Uri.parse('$_baseUrl/tracking/search/results?mtn=$mountainName');
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

        // API 응답 구조 디버깅 (직접 파싱)
        final jsonData = jsonDecode(body);
        debugPrint('API 응답 구조: ${jsonData.runtimeType}');
        debugPrint('API 응답 내용: $jsonData');

        if (jsonData == null) {
          throw FormatException('API 응답이 null입니다');
        }

        if (jsonData['status'] != true) {
          throw FormatException('API 상태가 true가 아닙니다: ${jsonData['status']}');
        }

        if (jsonData['data'] == null) {
          throw FormatException('API 데이터가 null입니다');
        }

        // 데이터 구조 검사
        final data = jsonData['data']['results'][0];
        debugPrint('data 내용: $data');

        // if (data is! Map<String, dynamic>) {
        //   throw FormatException('data가 Map 형식이 아닙니다: ${data.runtimeType}');
        // }

        // Mountain 객체 생성
        Mountain mountain;
        if (data['mountain'] == null) {
          debugPrint('mountain 데이터가 null입니다');
          mountain = Mountain(
            id: 0, // 임시 ID
            name: mountainName,
            location: '',
            height: 0.0,
          );
        } else {
          try {
            mountain = Mountain.fromJson(data['mountain']);
          } catch (e) {
            debugPrint('Mountain 객체 생성 오류: $e');
            mountain = Mountain(
              id: 0, // 임시 ID
              name: mountainName,
              location: '',
              height: 0.0,
            );
          }
        }

        // 등산로 정보 처리
        List<HikingRoute> routes = [];
        if (data['paths'] != null && data['paths'] is List) {
          try {
            final pathsList = data['paths'] as List;
            for (var pathData in pathsList) {
              if (pathData != null && pathData is Map<String, dynamic>) {
                try {
                  final route = HikingRoute.fromJson(pathData);
                  routes.add(route);
                } catch (routeError) {
                  debugPrint('등산로 변환 오류: $routeError');
                }
              } else {
                debugPrint('등산로 데이터가 null이거나 Map이 아닙니다: $pathData');
              }
            }
          } catch (pathError) {
            debugPrint('등산로 목록 처리 오류: $pathError');
          }
        } else {
          debugPrint('paths 데이터가 null이거나 List가 아닙니다: ${data['paths']}');
        }

        return MountainWithRoutes(
            mountain: mountain, routes: routes, location: mountain.location);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      debugPrint('Nearby JSON 오류: $e');
      // 오류 발생 시 기본 객체 반환
      return MountainWithRoutes(
        mountain: Mountain(
          id: 0, // 임시 ID
          name: mountainName,
          location: '',
          height: 0.0,
        ),
        routes: [],
        location: '',
      );
    } catch (e) {
      debugPrint('주변 산 데이터 불러오기 실패: $e');
      // 오류 발생 시 기본 객체 반환
      return MountainWithRoutes(
        mountain: Mountain(
          id: 0, // 임시 ID
          name: mountainName,
          location: '',
          height: 0.0,
        ),
        routes: [],
        location: '',
      );
    }
  }

  /// 산 ID로 상세 정보 및 등산로 조회
  Future<MountainWithRoutes> getMountainById(num mountainId,
      [String? token]) async {
    final uri = Uri.parse('$_baseUrl/tracking/search/mountain/$mountainId');
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
        debugPrint('API 응답 구조: ${jsonData.runtimeType}');

        if (jsonData == null) {
          throw FormatException('API 응답이 null입니다');
        }

        if (jsonData['status'] != true) {
          throw FormatException('API 상태가 true가 아닙니다: ${jsonData['status']}');
        }

        if (jsonData['data'] == null) {
          throw FormatException('API 데이터가 null입니다');
        }

        // 새로운 응답 구조에 맞게 파싱
        final data = jsonData['data'];
        debugPrint('data 내용: $data');

        // Mountain 객체 생성
        Mountain mountain;
        if (data['mountain'] == null) {
          debugPrint('mountain 데이터가 null입니다');
          mountain = Mountain(
            id: mountainId, // mountainId를 그대로 사용
            name: '알 수 없는 산',
            location: '',
            height: 0.0,
          );
        } else {
          try {
            // 새 데이터 구조에 맞게 Mountain 객체 생성
            final mountainData = data['mountain'];
            mountain = Mountain(
              id: mountainData['mountainId'] ??
                  mountainId, // API에서 제공하지 않으면 파라미터 값 사용
              name: mountainData['mountainName'] ?? '',
              location: mountainData['location'] ?? '',
              height: 0.0, // API에서 height가 제공되지 않는 경우
            );
          } catch (e) {
            debugPrint('Mountain 객체 생성 오류: $e');
            mountain = Mountain(
              id: mountainId, // mountainId를 그대로 사용
              name: '알 수 없는 산',
              location: '',
              height: 0.0,
            );
          }
        }

        // 등산로 정보 처리
        List<HikingRoute> routes = [];
        if (data['paths'] != null && data['paths'] is List) {
          try {
            final pathsList = data['paths'] as List;
            for (var pathData in pathsList) {
              if (pathData != null && pathData is Map<String, dynamic>) {
                try {
                  // 새 데이터 구조에 맞게 HikingRoute 객체 생성
                  final List<Map<String, double>> pathCoordinates = [];

                  if (pathData['route'] != null && pathData['route'] is List) {
                    for (var point in pathData['route']) {
                      if (point is Map<String, dynamic>) {
                        pathCoordinates.add({
                          'latitude': (point['latitude'] as num).toDouble(),
                          'longitude': (point['longitude'] as num).toDouble(),
                        });
                      }
                    }
                  }

                  // mountainId 디버그 출력
                  debugPrint(
                      '등산로 생성 - 산 ID: ${mountain.id}, 산 이름: ${mountain.name}');

                  // 등산로 내의 mountainId 설정
                  final routeMountainId = pathData['mountainId'] ?? mountain.id;

                  final route = HikingRoute(
                    id: pathData['pathId'] ?? 0,
                    mountainId:
                        routeMountainId, // API에서 제공하지 않으면 mountain 객체의 ID 사용
                    name: pathData['pathName'] ?? '',
                    distance:
                        ((pathData['pathLength'] as num?)?.toDouble() ?? 0.0)
                            .toInt(),
                    estimatedTime:
                        int.tryParse(pathData['pathTime'] ?? '0') ?? 0,
                    difficulty: '중', // API에서 난이도가 제공되지 않는 경우 기본값
                    path: pathCoordinates,
                  );

                  // 생성된 등산로 객체 정보 출력
                  debugPrint(
                      '등산로 생성 완료 - ${route.name}, mountainId: ${route.mountainId}, pathId: ${route.id}');

                  routes.add(route);
                } catch (routeError) {
                  debugPrint('등산로 변환 오류: $routeError');
                }
              } else {
                debugPrint('등산로 데이터가 null이거나 Map이 아닙니다: $pathData');
              }
            }
          } catch (pathError) {
            debugPrint('등산로 목록 처리 오류: $pathError');
          }
        } else {
          debugPrint('paths 데이터가 null이거나 List가 아닙니다: ${data['paths']}');
        }

        return MountainWithRoutes(
            mountain: mountain, routes: routes, location: mountain.location);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('클라이언트 오류 ${response.statusCode}');
      } else {
        throw Exception('서버 오류 ${response.statusCode}');
      }
    } on FormatException catch (e) {
      debugPrint('JSON 파싱 오류: $e');
      // 오류 발생 시 기본 객체 반환
      return MountainWithRoutes(
        mountain: Mountain(
          id: mountainId, // mountainId를 그대로 사용
          name: '알 수 없는 산',
          location: '',
          height: 0.0,
        ),
        routes: [],
        location: '',
      );
    } catch (e) {
      debugPrint('산 데이터 불러오기 실패: $e');
      // 오류 발생 시 기본 객체 반환
      return MountainWithRoutes(
        mountain: Mountain(
          id: mountainId, // mountainId를 그대로 사용
          name: '알 수 없는 산',
          location: '',
          height: 0.0,
        ),
        routes: [],
        location: '',
      );
    }
  }
}
