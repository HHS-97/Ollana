package com.ssafy.ollana.auth.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class SignupRequestDto {
    @Email(message = "유효한 이메일 형식이 아닙니다.")
    private String email;

    @Pattern(regexp = "^(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$",
            message = "비밀번호는 8자리 이상이며 특수문자를 포함해야 합니다.")
    private String password;

    @Size(max = 10, message = "닉네임은 10자리 이하여야 합니다.")
    private String nickname;

    private String birth;
    private String gender;
}
