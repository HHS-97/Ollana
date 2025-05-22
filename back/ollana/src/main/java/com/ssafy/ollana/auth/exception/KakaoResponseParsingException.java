package com.ssafy.ollana.auth.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class KakaoResponseParsingException extends BusinessException {
    public KakaoResponseParsingException() {
        super("카카오 API 응답을 파싱하는데 실패했습니다.", "K-001");
    }
}
