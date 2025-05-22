package com.ssafy.ollana.footprint.service.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class NotFoundException extends BusinessException {
    public NotFoundException() {
        super("존재하지 않는 데이터입니다.", "F-000");
    }
}
