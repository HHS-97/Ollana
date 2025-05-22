package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class GrowthInfoResponseDto {
    private String mountainName;
    private LocalDate date;
    private Integer pastTime;
    private Integer recentTime;

    public static GrowthInfoResponseDto of(HikingHistory latestHistory, Integer pastTime) {
        return GrowthInfoResponseDto.builder()
                                    .mountainName(latestHistory.getFootprint().getMountain().getMountainName())
                                    .date(latestHistory.getCreatedAt().toLocalDate())
                                    .recentTime(latestHistory.getHikingTime())
                                    .pastTime(pastTime)
                                    .build();
    }
}
