package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.user.dto.UserBattleInfoDto;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class UserVersusOtherResponseDto {
    private MountainResponseDto mountain;
    private String result;
    private LocalDate date;
    private UserBattleInfoDto opponent;

    public static UserVersusOtherResponseDto from(BattleHistory battleHistory) {
        return UserVersusOtherResponseDto.builder()
                .mountain(MountainResponseDto.from(battleHistory.getMountain()))
                .result(battleHistory.getResult().name())
                .date(battleHistory.getCreatedAt().toLocalDate())
                .opponent(UserBattleInfoDto.from(battleHistory.getOpponent()))
                .build();
    }
}
