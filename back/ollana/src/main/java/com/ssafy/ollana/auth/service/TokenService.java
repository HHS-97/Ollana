package com.ssafy.ollana.auth.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.ollana.auth.dto.TempUserDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.exception.KakaoTokenNotFoundException;
import com.ssafy.ollana.auth.exception.KakaoResponseSaveException;
import com.ssafy.ollana.security.jwt.JwtUtil;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenService {

    private final RedisTemplate<String, String> redisTemplate;
    private final JwtUtil jwtUtil;
    private final ObjectMapper objectMapper;

    // redis
    // redis에 리프레시 토큰 저장
    public void saveRefreshToken(String userEmail, String refreshToken) {
        String key = "RT:" + userEmail; // 키 형식: "RT:{userEmail}"
        long expiration = jwtUtil.getRefreshTokenExpiration() / 1000; // redis는 초 단위로 만료 시간 설정
        redisTemplate.opsForValue().set(key, refreshToken, expiration, TimeUnit.SECONDS);

        int userId = jwtUtil.getUserIdFromToken(refreshToken);
        log.info("Refresh token saved: userId={}", userId);
    }

    // user의 리프레시 토큰 조회
    public String getRefreshToken(String userEmail) {
        String key = "RT:" + userEmail;
        String token = redisTemplate.opsForValue().get(key);
        return token;
    }

    // 로그아웃 시 user의 리프레시 토큰 삭제
    public void deleteRefreshToken(String userEmail) {
        String key = "RT:" + userEmail;
        redisTemplate.delete(key);
    }

    // 리프레시 토큰이 redis에 저장된 토큰과 일치하는지 검사
    public boolean validateRefreshToken(String userEmail, String refreshToken) {
        String storedToken = getRefreshToken(userEmail);
        boolean isValid = storedToken != null && storedToken.equals(refreshToken);

        if (!isValid) {
            int userId = jwtUtil.getUserIdFromToken(refreshToken);
            log.info("Refresh token validation failed: userId={}", userId);
        }

        return isValid;
    }

    // 카카오 임시 사용자 정보 관련
    // 카카오 딥링크 리다이렉트용 임시 사용자 정보 저장
    public void saveTempUser(String token, TempUserDto tempUser) {
        String key = "TU:" + token;
        try {
            // TempUserDto 객체를 json 문자열로 변환
            String tempUserResponse = objectMapper.writeValueAsString(tempUser);

            // 변환된 json 문자열을 redis에 저장 (10분동안 유효)
            redisTemplate.opsForValue().set(key, tempUserResponse, 10, TimeUnit.MINUTES);
        } catch (JsonProcessingException e) {
            throw new KakaoResponseSaveException("임시 사용자 정보");
        }
    }

    // 임시 사용자 정보 조회
    public TempUserDto getTempUserByToken(String token) {
        String key = "TU:" + token;
        String tempUserResponse = redisTemplate.opsForValue().get(key);

        if (tempUserResponse == null) {
            throw new KakaoTokenNotFoundException("temp user token");
        }

        try {
            return objectMapper.readValue(tempUserResponse, TempUserDto.class);
        } catch (JsonProcessingException e) {
            throw new KakaoTokenNotFoundException("temp user token");
        }
    }

    // 임시 사용자 정보 삭제
    public void deleteTempUserByToken(String token) {
        String key = "TU:" + token;
        redisTemplate.delete(key);
    }

    // 카카오 딥링크 리다이렉트용 - 로그인 응답
    public void saveKakaoLoginResponse(String token, LoginResponseDto loginResponse) {
        String key = "LS:" + token;

        try {
            // LoginResponseDto 객체를 json 문자열로 변환
            String loginResponseJson = objectMapper.writeValueAsString(loginResponse);

            redisTemplate.opsForValue().set(key, loginResponseJson, 10, TimeUnit.MINUTES);
        } catch (JsonProcessingException e) {
            throw new KakaoResponseSaveException("로그인 응답");
        }
    }

    // 로그인 응답 조회
    public LoginResponseDto getKakaoLoginResponse(String token) {
        String key = "LS:" + token;

        try {
            String loginResponseJson = redisTemplate.opsForValue().get(key);

            if (loginResponseJson == null) {
                throw new KakaoTokenNotFoundException("kakao login token");
            }

            redisTemplate.delete(key);

            LoginResponseDto loginResponse = objectMapper.readValue(loginResponseJson, LoginResponseDto.class);
            return loginResponse;
        } catch (JsonProcessingException e) {
            throw new KakaoTokenNotFoundException("kakao login token");
        }
    }

    // 리프레시 토큰 로테이션
    // 분산 락 획득
    public boolean acquireRefreshLock(String userEmail) {
        String lockKey = "RT-LOCK:" + userEmail;
        // 30초 동안 유효한 락 설정 (데드락 방지)
        return Boolean.TRUE.equals(
                redisTemplate.opsForValue().setIfAbsent(lockKey, "locked", 30, TimeUnit.SECONDS));
    }

    // 락 해제
    public void releaseRefreshLock(String userEmail) {
        String lockKey = "RT-LOCK:" + userEmail;
        redisTemplate.delete(lockKey);
    }


    // 토큰 블랙리스트 관리
    // redis 블랙리스트에 추가
    public void blacklistToken(String token, String reason) {
        long remainingTime = jwtUtil.getTokenRemainingTime(token);

        if (remainingTime > 0) {
            String key = "BL: " + token;

            // 남은 유효시간 만큼 저장
            redisTemplate.opsForValue().set(key, reason, remainingTime, TimeUnit.MILLISECONDS);
        }
    }

    // 블랙리스트에 있는지 확인
    public boolean isBlacklisted(String token) {
        return redisTemplate.hasKey("BL:" + token);
    }

    // 토큰 추출
    // 헤더에서 액세스 토큰 추출
    public String extractAccessTokenFromHeader(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    // 쿠키에서 리프레시 토큰 추출
    public String extractRefreshTokenFromCookie(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (cookie.getName().equals("refreshToken")) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }

    // 리프레시 토큰을 HTTP-only 쿠키로 설정
    public Cookie createRefreshTokenCookie(String refreshToken) {
        Cookie refreshCookie = new Cookie("refreshToken", refreshToken);
        refreshCookie.setHttpOnly(true);  // JavaScript에서 접근 불가
        refreshCookie.setSecure(true);    // HTTPS에서만 전송
        refreshCookie.setPath("/");       // 모든 경로에서 접근 가능
        refreshCookie.setMaxAge((int) (jwtUtil.getRefreshTokenExpiration() / 1000)); // 초 단위로 변환
        return refreshCookie;
    }

    // 만료된 리프레시 토큰 쿠키 생성 (로그아웃)
    public Cookie createExpiredRefreshTokenCookie() {
        Cookie refreshCookie = new Cookie("refreshToken", "");
        refreshCookie.setHttpOnly(true);
        refreshCookie.setSecure(true);
        refreshCookie.setPath("/");
        refreshCookie.setMaxAge(0); // 즉시 만료
        return refreshCookie;
    }
}
