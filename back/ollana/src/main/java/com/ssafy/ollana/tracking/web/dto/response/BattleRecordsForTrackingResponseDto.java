package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import lombok.Builder;
import lombok.Getter;
import lombok.ToString;

@Getter
@Builder
@ToString
public class BattleRecordsForTrackingResponseDto {
    private int time;
    private double distance;
    private int heartRate;
    private Double latitude;
    private Double longitude;

    public static BattleRecordsForTrackingResponseDto from(HikingLiveRecords records) {
        return BattleRecordsForTrackingResponseDto.builder()
                                                  .time(records.getTotalTime())
                                                  .distance(records.getTotalDistance())
                                                  .heartRate(records.getHeartRate())
                                                  .latitude(records.getLatitude())
                                                  .longitude(records.getLongitude())
                                                  .build();
    }

}
