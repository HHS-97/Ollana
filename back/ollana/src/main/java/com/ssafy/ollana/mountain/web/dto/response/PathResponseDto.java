package com.ssafy.ollana.mountain.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Path;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PathResponseDto {
    private Integer pathId;
    private String pathName;

    public static PathResponseDto from(Path path) {
        return PathResponseDto.builder()
                              .pathId(path.getId())
                              .pathName(path.getPathName())
                              .build();
    }
}

