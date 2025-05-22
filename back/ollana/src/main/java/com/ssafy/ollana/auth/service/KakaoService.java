package com.ssafy.ollana.auth.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.ollana.auth.dto.KakaoProfileDto;
import com.ssafy.ollana.auth.dto.KakaoTokenDto;
import com.ssafy.ollana.auth.dto.TempUserDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import com.ssafy.ollana.auth.exception.KakaoResponseParsingException;
import com.ssafy.ollana.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class KakaoService {

    private final TokenService tokenService;
    @Value("${spring.kakao.auth.client}")
    private String client;

    @Value("${spring.kakao.auth.redirect}")
    private String redirect;

    @Value("${spring.kakao.auth.admin}")
    private String admin;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // 카카오 인가 코드로 토큰 받아오기
    public KakaoTokenDto getAccessToken(String accessCode) {
        // 헤더
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8");

        // 바디
        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "authorization_code");
        body.add("client_id", client);
        body.add("redirect_uri", redirect);
        body.add("code", accessCode);

        // 헤더, 바디 연결
        HttpEntity<MultiValueMap<String, String>> kakaoTokenRequest = new HttpEntity<>(body, headers);

        // request 통해서 response 받아오기
        ResponseEntity<String> response = restTemplate.exchange(
                "https://kauth.kakao.com/oauth/token",
                HttpMethod.POST,
                kakaoTokenRequest,
                String.class
        );

        // response -> dto
        KakaoTokenDto kakaoTokenDto = null;
        try {
            kakaoTokenDto = objectMapper.readValue(response.getBody(), KakaoTokenDto.class);
        } catch (JsonProcessingException e) {
            throw new KakaoResponseParsingException();
        }

        return kakaoTokenDto;
    }

    // 받아온 토큰으로 사용자 정보 받아오기
    public KakaoProfileDto getKakaoProfile(KakaoTokenDto kakaoTokenDto) {
        // 헤더
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8");
        headers.add("Authorization", "Bearer " + kakaoTokenDto.getAccessToken());

        HttpEntity<MultiValueMap<String, String>> kakaoProfileRequest = new HttpEntity<>(headers);

        // request 통해서 response 받아오기
        ResponseEntity<String> response = restTemplate.exchange(
                "https://kapi.kakao.com/v2/user/me",
                HttpMethod.GET,
                kakaoProfileRequest,
                String.class
        );

        // response -> dto
        KakaoProfileDto kakaoProfileDto = null;
        try {
            kakaoProfileDto = objectMapper.readValue(response.getBody(), KakaoProfileDto.class);
        } catch (JsonProcessingException e) {
            throw new KakaoResponseParsingException();
        }

        return kakaoProfileDto;
    }

    // 연결 끊기
    public void unlinkKakao(User user) {
        // 헤더
        HttpHeaders headers = new HttpHeaders();
        headers.add("Authorization", "KakaoAK " + admin);
        headers.add("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8");

        // 바디
        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("target_id_type", "user_id");
        body.add("target_id", String.valueOf(user.getKakaoId()));

        // 헤더, 바디 연결
        HttpEntity<MultiValueMap<String, String>> kakaoUnlinkRequest = new HttpEntity<>(body, headers);

        // request 통해서 response 받아오기
        ResponseEntity<String> response = restTemplate.exchange(
                "https://kapi.kakao.com/v1/user/unlink",
                HttpMethod.POST,
                kakaoUnlinkRequest,
                String.class
        );
    }


    // 딥링크 리다이렉트용 임시 토큰 생성 - 회원가입 중 임시 사용자 정보
    public String generateKakaoTempToken(TempUserDto tempUser) {
        // UUID 기반 토큰 생성
        String token = UUID.randomUUID().toString();

        // redis 저장
        tokenService.saveTempUser(token, tempUser);

        return token;
    }

    // 딥링크 리다이렉트용 임시 토큰 생성 - 로그인 정보
    public String generateKakaoLoginToken(LoginResponseDto loginResponse) {
        // UUID 기반 토큰 생성
        String token = UUID.randomUUID().toString();

        // redis 저장
        tokenService.saveKakaoLoginResponse(token, loginResponse);
        return token;
    }
}
