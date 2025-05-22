package com.ssafy.ollana.auth.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AccessTokenResponseDto {
    private String accessToken;
}
