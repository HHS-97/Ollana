package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;

import java.util.Optional;

public interface MountainCustomRepository {
    // 사용자 위치를 기준으로 반경 15km 이내에 존재하는 가장 가까운 산 조회
    Optional<Mountain> findNearestMountain(double lat, double lng);

    // 해당 산이 사용자의 위치를 기준으로 반경 15km 이내에 존재하는지 검증
    boolean isMountainWithin10km(Integer mountainId, double lat, double lng);

}
