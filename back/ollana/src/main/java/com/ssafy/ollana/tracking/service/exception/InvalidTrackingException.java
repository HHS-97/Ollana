package com.ssafy.ollana.tracking.service.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class InvalidTrackingException extends BusinessException {
    public InvalidTrackingException() {
        super("해당 산의 등산로를 등산하고 있지 않습니다.", "T-002");
    }
}
