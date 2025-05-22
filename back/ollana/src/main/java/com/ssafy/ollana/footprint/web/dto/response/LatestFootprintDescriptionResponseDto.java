package com.ssafy.ollana.footprint.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class LatestFootprintDescriptionResponseDto {
    private UserInfoResponseDto user;
    private GrowthInfoResponseDto growth;

    public static LatestFootprintDescriptionResponseDto of(UserInfoResponseDto userDto, GrowthInfoResponseDto growthDto) {
        return LatestFootprintDescriptionResponseDto.builder()
                .user(userDto)
                .growth(growthDto)
                .build();
    }
}
