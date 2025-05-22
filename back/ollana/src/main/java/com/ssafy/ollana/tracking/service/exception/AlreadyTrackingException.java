package com.ssafy.ollana.tracking.service.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class AlreadyTrackingException extends BusinessException {
    public AlreadyTrackingException() {
        super("이미 등산 중입니다.", "T-001");
    }
}
