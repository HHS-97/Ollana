package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class TodayHikingResultResponseDto {
    private Integer recordId;
    private LocalDate date;
    private int maxHeartRate;
    private double averageHeartRate;
    private int time;

    public static TodayHikingResultResponseDto from(HikingHistory history) {
        return TodayHikingResultResponseDto.builder()
                                          .recordId(history.getId())
                                          .date(history.getCreatedAt().toLocalDate())
                                          .maxHeartRate(history.getMaxHeartRate())
                                          .averageHeartRate(history.getAverageHeartRate())
                                          .time(history.getHikingTime())
                                          .build();
    }
}
