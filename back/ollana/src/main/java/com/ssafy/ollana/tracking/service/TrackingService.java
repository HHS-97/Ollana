package com.ssafy.ollana.tracking.service;

import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.entity.HikingHistory;
import com.ssafy.ollana.footprint.persistent.repository.FootprintRepository;
import com.ssafy.ollana.footprint.persistent.repository.HikingHistoryRepository;
import com.ssafy.ollana.footprint.service.BattleHistoryService;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.TodayHikingResultResponseDto;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import com.ssafy.ollana.mountain.web.dto.response.MountainResponseDto;
import com.ssafy.ollana.tracking.persistent.repository.HikingLiveRecordsRepository;
import com.ssafy.ollana.tracking.persistent.entity.HikingLiveRecords;
import com.ssafy.ollana.tracking.service.exception.AlreadyTrackingException;
import com.ssafy.ollana.tracking.service.exception.CannotSaveBeforeSummitException;
import com.ssafy.ollana.tracking.service.exception.InvalidTrackingException;
import com.ssafy.ollana.tracking.service.exception.NoNearbyMountainException;
import com.ssafy.ollana.tracking.web.dto.request.TrackingFinishRequestDto;
import com.ssafy.ollana.tracking.web.dto.request.TrackingStartRequestDto;
import com.ssafy.ollana.tracking.web.dto.response.*;
import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
import com.ssafy.ollana.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class TrackingService {
    private final MountainRepository mountainRepository;
    private final FootprintRepository footprintRepository;
    private final PathRepository pathRepository;
    private final UserRepository userRepository;
    private final HikingHistoryRepository hikingHistoryRepository;
    private final HikingLiveRecordsRepository hikingLiveRecordsRepository;
    private final UserService userService;
    private final BattleHistoryService battleHistoryService;
    private final ApplicationEventPublisher eventPublisher;
    private final RedisTemplate<String, String> redisTemplate;
    private static final String TRACKING_STATUS_KEY_PREFIX = "tracking:";


    /*
     * 사용자 위치 인식 후 가장 가까운 산 반환
     */
    @Transactional(readOnly = true)
    public NearestMountainResponseDto findNearestMountain(double lat, double lng) {
        Mountain mountain = mountainRepository.findNearestMountain(lat, lng)
                .orElseThrow(NoNearbyMountainException::new);

        List<Path> paths = pathRepository.findByMountainId(mountain.getId());

        return NearestMountainResponseDto.builder()
                .mountain(MountainResponseDto.from(mountain))
                .paths(paths.stream()
                        .map(PathForTrackingResponseDto::from)
                        .toList())
                .build();
    }

    /*
     * 산 검색 시 자동완성
     */
    @Transactional(readOnly = true)
    public MountainSuggestionsResponseDto getMountainSuggestions(String mountainName) {
        List<Mountain> mountains = mountainRepository.findTop10ByMountainNameContaining(mountainName);
        return MountainSuggestionsResponseDto.from(mountains);
    }

    /*
     * 산 검색 결과 반환
     */
    @Transactional(readOnly = true)
    public MountainSearchResponseDto getMountainSearchResults(String mountainName) {
        List<Mountain> mountains = mountainRepository.findByMountainNameContaining(mountainName);

        List<MountainSearchListResponseDto> results = mountains.stream()
                .map(mountain -> {
                    List<Path> paths = pathRepository.findByMountainId(mountain.getId());

                    return MountainSearchListResponseDto.builder()
                            .mountain(MountainAddressResponseDto.from(mountain))
                            .paths(paths.stream()
                                    .map(PathForTrackingResponseDto::from)
                                    .toList())
                            .build();
                })
                .toList();

        return MountainSearchResponseDto.from(results);
    }

    /*
     * 산 리스트 중 특정 산 선택 시 결과 반환
     */
    @Transactional(readOnly = true)
    public MountainSearchListResponseDto getMountainSelectResult(Integer mountainId) {
        Mountain mountain = mountainRepository.findById(mountainId)
                .orElseThrow(NotFoundException::new);

        List<Path> paths = pathRepository.findByMountainId(mountainId);

        return MountainSearchListResponseDto.builder()
                .mountain(MountainAddressResponseDto.from(mountain))
                .paths(paths.stream()
                        .map(PathForTrackingResponseDto::from)
                        .toList())
                .build();
    }

    /*
     * [나 VS 나] 모드 선택 시 가장 최근의 이전 정보 조회
     */
    @Transactional(readOnly = true)
    public TodayHikingResultResponseDto getHikingRecord(Integer userId, Integer mountainId, Integer pathId) {
        HikingHistory history = hikingHistoryRepository.findLatestRecord(userId, mountainId, pathId)
                .orElseThrow(NotFoundException::new);

        return TodayHikingResultResponseDto.from(history);
    }

    /*
     * [나 VS 친구] 모드 선택 시 친구 정보 조회
     */
    @Transactional(readOnly = true)
    public FriendListResponseDto getFriendsInfo(Integer userId, Integer mountainId, Integer pathId, String nickname) {
        List<FriendInfoResponseDto> friends = userRepository.searchFriends(nickname, mountainId, pathId, userId);

        return FriendListResponseDto.builder()
                                    .users(friends)
                                    .build();
    }

    /*
     * 대결 상대의 등산 기록 조회
     */
    @Transactional(readOnly = true)
    public OpponentRecordListDto findOpponentRecords(Integer userId, Integer mountainId, Integer pathId, Integer opponentId) {
        Integer targetId = (opponentId != null) ? opponentId : userId;

        List<HikingHistory> histories = hikingHistoryRepository
                .findOpponentHistories(targetId, mountainId, pathId);

        return OpponentRecordListDto.from(histories);
    }

    /*
     * 트래킹 시작 요청
     */
    @Transactional(readOnly = true)
    public TrackingStartResponseDto getTrackingStartInfo(Integer userId, TrackingStartRequestDto request) {

        // 등산 중인지 검증
        String redisKey = getTrackingStatusKey(userId);
        if (Boolean.TRUE.equals(redisTemplate.hasKey(redisKey))) {
            throw new AlreadyTrackingException();
        }

        Mountain mountain = mountainRepository.findById(request.getMountainId())
                .orElseThrow(NotFoundException::new);

        Path path = pathRepository.findById(request.getPathId())
                .orElseThrow(NotFoundException::new);

        // 선택한 산이 사용자 현 위치를 기준으로 반경 15km 이내에 존재하는지 검증
        boolean isNearby = mountainRepository.isMountainWithin10km(
                request.getMountainId(),
                request.getLatitude(),
                request.getLongitude()
        );

        User opponent = null;
        HikingHistory hikingHistory = null;
        OpponentResponseDto opponentDto = null;

        // mode가 ME이면 userId로 조회
        if ("ME".equals(request.getMode())) {
            opponent = userRepository.findById(userId)
                                     .orElseThrow(NotFoundException::new);
        }
        // mode가 FRIEND이면 opponentId로 조회
        else if ("FRIEND".equals(request.getMode()) && request.getOpponentId() != null) {
            opponent = userRepository.findById(request.getOpponentId())
                                     .orElseThrow(NotFoundException::new);
        }

        if (request.getRecordId() != null) {
            hikingHistory = hikingHistoryRepository.findById(request.getRecordId())
                                                   .orElseThrow(NotFoundException::new);
        }
        List<HikingLiveRecords> records = hikingLiveRecordsRepository.findByHikingHistoryId(request.getRecordId());

        if (opponent != null) {
            opponentDto = OpponentResponseDto.from(opponent, hikingHistory, records);
        }

        // redis에 등산 상태 저장
        String redisValue = request.getMountainId() + ":" + request.getPathId();
        redisTemplate.opsForValue().set(redisKey, redisValue, Duration.ofHours(24));

        return TrackingStartResponseDto.from(isNearby, mountain, path, opponentDto);
    }

    /*
     * 트래킹 종료 요청
     */
    @Transactional
    public TrackingFinishResponseDto manageTrackingFinish(Integer userId, TrackingFinishRequestDto request) {
        log.info("트래킹 종료 API 호출 -> 요청 데이터 : {}", request);

        String redisKey = getTrackingStatusKey(userId);
        String redisValue = (String) redisTemplate.opsForValue().get(redisKey);
        String expectedValue = request.getMountainId() + ":" + request.getPathId();
        if (redisValue == null || !redisValue.equals(expectedValue)) {
            throw new InvalidTrackingException();
        }

        User user = userRepository.findById(userId).orElseThrow(NotFoundException::new);
        Path path = pathRepository.findById(request.getPathId()).orElseThrow(NotFoundException::new);
        Mountain mountain = mountainRepository.findById(request.getMountainId()).orElseThrow(NotFoundException::new);

        // 정상 도착했는지 확인
        Coordinate end = path.getRoute().getEndPoint().getCoordinate();
        double endLat = end.y;
        double endLng = end.x;
        double userLat = request.getFinalLatitude();
        double userLng = request.getFinalLongitude();
        double distance = TrackingUtils.calculateDistance(endLat, endLng, userLat, userLng);

        if (distance > 300 && request.isSave()) {
            throw new CannotSaveBeforeSummitException();
        }

        // 기본 응답값 초기화
        String badge = mountain.getMountainBadge();
        Double avg = null;
        Integer max = null;
        Integer timeDiff = null;

        // 기록 저장 및 응답 데이터 계산
        if (request.isSave()) {
            Footprint footprint = footprintRepository.findByUserAndMountain(user, mountain)
                                        .orElseGet(() -> footprintRepository.save(Footprint.of(user, mountain)));

            List<Integer> heartRates = request.getRecords().stream()
                    .map(BattleRecordsForTrackingResponseDto::getHeartRate)
                    .filter(Objects::nonNull)
                    .toList();

            HikingHistory history = HikingHistory.of(footprint, path, request.getFinalTime(), heartRates);
            hikingHistoryRepository.save(history);

            avg = history.getAverageHeartRate();
            max = history.getMaxHeartRate();

            List<HikingLiveRecords> entityList = TrackingUtils.toEntities(request.getRecords(), user, mountain, path, history);
            hikingLiveRecordsRepository.saveAll(entityList);

            // 경험치 및 거리 갱신
            userService.updateUserInfoAfterTracking(user, request.getFinalDistance(), mountain.getLevel());
        }

        // 나 VS 친구인 경우 대결 결과 저장
        if ("FRIEND".equals(request.getMode())) {
            User opponent = userRepository.findById(request.getOpponentId()).orElseThrow(NotFoundException::new);
            battleHistoryService.saveBattleHistoryAfterTracking(user, opponent, mountain, path, request.getRecordId(), request.getFinalTime());
        }

        // 나 VS 친구, 나 VS 나인 경우 timeDiff 계산
        if ("ME".equals(request.getMode()) || "FRIEND".equals(request.getMode())) {
            if (request.getRecordId() != null) {
                HikingHistory opponentHistory = hikingHistoryRepository.findById(request.getRecordId())
                                                     .orElseThrow(NotFoundException::new);
                timeDiff = request.getFinalTime() - opponentHistory.getHikingTime();
            }
        }

        // Redis key 제거
        redisTemplate.delete(redisKey);
        return TrackingFinishResponseDto.of(badge, avg, max, timeDiff);
    }


    private String getTrackingStatusKey(Integer userId) {
        return TRACKING_STATUS_KEY_PREFIX + userId;
    }

}
