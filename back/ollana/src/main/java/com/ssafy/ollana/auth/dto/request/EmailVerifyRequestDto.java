package com.ssafy.ollana.auth.dto.request;

import lombok.Getter;

@Getter
public class EmailVerifyRequestDto {
    private String email;
    private String code;
}
