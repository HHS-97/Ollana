package com.ssafy.ollana.footprint.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class UserVersusOtherListResponseDto {
    private List<UserVersusOtherResponseDto> list;
}
