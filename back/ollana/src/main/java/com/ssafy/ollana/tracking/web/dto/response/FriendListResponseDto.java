package com.ssafy.ollana.tracking.web.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class FriendListResponseDto {
    private List<FriendInfoResponseDto> users;
}
