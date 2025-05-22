package com.ssafy.ollana.mountain.web.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class MountainListResponseDto {
    private int id;
    private String name;
    private double latitude;
    private double longitude;
    private double altitude;
    private String location;
    private String level;
    private String description;
    private List<String> images;
}
