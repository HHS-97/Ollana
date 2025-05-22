package com.ssafy.ollana.user.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class LatestRecordDto {
    private String mountainName;
    private String climbDate;
    private int climbTime;
    private double climbDistance;
}
