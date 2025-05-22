package com.ssafy.ollana.mountain.web.dto;

import lombok.Getter;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;

// openweather response
@Getter
public class OpenWeatherDto {
    private double lat;
    private double lon;
    private String timezone;
    private int timezone_offset;
    private List<DailyData> daily;

    // 내가 내보낼 dto로 변환
    public MountainWeatherDto toMountainWeatherDto() {
        // 오늘 일출 시간, 일몰 시간
        DailyData today = daily.get(0);
        String sunrise = convertTime(today.getSunrise());
        String sunset = convertTime(today.getSunset());

        // 5일치 일일 예보
        List<MountainWeatherDto.DailyWeatherDto> dailyWeatherList = daily.stream()
                .limit(5)
                .map(DailyData::toDailyWeatherDto)
                .toList();

        return MountainWeatherDto.builder()
                .sunrise(sunrise)
                .sunset(sunset)
                .dailyWeather(dailyWeatherList)
                .build();
    }

    // Unix -> 한국 시간으로
    private String convertTime(long unixTime) {
        LocalDateTime dateTime = LocalDateTime.ofInstant(
                Instant.ofEpochSecond(unixTime),
                ZoneId.of("Asia/Seoul")
        );
        return dateTime.format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    // 일별 데이터
    @Getter
    public static class DailyData {
        private long dt;
        private long sunrise;
        private long sunset;
        private Temp temp;
        private double wind_speed;
        private List<WeatherInfo> weather;
        private double pop;
        private Double rain;
        private Double snow;

        // 기온 정보
        @Getter
        public static class Temp {
            private double min;
            private double max;
        }

        // 날씨 정보
        @Getter
        public static class WeatherInfo {
            private int id;
            private String main;
            private String description;
            private String icon;
        }

        // DailyData -> DailyWeatherDto
        public MountainWeatherDto.DailyWeatherDto toDailyWeatherDto() {
            WeatherInfo weatherInfo = weather.get(0);

            MountainWeatherDto.DailyWeatherDto.Weather weatherDto = MountainWeatherDto.DailyWeatherDto.Weather.builder()
                    .id(weatherInfo.getId())
                    .main(weatherInfo.getMain())
                    .description(weatherInfo.getDescription())
                    .icon(weatherInfo.getIcon())
                    .build();

            return MountainWeatherDto.DailyWeatherDto.builder()
                    .date(convertDateTime(dt))
                    .temperatureMin(temp.getMin())
                    .temperatureMax(temp.getMax())
                    .windSpeed(wind_speed)
                    .pop(pop)
                    .rain(rain)
                    .snow(snow)
                    .weather(weatherDto)
                    .build();
        }

        // Unix -> 한국 시간으로
        private String convertDateTime(long unixTime) {
            LocalDateTime dateTime = LocalDateTime.ofInstant(
                    Instant.ofEpochSecond(unixTime),
                    ZoneId.of("Asia/Seoul")
            );
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        }
    }
}
