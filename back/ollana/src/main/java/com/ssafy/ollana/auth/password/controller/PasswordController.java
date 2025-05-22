package com.ssafy.ollana.auth.password.controller;

import com.ssafy.ollana.auth.password.dto.request.PasswordChangeRequestDto;
import com.ssafy.ollana.auth.password.dto.request.PasswordResetRequestDto;
import com.ssafy.ollana.auth.password.service.PasswordService;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth/password")
@RequiredArgsConstructor
public class PasswordController {

    private final PasswordService passwordService;

    @PostMapping("/reset")
    public ResponseEntity<Response<Void>> passwordReset(@RequestBody PasswordResetRequestDto request) {
        passwordService.sendPasswordEmail(request);
        return ResponseEntity.ok(Response.success());
    }

    @PostMapping("/change")
    public ResponseEntity<Response<Void>> passwordChange(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                         @RequestBody PasswordChangeRequestDto request) {
        passwordService.passwordChange(userDetails, request);
        return ResponseEntity.ok(Response.success());
    }
}
