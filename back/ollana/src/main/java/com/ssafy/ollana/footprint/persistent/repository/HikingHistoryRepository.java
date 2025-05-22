package com.ssafy.ollana.footprint.persistent.repository;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HikingHistoryRepository extends JpaRepository<HikingHistory, Integer>, HikingHistoryRepositoryCustom {
    List<HikingHistory> findAllByFootprintIdOrderByCreatedAtAsc(Integer footprintId);


}
