package com.ssafy.ollana.security.jwt;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SignatureException;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;

// 토큰 생성, 검증, 파싱
@Slf4j
@Component
@Getter
public class JwtUtil {

    private final Key key;
    private final long accessTokenExpiration;
    private final long refreshTokenExpiration;
    private final long passwordResetTokenExpiration;

    public JwtUtil(@Value("${spring.jwt.secret}") String secretKey,
                   @Value("${spring.jwt.access.expiration}") long accessTokenExpiration,
                   @Value("${spring.jwt.refresh.expiration}") long refreshTokenExpiration,
                   @Value("${spring.jwt.password-reset.expiration}") long passwordResetTokenExpiration) {

        this.key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8)); // 시크릿 키를 Key 객체로 변환
        this.accessTokenExpiration = accessTokenExpiration;
        this.refreshTokenExpiration = refreshTokenExpiration;
        this.passwordResetTokenExpiration = passwordResetTokenExpiration;
    }

    // access token 생성
    public String createAccessToken(String userEmail, int userId) {
        return createAccessToken(userEmail, userId, accessTokenExpiration);
    }

    // refresh token 생성
    public String createRefreshToken(String userEmail, int userId) {
        return createAccessToken(userEmail, userId, refreshTokenExpiration);
    }

    // token 생성 공통 메서드
    private String createAccessToken(String userEmail, int userId, long tokenExpiration) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + tokenExpiration);

        return Jwts.builder()
                .setSubject(userEmail)                         // 사용자 식별자값
                .claim("userId", userId)
                .setIssuedAt(now)                              // 발급일
                .setExpiration(expiration)                     // 만료 시간
                .signWith(key, SignatureAlgorithm.HS256)       // 암호화 알고리즘
                .compact();
    }

    // 토큰 유효성 검사
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.info("Expired JWT token, 만료된 JWT 토큰입니다.");
        } catch (SecurityException | MalformedJwtException | SignatureException e) {
            log.error("Invalid JWT signature, 유효하지 않는 JWT 서명 입니다.");
        } catch (UnsupportedJwtException e) {
            log.error("Unsupported JWT token, 지원되지 않는 JWT 토큰 입니다.");
        } catch (IllegalArgumentException e) {
            log.error("JWT claims is empty, 잘못된 JWT 토큰 입니다.");
        }
        return false;
    }

    // 토큰 만료 여부 확인
    public boolean isTokenExpired(String token) {
        try {
            return getClaims(token).getExpiration().before(new Date());
        } catch (ExpiredJwtException e) {
            return true;
        }
    }

    // 토큰 남은 시간 계산
    public long getTokenRemainingTime(String token) {
        Claims claims = getClaims(token);
        Date expiration = claims.getExpiration();
        return expiration.getTime() - System.currentTimeMillis();
    }

    // 클레임 추출
    public Claims getClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    // 토큰에서 사용자 이메일 가져오기
    public String getUserEmailFromToken(String token) {
        return getClaims(token).getSubject();
    }

    // 토큰에서 userId 가져오기
    public int getUserIdFromToken(String token) {
        Claims claims = getClaims(token);
        return claims.get("userId", Integer.class);
    }
}
