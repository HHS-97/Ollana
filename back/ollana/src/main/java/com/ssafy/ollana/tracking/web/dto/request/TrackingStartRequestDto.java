package com.ssafy.ollana.tracking.web.dto.request;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TrackingStartRequestDto {
    private Integer mountainId;
    private Integer pathId;
    private String mode;
    private Integer opponentId;
    private Integer recordId;
    private Double latitude;
    private Double longitude;
}
