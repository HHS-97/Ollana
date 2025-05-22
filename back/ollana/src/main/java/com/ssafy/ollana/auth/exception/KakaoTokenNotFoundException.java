package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class KakaoTokenNotFoundException extends BusinessException {
    public KakaoTokenNotFoundException(String tokenType) {
        super(tokenType + "의 데이터를 찾을 수 없습니다.", "K-002");
    }
}
