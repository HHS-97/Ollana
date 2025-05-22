package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainSearchListResponseDto {
    private MountainAddressResponseDto mountain;
    private List<PathForTrackingResponseDto> paths;
}
