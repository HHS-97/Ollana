package com.ssafy.ollana.auth.dto.response;

import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.dto.LatestRecordDto;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class LoginResponseDto {
    private String accessToken;
    private UserInfoDto user;
    private LatestRecordDto latestRecord;
}
