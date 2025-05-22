package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import lombok.Builder;
import lombok.Getter;
import org.springframework.data.domain.Page;

import java.util.List;

@Getter
public class HikingHistoryResponseDto extends PageResponse<HikingHistoryWithPathResponseDto> {
    private final MountainResponseDto mountain;

    public HikingHistoryResponseDto(MountainResponseDto mountain, Page<HikingHistoryWithPathResponseDto> page) {
        super("paths", page);
        this.mountain = mountain;
    }
}
