package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.mountain.web.dto.GrowthStatus;

public class HikingHistoryUtils {

    public static GrowthStatus determineStatus(int timeDiff) {
        if (timeDiff < 0) return GrowthStatus.IMPROVING;
        else if (timeDiff > 0) return GrowthStatus.REGRESSING;
        else return GrowthStatus.STABLE;
    }
}
