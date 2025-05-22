package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Builder
@Getter
public class OpponentRecordListDto {
    private List<OpponentRecordDto> records;

    public static OpponentRecordListDto from(List<HikingHistory> histories) {
        List<OpponentRecordDto> dtos = histories.stream()
                                                .map(OpponentRecordDto::from)
                                                .toList();
        return OpponentRecordListDto.builder()
                                    .records(dtos)
                                    .build();
    }
}
