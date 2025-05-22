package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TrackingFinishResponseDto {
    private String badge;
    private Double averageHeartRate;
    private Integer maxHeartRate;
    private Integer timeDiff;

    public static TrackingFinishResponseDto of(String badge, Double avg, Integer max, Integer timeDiff) {
        return TrackingFinishResponseDto.builder()
                .badge(badge)
                .averageHeartRate(avg)
                .maxHeartRate(max)
                .timeDiff(timeDiff)
                .build();
    }
}
