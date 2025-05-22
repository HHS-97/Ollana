package com.ssafy.ollana.mountain.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MountainResponseDto {
    private Integer mountainId;
    private String mountainName;

    public static MountainResponseDto from(Mountain mountain) {
        return MountainResponseDto.builder()
                                  .mountainId(mountain.getId())
                                  .mountainName(mountain.getMountainName())
                                  .build();
    }
}
