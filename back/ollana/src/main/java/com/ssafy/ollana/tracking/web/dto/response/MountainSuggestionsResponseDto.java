package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainSuggestionsResponseDto {
    private List<MountainAutoCompleteResponseDto> mountains;

    public static MountainSuggestionsResponseDto from(List<Mountain> mountains) {
        List<MountainAutoCompleteResponseDto> dtos = mountains.stream()
                                                              .map(MountainAutoCompleteResponseDto::from)
                                                              .toList();
        return MountainSuggestionsResponseDto.builder()
                                             .mountains(dtos)
                                             .build();
    }
}
