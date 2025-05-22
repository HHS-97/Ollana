package com.ssafy.ollana.mountain.web.dto.response;

import com.ssafy.ollana.mountain.web.dto.MountainWeatherDto;
import com.ssafy.ollana.tracking.web.dto.response.PathForTrackingResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainDetailResponseDto {
    private String name;
    private double altitude;
    private String location;
    private String level;
    private String description;
    private List<PathForTrackingResponseDto> paths;
    private List<String> images;
    private MountainWeatherDto weather;
}
