package com.ssafy.ollana.tracking.web.dto.response;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.user.entity.User;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class OpponentResponseDto {
    private Integer opponentId;
    private String nickname;
    private Integer maxHeartRate;
    private Double averageHeartRate;
    private List<BattleRecordsForTrackingResponseDto> records;

    public static OpponentResponseDto from(User opponent, HikingHistory hikingHistory, List<HikingLiveRecords> records) {
        return OpponentResponseDto.builder()
                .opponentId(opponent.getId())
                .nickname(opponent.getNickname())
                .averageHeartRate(hikingHistory != null ? hikingHistory.getAverageHeartRate() : null)
                .maxHeartRate(hikingHistory != null ? hikingHistory.getMaxHeartRate() : null)
                .records(records.stream()
                        .map(BattleRecordsForTrackingResponseDto::from)
                        .toList())
                .build();
    }


}
