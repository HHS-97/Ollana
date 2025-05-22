package com.ssafy.ollana.footprint.service.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class AccessDeniedException extends BusinessException {
    public AccessDeniedException() {
        super("접근할 수 없는 데이터입니다.", "F-001");
    }
}
