package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class KakaoResponseSaveException extends BusinessException {
    public KakaoResponseSaveException(String saveTarget) {
        super(saveTarget + " 저장 중 요루가 발생했습니다.", "K-003");
    }
}
