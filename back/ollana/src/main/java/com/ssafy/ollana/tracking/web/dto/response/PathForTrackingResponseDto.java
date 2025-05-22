package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.tracking.service.TrackingUtils;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class PathForTrackingResponseDto {
    private Integer pathId;
    private String pathName;
    private Double pathLength;
    private String pathTime;
    private List<LatLngPointResponseDto> route;

    public static PathForTrackingResponseDto from(Path path) {
        return PathForTrackingResponseDto.builder()
                .pathId(path.getId())
                .pathName(path.getPathName())
                .pathLength(path.getPathLength())
                .pathTime(path.getPathTime())
                .route(TrackingUtils.convertLineStringToLatLng(path.getRoute()))
                .build();
    }

}
