package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MountainLocationResponseDto {
    private Integer mountainId;
    private String mountainName;
    private double latitude;
    private double longitude;

    public static MountainLocationResponseDto from(Mountain mountain) {
        return MountainLocationResponseDto.builder()
                .mountainId(mountain.getId())
                .mountainName(mountain.getMountainName())
                .latitude(mountain.getMountainLatitude())
                .longitude(mountain.getMountainLongitude())
                .build();
    }


}
