package com.ssafy.ollana.user.exception;

import com.ssafy.ollana.common.exception.BusinessException;

public class UserNotFoundException extends BusinessException {
    public UserNotFoundException() {
        super("해당 사용자가 존재하지 않습니다.", "U-003");
    }
}
