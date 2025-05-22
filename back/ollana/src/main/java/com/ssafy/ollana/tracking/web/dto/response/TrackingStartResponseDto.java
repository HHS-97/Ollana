package com.ssafy.ollana.tracking.web.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TrackingStartResponseDto {
    private Boolean isNearby;
    private MountainLocationResponseDto mountain;
    private PathForTrackingResponseDto path;
    private OpponentResponseDto opponent;

    @JsonProperty("isNearby")
    public boolean isNearby() {
        return isNearby;
    }

    public static TrackingStartResponseDto from(boolean isNearby,
                                                Mountain mountain,
                                                Path path,
                                                OpponentResponseDto opponent) {
        return TrackingStartResponseDto.builder()
                .isNearby(isNearby)
                .mountain(MountainLocationResponseDto.from(mountain))
                .path(PathForTrackingResponseDto.from(path))
                .opponent(opponent)
                .build();
    }
}
