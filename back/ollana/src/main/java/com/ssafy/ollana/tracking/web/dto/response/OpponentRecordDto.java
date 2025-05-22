package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Builder
@Getter
public class OpponentRecordDto {
    private Integer recordId;
    private LocalDate date;
    private int time;

    public static OpponentRecordDto from(HikingHistory history) {
        return OpponentRecordDto.builder()
                                .recordId(history.getId())
                                .date(history.getCreatedAt().toLocalDate())
                                .time(history.getHikingTime())
                                .build();
    }
}
