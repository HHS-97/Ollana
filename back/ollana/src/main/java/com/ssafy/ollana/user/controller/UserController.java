package com.ssafy.ollana.user.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.user.dto.request.MypageUpdateRequestDto;
import com.ssafy.ollana.user.dto.request.WithdrawlRequest;
import com.ssafy.ollana.user.dto.response.MypageResponseDto;
import com.ssafy.ollana.user.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/mypage")
    public ResponseEntity<Response<MypageResponseDto>> getMypage(@AuthenticationPrincipal CustomUserDetails userDetails) {
        MypageResponseDto response = userService.getMypage(userDetails);
        return ResponseEntity.ok(Response.success(response));
    }

    @PatchMapping("/mypage")
    public ResponseEntity<Response<MypageResponseDto>> updateMypage(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                    @RequestPart(value = "userData", required = false) MypageUpdateRequestDto requset,
                                                                    @RequestPart(value = "profileImage", required = false) MultipartFile profileImage) {
        MypageResponseDto response = userService.updateMypage(userDetails, requset, profileImage);
        return ResponseEntity.ok(Response.success(response));
    }

    @DeleteMapping("/withdraw")
    public ResponseEntity<Response<Void>> withdraw(HttpServletRequest request,
                                                   HttpServletResponse response,
                                                   @AuthenticationPrincipal CustomUserDetails userDetails,
                                                   @RequestBody WithdrawlRequest withDrawlRequest) {
        userService.withdraw(request, response, userDetails, withDrawlRequest);
        return ResponseEntity.ok(Response.success());
    }
}
