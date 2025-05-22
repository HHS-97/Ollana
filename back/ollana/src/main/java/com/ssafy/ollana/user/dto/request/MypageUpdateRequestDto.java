package com.ssafy.ollana.user.dto.request;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class MypageUpdateRequestDto {
    private String nickname;
    private Boolean isAgree;
}
