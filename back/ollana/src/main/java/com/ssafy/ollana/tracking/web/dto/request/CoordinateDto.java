package com.ssafy.ollana.tracking.web.dto.request;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class CoordinateDto {
    private double latitude;
    private double longitude;
}