package com.ssafy.ollana.user.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class MypageResponseDto {
    private String nickname;
    private String email;
    private String imageUrl;
    private boolean isAgree;
}
