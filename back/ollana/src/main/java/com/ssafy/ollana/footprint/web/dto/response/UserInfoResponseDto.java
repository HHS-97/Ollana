package com.ssafy.ollana.footprint.web.dto.response;

import com.ssafy.ollana.user.entity.Grade;
import com.ssafy.ollana.user.entity.User;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserInfoResponseDto {
    private int exp;
    private int gradeCount;
    private Grade grade;

    public static UserInfoResponseDto of(User user) {
        return UserInfoResponseDto.builder()
                .exp(user.getExp())
                .gradeCount(user.getGradeCount())
                .grade(user.getGrade())
                .build();
    }
}
