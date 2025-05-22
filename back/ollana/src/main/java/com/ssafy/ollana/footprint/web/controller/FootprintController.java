package com.ssafy.ollana.footprint.web.controller;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.service.FootprintService;
import com.ssafy.ollana.footprint.web.dto.response.FootprintListResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.FootprintResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.LatestFootprintDescriptionResponseDto;
import com.ssafy.ollana.security.CustomUserDetails;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;


@RestController
@RequiredArgsConstructor
@RequestMapping("/footprint")
public class FootprintController {

    private final FootprintService footprintService;

    /*
     * 발자취 목록 조회
     */
    @GetMapping
    public ResponseEntity<Response<FootprintListResponseDto>> getFootprintList(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PageableDefault(size = 9) Pageable pageable) {

        FootprintListResponseDto response = footprintService.getFootprintList(userDetails.getUser().getId(), pageable);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 홈 화면용 유저 및 등산 정보 조회
     */
    @GetMapping("/main")
    public ResponseEntity<Response<LatestFootprintDescriptionResponseDto>> getFootprintDescription(
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        LatestFootprintDescriptionResponseDto response = footprintService.getFootprintDescription(userDetails.getUser().getId());
        return ResponseEntity.ok(Response.success(response));
    }


}
