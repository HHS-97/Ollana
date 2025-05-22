package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class NearestMountainResponseDto {
    private MountainResponseDto mountain;
    private List<PathForTrackingResponseDto> paths;
}
