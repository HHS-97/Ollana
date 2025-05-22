package com.ssafy.ollana.user.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class NicknameAlreadyExistsException extends BusinessException {
    public NicknameAlreadyExistsException() {
        super("이미 사용중인 닉네임입니다.", "U-002");
    }
}
