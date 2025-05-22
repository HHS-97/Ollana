package com.ssafy.ollana.footprint.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class HikingRecordsByPeriodResponseDto {
    private List<TodayHikingResultResponseDto> records;
    private DiffResponseDto result;
}
