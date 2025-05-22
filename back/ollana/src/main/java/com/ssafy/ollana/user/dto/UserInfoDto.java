package com.ssafy.ollana.user.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserInfoDto {
    private int id;
    private String email;
    private String nickname;
    private int exp;
    private String grade;
    private int gradeCount;
    private double totalDistance;
    private String profileImageUrl;
    private boolean isTempPassword;
    private boolean isSocial;
}
