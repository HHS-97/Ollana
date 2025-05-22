package com.ssafy.ollana.user.service;

import com.ssafy.ollana.mountain.persistent.entity.Level;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.dto.LatestRecordDto;
import com.ssafy.ollana.user.dto.request.MypageUpdateRequestDto;
import com.ssafy.ollana.user.dto.request.WithdrawlRequest;
import com.ssafy.ollana.user.dto.response.MypageResponseDto;
import com.ssafy.ollana.user.dto.UserInfoDto;
import com.ssafy.ollana.user.entity.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.multipart.MultipartFile;

public interface UserService {
    MypageResponseDto getMypage(CustomUserDetails userDetails);
    MypageResponseDto updateMypage(CustomUserDetails userDetails, MypageUpdateRequestDto request, MultipartFile profileImage);
    void withdraw(HttpServletRequest request, HttpServletResponse response, CustomUserDetails userDetails, WithdrawlRequest withdrawlRequest);

    // Auth에서 필요한 메서드
    UserInfoDto getUserInfo(User user);
    LatestRecordDto getLatestRecord(User user);
    void updateUserInfoAfterTracking(User user, Double finalDistance, Level level);
}
