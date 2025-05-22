package com.ssafy.ollana.footprint.persistent.repository;

import com.querydsl.jpa.impl.JPAQueryFactory;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.entity.QFootprint;
import com.ssafy.ollana.mountain.persistent.entity.QMountain;
import com.ssafy.ollana.mountain.persistent.entity.QPath;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import static com.ssafy.ollana.footprint.persistent.entity.QFootprint.footprint;
import static com.ssafy.ollana.footprint.persistent.entity.QHikingHistory.hikingHistory;
import static com.ssafy.ollana.mountain.persistent.entity.QMountain.mountain;
import static com.ssafy.ollana.mountain.persistent.entity.QPath.path;

@Repository
@RequiredArgsConstructor
public class HikingHistoryRepositoryImpl implements HikingHistoryRepositoryCustom {
    private final JPAQueryFactory queryFactory;

    @Override
    public List<HikingHistory> findHistories(Integer footprintId, Integer pathId, LocalDateTime start, LocalDateTime end) {
        return queryFactory
                .selectFrom(hikingHistory)
                .where(
                        hikingHistory.footprint.id.eq(footprintId),
                        hikingHistory.path.id.eq(pathId),
                        hikingHistory.createdAt.between(start, end)
                )
                .orderBy(hikingHistory.createdAt.asc())
                .fetch();
    }

    @Override
    public Optional<HikingHistory> findLatestRecord(Integer userId, Integer mountainId, Integer pathId) {
        return Optional.ofNullable(
                queryFactory.selectFrom(hikingHistory)
                            .join(hikingHistory.footprint, footprint).fetchJoin()
                            .where(
                                    footprint.user.id.eq(userId),
                                    footprint.mountain.id.eq(mountainId),
                                    hikingHistory.path.id.eq(pathId)
                            )
                            .orderBy(hikingHistory.createdAt.desc())
                            .limit(1)
                            .fetchOne()
            );
    }

    @Override
    public List<HikingHistory> findOpponentHistories(Integer userId, Integer mountainId, Integer pathId) {
        return queryFactory
                .selectFrom(hikingHistory)
                .join(hikingHistory.footprint, footprint).fetchJoin()
                .where(
                        footprint.user.id.eq(userId),
                        footprint.mountain.id.eq(mountainId),
                        hikingHistory.path.id.eq(pathId)
                )
                .orderBy(hikingHistory.createdAt.desc())
                .fetch();
    }

    @Override
    public List<HikingHistory> findAllByUserIdOrderByCreatedAtDesc(Integer userId) {
        return queryFactory.selectFrom(hikingHistory)
                            .join(hikingHistory.footprint, footprint).fetchJoin()
                            .join(footprint.mountain, mountain).fetchJoin()
                            .join(hikingHistory.path, path).fetchJoin()
                            .where(footprint.user.id.eq(userId))
                            .orderBy(hikingHistory.createdAt.desc())
                            .fetch();
    }
}
