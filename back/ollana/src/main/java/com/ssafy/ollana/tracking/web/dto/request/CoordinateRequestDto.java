package com.ssafy.ollana.tracking.web.dto.request;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class CoordinateRequestDto {
    private List<CoordinateDto> coordinates;
}