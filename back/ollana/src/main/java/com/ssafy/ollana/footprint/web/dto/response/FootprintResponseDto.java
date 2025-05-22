package com.ssafy.ollana.footprint.web.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FootprintResponseDto {
    private Integer footprintId;
    private String mountainName;
    private String imgUrl;
}
