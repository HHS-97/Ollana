package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class InvalidEmailCodeException extends BusinessException {
    public InvalidEmailCodeException() {
        super("인증번호가 일치하지 않습니다.", "E-003");
    }
}
