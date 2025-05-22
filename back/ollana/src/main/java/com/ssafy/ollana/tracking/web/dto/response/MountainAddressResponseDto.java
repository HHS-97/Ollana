package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MountainAddressResponseDto {
    private Integer mountainId;
    private String mountainName;
    private String location;

    public static MountainAddressResponseDto from(Mountain mountain) {
        return MountainAddressResponseDto.builder()
                                         .mountainId(mountain.getId())
                                         .mountainName(mountain.getMountainName())
                                         .location(mountain.getMountainLoc())
                                         .build();
    }

}
