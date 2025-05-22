import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decode/jwt_decode.dart'; 
import 'package:provider/provider.dart'; 
import '../models/app_state.dart';
import '../screens/home_screen.dart';
import '../screens/user/additional_info_screen.dart';
import '../../screens/user/password_change_screen.dart';
import '../main.dart'; 

class DeepLinkHandler {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> startListening() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      debugPrint('초기 링크 (String): $initialLink');

      if (initialLink != null) {
        debugPrint('초기 URI: $initialLink');
        _handleUri(initialLink);
      }
    } catch (e) {
      debugPrint('초기 딥링크 처리 실패: $e');
    }

    // 실시간 URI 스트림 처리
    _sub = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('실시간 URI 수신: $uri');
      _handleUri(uri);
    }, onError: (err) {
      debugPrint('딥링크 스트림 오류: $err');
    });
  }

  Future<void> _handleUri(Uri uri) async {
    final status = uri.queryParameters['status'];
    final tempToken = uri.queryParameters['temp_token'];
    final loginToken = uri.queryParameters['login_token'];
    debugPrint('temp_token = $tempToken');
    debugPrint('login_token = $loginToken');

    // navigatorKey.currentState가 준비될 때까지 대기
    await Future.delayed(Duration.zero, () async {
      if (navigatorKey.currentState == null) {
        debugPrint('navigatorKey.currentState가 null입니다. 나중에 다시 시도합니다.');
        return;
      }

      final baseUrl = dotenv.get('BASE_URL');

      if (status == 'login' && loginToken != null) {
        debugPrint('login_token = $loginToken');
        debugPrint('딥링크 status=login, loginToken=$loginToken → 로그인 API 호출');

        final apiUri = Uri.parse('$baseUrl/auth/oauth/kakao/login?token=$loginToken');
        
        try {
          final res = await http.get(apiUri);
          final body = utf8.decode(res.bodyBytes);
          debugPrint('API 응답: $body');
          final data = jsonDecode(body);

          if (res.statusCode == 200 && data['status'] == true) {
            // 데이터 추출
            final accessToken = data['data']['accessToken'];
            final profileImageUrl = data['data']['user']['profileImageUrl'];
            final nickname = data['data']['user']['nickname'];
            final social = data['data']['user']['social'] as bool;
            final payload = Jwt.parseJwt(accessToken);
            final userId = payload['userId']?.toString() ?? '';
            final exp = payload['exp'] as int;
            final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            final user = data['data']['user'];
            final isTemp = (user['tempPassword'] as bool?) ?? false;

            // AppState에 데이터 저장
            await navigatorKey.currentState!.context.read<AppState>().setToken(
                  accessToken,
                  userId: userId,
                  profileImageUrl: profileImageUrl,
                  nickname: nickname,
                  social: social,
                );

            // tempPassword 처리
            if (isTemp) {
              final shouldChange = await showDialog<bool>(
                context: navigatorKey.currentState!.context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('임시 비밀번호 안내'),
                  content: const Text('현재 임시비밀번호 발급을 받으셨습니다.\n'
                      '비밀번호 변경 페이지로 이동하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );

              if (shouldChange == true) {
                navigatorKey.currentState!.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PasswordChangeScreen(
                      accessToken: accessToken,
                    ),
                  ),
                );
                return;
              }
            }

            // 정상 로그인 시 HomeScreen으로 이동
            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => HomeScreen(),
              ),
              (route) => false,
            );
          } else {
            debugPrint('로그인 실패: $body');
          }
        } catch (e, stackTrace) {
          debugPrint('로그인 API 호출 오류: $e');
          debugPrint('스택 트레이스: $stackTrace');
        }
      } else if (status == 'signup' && tempToken != null) {
        debugPrint('딥링크 status=signup → tempToken=$tempToken');

        final apiUri = Uri.parse('$baseUrl/auth/oauth/kakao/temp-user?token=$tempToken');

        try {
          final res = await http.get(apiUri);
          final body = utf8.decode(res.bodyBytes);
          debugPrint('API 응답: $body');
          final data = jsonDecode(body);
          final tempdata = data['data'];
          debugPrint('temp data : $tempdata');

          if (res.statusCode == 200 && data['status'] == true) {
            final tempUser = data['data'];
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => AdditionalInfoScreen(
                  email: tempUser['email'],
                  nickname: tempUser['nickname'],
                  profileImage: tempUser['profileImage'],
                  isSocial: tempUser['isSocial'],
                  kakaoId: tempUser['kakaoId'],
                  tempToken: tempToken,
                ),
              ),
            );
          } else {
            debugPrint('임시 유저 정보 불러오기 실패: $body');
          }
        } catch (e, stackTrace) {
          debugPrint('API 호출 오류: $e');
          debugPrint('스택 트레이스: $stackTrace');
        }
      } else {
        debugPrint('처리할 수 없는 딥링크 URI: $uri');
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}