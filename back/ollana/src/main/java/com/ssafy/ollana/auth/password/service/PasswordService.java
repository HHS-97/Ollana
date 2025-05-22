package com.ssafy.ollana.auth.password.service;

import com.ssafy.ollana.auth.password.dto.request.PasswordChangeRequestDto;
import com.ssafy.ollana.auth.password.dto.request.PasswordResetRequestDto;
import com.ssafy.ollana.auth.service.MailService;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.exception.UnsupportedPasswordOperationException;
import com.ssafy.ollana.user.exception.UserNotFoundException;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;

@Service
@RequiredArgsConstructor
public class PasswordService {

    private final UserRepository userRepository;
    private final MailService mailService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public void sendPasswordEmail(PasswordResetRequestDto request) {
        String email = request.getEmail();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException());

        // 소셜 회원인지 확인
        if (user.isSocial()) {
            throw new UnsupportedPasswordOperationException();
        }

        // 임시 비밀번호 생성 및 저장
        String tempPassword = createTempPassword();
        user.setPassword(passwordEncoder.encode(tempPassword));

        // 임시 비밀번호 사용 필드 true
        user.setTempPassword(true);

        userRepository.save(user);

        // 임시 비밀번호 메일 생성 및 전송
        mailService.sendTempPasswordMail(email, tempPassword);
    }

    @Transactional
    public void passwordChange(CustomUserDetails userDetails, PasswordChangeRequestDto request) {
        User user = userDetails.getUser();

        // 소셜 회원인지 확인
        if (user.isSocial()) {
            throw new UnsupportedPasswordOperationException();
        }

        // 새로운 비밀번호 설정
        String encodePassword = passwordEncoder.encode(request.getNewPassword());
        user.setPassword(encodePassword);

        // 임시 비밀번호 사용 필드 false
        user.setTempPassword(false);

        userRepository.save(user);
    }


    // 임시 비밀번호 생성
    private String createTempPassword() {
        int length = 10;
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
        SecureRandom secureRandom = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(secureRandom.nextInt(chars.length())));
        }
        return sb.toString();
    }
}
