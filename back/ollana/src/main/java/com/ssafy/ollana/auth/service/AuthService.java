package com.ssafy.ollana.auth.service;

import com.ssafy.ollana.auth.dto.request.KakaoSignupRequestDto;
import com.ssafy.ollana.auth.dto.request.LoginRequestDto;
import com.ssafy.ollana.auth.dto.request.SignupRequestDto;
import com.ssafy.ollana.auth.dto.response.DeepLinkResponseDto;
import com.ssafy.ollana.auth.dto.response.LoginResponseDto;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.multipart.MultipartFile;

public interface AuthService {
    void signup(SignupRequestDto request, MultipartFile profileImage);
    LoginResponseDto login(LoginRequestDto request, HttpServletResponse response);
    void logout(HttpServletRequest request, HttpServletResponse response);

    DeepLinkResponseDto processKakaoLogin(String accessCode, HttpServletResponse response);
    LoginResponseDto saveKakaoUserAndLogin(KakaoSignupRequestDto request, HttpServletResponse response);
}
