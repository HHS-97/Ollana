package com.ssafy.ollana.footprint.web.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class HikingRecordsForGraphResponseDto {
    private boolean isExceed;

    @JsonProperty("isExceed")
    public boolean isExceed() {
        return isExceed;
    }
    private List<TodayHikingResultResponseDto> records;
}
