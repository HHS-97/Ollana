package com.ssafy.ollana.common.s3.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class S3Exception extends BusinessException {
    private S3Exception(String message) {
        super(message, "S-001");
    }

    public static S3Exception uploadFailed(Throwable cause) {
        S3Exception exception = new S3Exception("파일 업로드 중 오류가 발생했습니다.");
        exception.initCause(cause);
        return exception;
    }

    public static S3Exception invalidFileType() {
        return new S3Exception("지원하지 않는 파일 형식입니다. (jpg/jpeg/png만 허용)");
    }

    public static S3Exception fileSizeExceeded() {
        return new S3Exception("파일 크기가 제한을 초과했습니다.");
    }
}
