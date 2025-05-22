package com.ssafy.ollana.footprint.web.controller;


import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleType;
import com.ssafy.ollana.footprint.service.BattleHistoryService;
import com.ssafy.ollana.footprint.service.HikingHistoryService;
import com.ssafy.ollana.footprint.web.dto.response.*;
import com.ssafy.ollana.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/footprint")
@Slf4j
public class HikingHistoryController {

    private final HikingHistoryService hikingHistoryService;
    private final BattleHistoryService battleHistoryService;

    /*
     * 나 vs 나 전체 기록 조회
     */
    @GetMapping("/{footprintId}")
    public ResponseEntity<Response<HikingHistoryResponseDto>> getHikingHistory(
                                                @AuthenticationPrincipal CustomUserDetails userDetails,
                                                @PathVariable Integer footprintId,
                                                @PageableDefault(size = 9) Pageable pageable) {

        HikingHistoryResponseDto response = hikingHistoryService.getHikingHistory(userDetails.getUser().getId(), footprintId, pageable);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 나 vs 나 이전 기록 조회 (그래프)
     */
    @GetMapping("/{footprintId}/path/{pathId}")
    public ResponseEntity<Response<HikingRecordsForGraphResponseDto>> getHikingRecordsByPeriod(
                                                @AuthenticationPrincipal CustomUserDetails userDetails,
                                                @PathVariable Integer footprintId,
                                                @PathVariable Integer pathId,
                                                @RequestParam LocalDate start,
                                                @RequestParam LocalDate end) {

        HikingRecordsForGraphResponseDto response = hikingHistoryService.getHikingRecordsByPeriod(userDetails.getUser().getId(), footprintId, pathId, start, end);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 특정 날짜를 지정하여 나 vs 나 기록 비교
     */
    @GetMapping("/{footprintId}/compare")
    public ResponseEntity<Response<HikingRecordsByPeriodResponseDto>> compareByRecordIds(
                                                @AuthenticationPrincipal CustomUserDetails userDetails,
                                                @RequestParam List<Integer> recordIds) {

        HikingRecordsByPeriodResponseDto response = hikingHistoryService.compareByRecordIds(userDetails.getUser().getId(), recordIds);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 나 vs 친구, 나 vs AI 기록 조회
     */
    @GetMapping("/battle")
    public ResponseEntity<Response<PageResponse<UserVersusOtherResponseDto>>> getHikingBattleRecords(
                                                @AuthenticationPrincipal CustomUserDetails userDetails,
                                                @PageableDefault(size = 9) Pageable pageable) {

        PageResponse<UserVersusOtherResponseDto> response = battleHistoryService.getHikingBattleRecords(userDetails.getUser().getId(), pageable);
        return ResponseEntity.ok(Response.success(response));
    }


}
