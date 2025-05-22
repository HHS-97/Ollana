package com.ssafy.ollana.user.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class UnsupportedPasswordOperationException extends BusinessException {
    public UnsupportedPasswordOperationException() {
        super("소셜 회원은 비밀번호 변경 또는 재설정을 지원하지 않습니다.", "P-001");
    }
}
