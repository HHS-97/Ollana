import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:jwt_decode/jwt_decode.dart';

class KakaoAuthService {
  String _getKakaoAuthUrl() {
    final clientId = dotenv.env['KAKAO_CLIENT_ID'] ?? '';
    final redirectUri = dotenv.env['KAKAO_REDIRECT_URI'];
    final authUrl =
        'https://kauth.kakao.com/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&lang=ko';

    debugPrint('🔗 [KakaoAuth] URL: $authUrl');
    return authUrl;
  }


  Future<void> loginWithKakao(BuildContext context) async {
    try {
      final authUrl = _getKakaoAuthUrl();
      final uri = Uri.parse(authUrl);
      debugPrint('[KakaoAuth] URL 열기 시도: $uri');

      final canLaunch = await canLaunchUrl(uri);
      debugPrint('[KakaoAuth] canLaunchUrl: $canLaunch');

      if (canLaunch) {
        debugPrint('[KakaoAuth] URL 열기 가능');
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 외부 브라우저에서 실행
        );
        debugPrint('[KakaoAuth] URL 열림');
      } else {
        debugPrint('[KakaoAuth] URL 열기 불가능');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('브라우저를 열 수 없습니다. 기본 브라우저가 설치되어 있는지 확인하세요.'),
          ),
        );
        throw '카카오 인증 URL을 열 수 없습니다.';
      }
    } catch (e, stackTrace) {
      debugPrint('[KakaoAuth] 오류: $e');
      debugPrint('[KakaoAuth] 스택 트레이스: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 중 오류가 발생했습니다: $e')),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeKakaoRegistration({
    required String email,
    required String nickname,
    required String profileImage,
    required String birth,
    required String gender,
    required bool isSocial,
    required String tempToken,
    required int kakaoId,
  }) async {
    try {
      final baseUrl = dotenv.get('BASE_URL');
      final uri = Uri.parse('$baseUrl/auth/oauth/kakao/complete');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'nickname': nickname,
          'profileImage': profileImage,
          'birth': birth,
          'gender': gender,
          'isSocial': isSocial,
          'tempToken': tempToken,
          'kakaoId': kakaoId,
        }),
      );

      final bodyString = utf8.decode(response.bodyBytes);
      final data = jsonDecode(bodyString);

      if (response.statusCode == 200 && data['status'] == true) {
        final accessToken = data['data']['accessToken'];
        final profileImageUrl = data['data']['user']['profileImageUrl'];
        final nickname = data['data']['user']['nickname'];
        final social = data['data']['user']['social'] as bool;
        final payload = Jwt.parseJwt(accessToken);
        final userId = payload['userId']?.toString() ?? '';
        final exp = payload['exp'] as int;
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

        return {
          'success': true,
          'accessToken': accessToken,
          'userId': userId,
          'profileImageUrl': profileImageUrl,
          'nickname': nickname,
          'social': social,
          'expiry': expiry,
        };
      } else {
        throw Exception(data['message'] ?? '회원가입을 완료할 수 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ [KakaoAuthService] completeKakaoRegistration 오류: $e');
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }
}