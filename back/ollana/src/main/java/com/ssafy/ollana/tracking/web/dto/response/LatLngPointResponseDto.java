package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;
import org.locationtech.jts.geom.Coordinate;

@Getter
@Builder
public class LatLngPointResponseDto {
    private double latitude;
    private double longitude;

    public static LatLngPointResponseDto from(Coordinate coord) {
        return LatLngPointResponseDto.builder()
                .latitude(coord.getY())  // Y = latitude
                .longitude(coord.getX()) // X = longitude
                .build();
    }
}
