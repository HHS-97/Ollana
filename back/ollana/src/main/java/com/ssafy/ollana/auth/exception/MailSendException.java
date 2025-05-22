package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class MailSendException extends BusinessException {
    public MailSendException() {
        super("메일 전송에 실패했습니다.", "E-001");
    }
}
