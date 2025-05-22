package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface MountainRepository extends JpaRepository<Mountain, Integer>, MountainCustomRepository {
    Optional<Mountain> findByMntnCode(String mntnCode);

    // 산 코드만 리스트로 추출
    @Query("SELECT m.mntnCode FROM Mountain m")
    List<String> findAllMntnCode();

    // 산 이름 검색
    List<Mountain> findTop10ByMountainNameContaining(String mountainName);
    List<Mountain> findByMountainNameContaining(String mountainName);
}
