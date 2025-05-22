package com.ssafy.ollana.mountain.web.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MountainWeatherDto {
    private String sunrise;             // 일출 시간
    private String sunset;              // 일몰 시간
    private List<DailyWeatherDto> dailyWeather;

    @Getter
    @Builder
    public static class DailyWeatherDto {
        private String date;
        private double temperatureMin;   // 최저 온도
        private double temperatureMax;   // 최고 온도
        private double windSpeed;        // 풍속 (단위: 미터/초)
        private double pop;              // 강수 확률
        private Double rain;             // 강수량, null 가능성 있음
        private Double snow;             // 적설량, null 가능성 있음
        private Weather weather;

        @Getter
        @Builder
        public static class Weather {
            private int id;             // 날씨 코드
            private String main;        // ex) Clear, Clouds
            private String description; // 날씨 상세한 설명
            private String icon;        // 날씨 아이콘
        }
    }
}