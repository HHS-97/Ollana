package com.ssafy.ollana.mountain.web.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class MountainMapResponseDto {
    private int id;
    private String name;
    private double latitude;
    private double longitude;
    private double altitude;
    private String level;
    private String description;
}
