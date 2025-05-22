package com.ssafy.ollana.tracking.web.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FriendInfoResponseDto {
    private Integer userId;
    private String nickname;
    private Boolean isPossible;
    private String profileImg;

    @JsonProperty("isPossible")
    public boolean isPossible() {
        return isPossible;
    }
}
