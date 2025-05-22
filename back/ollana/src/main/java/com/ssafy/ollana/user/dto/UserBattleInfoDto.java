package com.ssafy.ollana.user.dto;

import com.ssafy.ollana.user.entity.User;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserBattleInfoDto {
    private Integer opponentId;
    private String nickname;
    private String profile;

    public static UserBattleInfoDto from(User user) {
        return UserBattleInfoDto.builder()
                .opponentId(user.getId())
                .nickname(user.getNickname())
                .profile(user.getProfileImage())
                .build();
    }
}
