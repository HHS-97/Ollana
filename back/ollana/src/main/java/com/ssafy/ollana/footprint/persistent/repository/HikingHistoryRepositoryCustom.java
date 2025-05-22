package com.ssafy.ollana.footprint.persistent.repository;

import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface HikingHistoryRepositoryCustom {
    List<HikingHistory> findHistories(Integer footprintId, Integer pathId, LocalDateTime start, LocalDateTime end);
    Optional<HikingHistory> findLatestRecord(Integer userId, Integer mountainId, Integer pathId);
    List<HikingHistory> findOpponentHistories(Integer userId, Integer mountainId, Integer pathId);
    List<HikingHistory> findAllByUserIdOrderByCreatedAtDesc(Integer userId);
}
