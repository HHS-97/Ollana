package com.ssafy.ollana.footprint.persistent.repository;

import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BattleHistoryRepository extends JpaRepository<BattleHistory, Integer> {
    Page<BattleHistory> findByUserId(Integer userId, Pageable pageable);
}
