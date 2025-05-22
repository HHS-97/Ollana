package com.ssafy.ollana.tracking.service.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class NoNearbyMountainException extends BusinessException {
    public NoNearbyMountainException() {
        super("반경 15km 이내에 산이 존재하지 않습니다.", "T-000");
    }
}
