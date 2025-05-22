package com.ssafy.ollana.security.jwt;

import com.ssafy.ollana.auth.service.TokenService;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.service.CustomUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final CustomUserDetailsService customUserDetailsService;
    private final TokenService tokenService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {

        // 요청 헤더에서 access token 추출
        String accessToken = tokenService.extractAccessTokenFromHeader(request);

        if (accessToken != null && !tokenService.isBlacklisted(accessToken)) {

            // 토큰 유효성 검사
            if (jwtUtil.validateToken(accessToken)) {
                setAuthentication(accessToken);

            // 토큰 만료 여부 확인
            } else if (jwtUtil.isTokenExpired(accessToken)) {
                // 만료 되었으면 refresh token 검증 및 로테이션 처리, access token 새로 발금
                String refreshToken = getRefreshTokenFromCookie(request);

                // 리프레시 토큰 검증
                if (refreshToken != null && jwtUtil.validateToken(refreshToken) &&
                        !tokenService.isBlacklisted(refreshToken)) {

                    // user 정보 추출
                    String userEmail = jwtUtil.getUserEmailFromToken(refreshToken);
                    int userId = jwtUtil.getUserIdFromToken(refreshToken);

                    // redis 분산 락 획득 시도 (동시 요청 처리를 위해)
                    boolean lockAcquired = tokenService.acquireRefreshLock(userEmail);

                    if (lockAcquired) {
                        try {
                            // redis에 있는 refresh token과 일치하는지 확인
                            if (tokenService.validateRefreshToken(userEmail, refreshToken)) {
                                // 기존 리프레시 토큰을 블랙리스트에 추가
                                tokenService.blacklistToken(refreshToken, "rotation");

                                // 새로운 토큰 생성
                                String newAccessToken = jwtUtil.createAccessToken(userEmail, userId);
                                String newRefreshToken = jwtUtil.createRefreshToken(userEmail, userId);

                                // redis에 새로운 리프레시 토큰 저장
                                tokenService.saveRefreshToken(userEmail, newRefreshToken);

                                // 새로운 리프레시 토큰을 쿠키에 설정
                                Cookie refreshCookie = tokenService.createRefreshTokenCookie(newRefreshToken);
                                response.addCookie(refreshCookie);

                                // 새로운 액세스 토큰을 응답 헤더에 넣어주기
                                response.setHeader("Authorization", "Bearer " + newAccessToken);

                                // SecurityContext 갱신
                                setAuthentication(newAccessToken);
                            }
                        } finally {
                            // 락 해제
                            tokenService.releaseRefreshLock(userEmail);
                        }
                    }
                }
            }
        }

        filterChain.doFilter(request, response);
    }


    // 요청 쿠키에서 refresh token 추출
    private String getRefreshTokenFromCookie(HttpServletRequest request) {
        if (request.getCookies() == null) {
            return null;
        }

        for (Cookie cookie : request.getCookies()) {
            if (cookie.getName().equals("refreshToken")) {
                return cookie.getValue();
            }
        }

        return null;
    }

    private void setAuthentication(String accessToken) {
        String email = jwtUtil.getUserEmailFromToken(accessToken);
        CustomUserDetails userDetails = customUserDetailsService.loadUserByUsername(email);
        UsernamePasswordAuthenticationToken authenticationToken = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());

        SecurityContextHolder.getContext().setAuthentication(authenticationToken);
    }
}
