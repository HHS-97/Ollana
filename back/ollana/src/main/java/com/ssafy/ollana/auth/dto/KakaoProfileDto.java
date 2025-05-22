package com.ssafy.ollana.auth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
public class KakaoProfileDto {

    @JsonProperty("id")
    private Long kakaoId;

    @JsonProperty("kakao_account")
    private KakaoAccount kakaoAccount;

    @Getter
    @NoArgsConstructor
    public static class KakaoAccount {
        private String email;
        private Profile profile;
        @JsonProperty("profile_image_needs_agreement")
        private boolean profileImageNeedsAgreement;

        @Getter
        @NoArgsConstructor
        public static class Profile {
            private String nickname;

            @JsonProperty("profile_image_url")
            private String profileImageUrl;

            @JsonProperty("is_default_image")
            private boolean isDefaultImage;
        }
    }
}
