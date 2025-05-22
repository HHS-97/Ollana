package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.BattleHistory;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleResult;
import com.ssafy.ollana.footprint.persistent.entity.enums.BattleType;
import com.ssafy.ollana.footprint.persistent.repository.BattleHistoryRepository;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.UserVersusOtherResponseDto;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BattleHistoryService {

    private final BattleHistoryRepository battleHistoryRepository;
    private final HikingHistoryRepository hikingHistoryRepository;

    /*
     * 나 vs 친구, 나 vs AI 기록 조회
     */
    @Transactional(readOnly = true)
    public PageResponse<UserVersusOtherResponseDto> getHikingBattleRecords(Integer userId, Pageable pageable) {
        Page<BattleHistory> page = battleHistoryRepository.findByUserId(userId, pageable);

        Page<UserVersusOtherResponseDto> dtoPage = page.map(UserVersusOtherResponseDto::from);
        return new PageResponse<>("list", dtoPage);
    }

    public void saveBattleHistoryAfterTracking(User user, User opponent,
                                               Mountain mountain, Path path,
                                               Integer recordId, Integer finalTime) {
        HikingHistory opponentHistory = hikingHistoryRepository.findById(recordId)
                                                               .orElseThrow(NotFoundException::new);

        int opponentTime = opponentHistory.getHikingTime();
        BattleResult result = BattleResult.S;

        if (finalTime < opponentTime) result = BattleResult.W;
        else if (finalTime > opponentTime) result = BattleResult.L;

        BattleHistory history = BattleHistory.builder()
                                             .mountain(mountain)
                                             .path(path)
                                             .user(user)
                                             .opponent(opponent)
                                             .result(result)
                                             .build();

        battleHistoryRepository.save(history);
    }

}
