// lib/utils/jwt_utils.dart

import 'package:jwt_decode/jwt_decode.dart';

class JwtUtils {
  /// JWT 토큰에서 userId(claim)만 꺼내서 int로 반환합니다.
  /// 없거나 파싱에 실패하면 null을 반환해요.
  static int? extractUserId(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      final dynamic idClaim = payload['userId'];
      if (idClaim == null) return null;
      if (idClaim is int) return idClaim;
      // String으로 넘어올 수도 있으니 안전하게 파싱
      return int.tryParse(idClaim.toString());
    } catch (e) {
      // 토큰이 잘못됐거나 디코딩 에러
      return null;
    }
  }
}
