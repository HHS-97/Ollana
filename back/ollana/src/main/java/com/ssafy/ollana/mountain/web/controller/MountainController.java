package com.ssafy.ollana.mountain.web.controller;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.mountain.service.MountainService;
import com.ssafy.ollana.mountain.web.dto.response.MountainDetailResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainListResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/mountain")
@RequiredArgsConstructor
public class MountainController {

    private final MountainService mountainService;

    @GetMapping("/map")
    public ResponseEntity<Response<List<MountainMapResponseDto>>> getMountains() {
        List<MountainMapResponseDto> response = mountainService.getMountains();
        return ResponseEntity.ok(Response.success(response));
    }

    @GetMapping("/list")
    public ResponseEntity<Response<?>> getMountainList(
            @RequestParam(value = "search", required = false) String mountainName,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        // 검색어 있으면 산 검색
        if (mountainName != null && !mountainName.isEmpty()) {
            List<MountainListResponseDto> response = mountainService.searchMountain(mountainName);
            return ResponseEntity.ok(Response.success(response));
        } else {
            // 검색어 없으면 산 전체 리스트
            PageResponse<MountainListResponseDto> response = mountainService.getMountainList(page, size);
            return ResponseEntity.ok(Response.success(response));
        }
    }

    @GetMapping("/detail/{mountain_id}")
    public ResponseEntity<Response<MountainDetailResponseDto>> getMountainDetail(@PathVariable("mountain_id") int mountainId) {
        MountainDetailResponseDto response = mountainService.getMountainDetail(mountainId);
        return ResponseEntity.ok(Response.success(response));
    }

    @GetMapping("/save-image")
    public ResponseEntity<Response<Void>> saveMountainImg() {
        mountainService.saveMountainImg();
        return ResponseEntity.ok(Response.success());
    }
}
