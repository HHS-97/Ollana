package com.ssafy.ollana.user.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class EmailAlreadyExistsException extends BusinessException {
    public EmailAlreadyExistsException() {
        super("이미 가입한 이메일입니다.", "U-001");
    }
}
