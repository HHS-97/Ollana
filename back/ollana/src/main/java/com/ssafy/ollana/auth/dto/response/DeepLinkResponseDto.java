package com.ssafy.ollana.auth.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeepLinkResponseDto {
    private String deepLink;
    private boolean isNewUser;
}