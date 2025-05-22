package com.ssafy.ollana.auth.password.dto.request;

import jakarta.validation.constraints.Pattern;
import lombok.Getter;

@Getter
public class PasswordChangeRequestDto {
    @Pattern(regexp = "^(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$",
            message = "비밀번호는 8자리 이상이며 특수문자를 포함해야 합니다.")
    private String newPassword;
}
