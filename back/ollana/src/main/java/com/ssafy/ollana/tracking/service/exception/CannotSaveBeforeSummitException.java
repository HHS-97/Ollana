package com.ssafy.ollana.tracking.service.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class CannotSaveBeforeSummitException extends BusinessException {
    public CannotSaveBeforeSummitException() {
        super("등반하시는 코스의 마지막 지점까지 도착해야 기록을 저장할 수 있습니다.", "T-003");
    }
}
