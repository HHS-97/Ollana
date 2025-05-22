package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainSearchResponseDto {
    private List<MountainSearchListResponseDto> results;

    public static MountainSearchResponseDto from(List<MountainSearchListResponseDto> results) {
        return MountainSearchResponseDto.builder()
                                        .results(results)
                                        .build();
    }
}
