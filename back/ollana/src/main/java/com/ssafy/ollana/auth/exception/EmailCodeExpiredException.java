package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class EmailCodeExpiredException extends BusinessException {
    public EmailCodeExpiredException() {
        super("인증번호가 만료되었거나 존재하지 않습니다.", "E-002");
    }
}
