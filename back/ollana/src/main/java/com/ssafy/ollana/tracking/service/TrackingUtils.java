package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.tracking.web.dto.response.BattleRecordsForTrackingResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.LatLngPointResponseDto;
import com.ssafy.ollana.user.entity.User;
import org.locationtech.jts.geom.LineString;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class TrackingUtils {

    public static List<LatLngPointResponseDto> convertLineStringToLatLng(LineString lineString) {
        return Arrays.stream(lineString.getCoordinates())
                     .map(LatLngPointResponseDto::from)
                     .collect(Collectors.toList());
    }

    public static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int EARTH_RADIUS = 6371000;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS * c;
    }

    public static List<HikingLiveRecords> toEntities(
                                                    List<BattleRecordsForTrackingResponseDto> dtos,
                                                    User user,
                                                    Mountain mountain,
                                                    Path path,
                                                    HikingHistory hikingHistory) {
        return dtos.stream()
                .map(dto -> HikingLiveRecords.builder()
                                             .user(user)
                                             .mountain(mountain)
                                             .path(path)
                                             .hikingHistory(hikingHistory)
                                             .totalTime(dto.getTime())
                                             .totalDistance(dto.getDistance())
                                             .latitude(dto.getLatitude())
                                             .longitude(dto.getLongitude())
                                             .heartRate(dto.getHeartRate())
                                             .build())
                .toList();
    }


}
