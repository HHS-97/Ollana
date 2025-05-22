package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class AuthenticationException extends BusinessException {
    public AuthenticationException(String message) {
        super(message, "A-001");
    }

    public static AuthenticationException userNotFound() {
        return new AuthenticationException("존재하지 않는 이메일입니다.");
    }

    public static AuthenticationException passwordMismatch() {
        return new AuthenticationException("비밀번호가 일치하지 않습니다.");
    }
}
