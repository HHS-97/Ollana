package com.ssafy.ollana.auth.dto.request;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class KakaoSignupRequestDto {
    private String email;
    private String nickname;
    private String profileImage;
    private Long kakaoId;
    private String birth;
    private String gender;
    private boolean isSocial;
    private String tempToken;
}
