package com.ssafy.ollana.mountain.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class MountainNotFoundException extends BusinessException {
    public MountainNotFoundException() {
        super("산 정보를 찾을 수 없습니다.", "M-001");
    }
}
