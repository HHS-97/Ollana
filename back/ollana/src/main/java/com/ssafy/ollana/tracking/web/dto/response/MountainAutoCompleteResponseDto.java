package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MountainAutoCompleteResponseDto {
    private Integer mountainId;
    private String mountainName;
    private Double mountainHeight;
    private String mountainLoc;

    public static MountainAutoCompleteResponseDto from(Mountain mountain) {
        return MountainAutoCompleteResponseDto.builder()
                                             .mountainId(mountain.getId())
                                             .mountainName(mountain.getMountainName())
                                             .mountainHeight(mountain.getMountainHeight())
                                             .mountainLoc(mountain.getMountainLoc())
                                             .build();
    }
}
