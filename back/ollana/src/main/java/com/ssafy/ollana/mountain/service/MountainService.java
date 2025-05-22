package com.ssafy.ollana.mountain.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.mountain.web.dto.response.MountainDetailResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainListResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;

import java.util.List;

public interface MountainService {
    void saveMountainImg();
    List<MountainMapResponseDto> getMountains();
    PageResponse<MountainListResponseDto> getMountainList(int page, int size);
    MountainDetailResponseDto getMountainDetail(int mountainId);
    List<MountainListResponseDto> searchMountain(String mountainName);
}
