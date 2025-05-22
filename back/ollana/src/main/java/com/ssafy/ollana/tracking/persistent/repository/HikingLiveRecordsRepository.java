package com.ssafy.ollana.tracking.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HikingLiveRecordsRepository extends JpaRepository<HikingLiveRecords, Integer> {
    List<HikingLiveRecords> findByUserIdAndMountainIdAndPathIdOrderByTotalTimeAsc(
            Integer userId, Integer mountainId, Integer pathId
    );
    List<HikingLiveRecords> findByUserAndMountainAndPath(User user, Mountain mountain, Path path);
    void deleteByUserAndMountainAndPath(User user, Mountain mountain, Path path);
    List<HikingLiveRecords> findByHikingHistoryId(Integer hikingHistoryId);
}
