package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class RefreshTokenException extends BusinessException {
    public RefreshTokenException(String message) {
        super(message, "A-002");
    }

    public static RefreshTokenException notFound() {
        return new RefreshTokenException("리프레시 토큰을 찾을 수 없습니다.");
    }

    public static RefreshTokenException invalid() {
        throw new RefreshTokenException("유효하지 않은 리프레시 토큰입니다.");
    }

    public static RefreshTokenException mismatch() {
        return new RefreshTokenException("저장된 리프레시 토큰과 일치하지 않습니다.");
    }
}
