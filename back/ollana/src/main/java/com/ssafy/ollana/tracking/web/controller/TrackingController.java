package com.ssafy.ollana.tracking.web.controller;

import com.ssafy.ollana.common.util.Response;
import com.ssafy.ollana.footprint.web.dto.response.TodayHikingResultResponseDto;
import com.ssafy.ollana.mountain.persistent.entity.Level;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import com.ssafy.ollana.security.CustomUserDetails;
import com.ssafy.ollana.tracking.service.TrackingService;
import com.ssafy.ollana.tracking.web.dto.request.CoordinateDto;
import com.ssafy.ollana.tracking.web.dto.request.CoordinateRequestDto;
import com.ssafy.ollana.tracking.web.dto.request.TrackingFinishRequestDto;
import com.ssafy.ollana.tracking.web.dto.request.TrackingStartRequestDto;
import com.ssafy.ollana.tracking.web.dto.response.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.geolatte.geom.V;
import org.locationtech.jts.geom.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequiredArgsConstructor
@RequestMapping("/tracking")
@Slf4j
public class TrackingController {

    private final TrackingService trackingService;

    /*
     * 사용자 위치 인식 후 가장 가까운 산 반환
     */
    @GetMapping("/mountains/nearby")
    public ResponseEntity<Response<NearestMountainResponseDto>> getNearestMountain(
                                                        @RequestParam double lat,
                                                        @RequestParam double lng) {
        NearestMountainResponseDto response = trackingService.findNearestMountain(lat, lng);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 산 검색 시 자동완성
     */
    @GetMapping("/search")
    public ResponseEntity<Response<MountainSuggestionsResponseDto>> getMountainSuggestions(@RequestParam String mtn) {
        log.info("검색 단어 = {}", mtn);
        MountainSuggestionsResponseDto response = trackingService.getMountainSuggestions(mtn);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 산 검색 결과 반환
     */
    @GetMapping("/search/list")
    public ResponseEntity<Response<MountainSearchResponseDto>> getMountainSearchResults(@RequestParam String mtn) {
        MountainSearchResponseDto response = trackingService.getMountainSearchResults(mtn);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 산 리스트 중 특정 산 선택 시 결과 반환
     */
    @GetMapping("/search/mountain/{mountainId}")
    public ResponseEntity<Response<MountainSearchListResponseDto>> getMountainSelectResult(@PathVariable Integer mountainId) {
        MountainSearchListResponseDto response = trackingService.getMountainSelectResult(mountainId);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * [나 VS 나] 모드 선택 시 이전 정보 조회
     */
    @GetMapping("/me/mountain/{mountainId}/path/{pathId}")
    public ResponseEntity<Response<TodayHikingResultResponseDto>> getHikingRecord(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                                  @PathVariable Integer mountainId,
                                                                                  @PathVariable Integer pathId) {
        TodayHikingResultResponseDto response = trackingService.getHikingRecord(userDetails.getUser().getId(), mountainId, pathId);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * [나 VS 친구] 모드 선택 시 친구 정보 조회
     */
    @GetMapping("/friends")
    public ResponseEntity<Response<FriendListResponseDto>> getFriendsInfo(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                          @RequestParam Integer mountainId,
                                                                          @RequestParam Integer pathId,
                                                                          @RequestParam String nickname) {
        FriendListResponseDto response = trackingService.getFriendsInfo(userDetails.getUser().getId(), mountainId, pathId, nickname);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 대결 상대의 등산 기록 조회
     */
    @GetMapping("/options")
    public ResponseEntity<Response<OpponentRecordListDto>> getOpponentRecords(
                                                        @AuthenticationPrincipal CustomUserDetails userDetails,
                                                        @RequestParam Integer mountainId,
                                                        @RequestParam Integer pathId,
                                                        @RequestParam(required = false) Integer opponentId
    ) {
        OpponentRecordListDto response = trackingService.findOpponentRecords(userDetails.getUser().getId(), mountainId, pathId, opponentId);
        return ResponseEntity.ok(Response.success(response));
    }


    /*
     * 트래킹 시작 요청
     */
    @GetMapping("/start")
    public ResponseEntity<Response<TrackingStartResponseDto>> getTrackingStartInfo(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                                   @RequestBody TrackingStartRequestDto request) {
        TrackingStartResponseDto response = trackingService.getTrackingStartInfo(userDetails.getUser().getId(), request);
        return ResponseEntity.ok(Response.success(response));
    }

    /*
     * 트래킹 종료 요청
     */
    @PostMapping("/finish")
    public ResponseEntity<Response<TrackingFinishResponseDto>> manageTrackingFinish(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                 @RequestBody TrackingFinishRequestDto request) {
        TrackingFinishResponseDto response = trackingService.manageTrackingFinish(userDetails.getUser().getId(), request);
        return ResponseEntity.ok(Response.success(response));
    }

    //------------------------------------------------------------------------------------------------------------------------------
    private final MountainRepository mountainRepository;
    private final PathRepository pathRepository;

    /*
     * 테스트용 가상 등산로 좌표 저장 API
     */
    @PostMapping("/ssafy")
    public ResponseEntity<Response<String>> saveSSAFY(@RequestBody CoordinateRequestDto request) {

        List<CoordinateDto> coords = request.getCoordinates();
        log.info("싸피산 API 호출");
        log.info("싸피산 요청 데이터 coords : {}", coords);

        if (coords == null || coords.isEmpty()) {
            return ResponseEntity.ok(Response.success("저장 실패"));
        }

        CoordinateDto first = coords.get(0);

        // geom 생성
        log.info("싸피산 Mountain geom 생성");
        GeometryFactory gf = new GeometryFactory(new PrecisionModel(), 4326);
        Point geom = gf.createPoint(new Coordinate(first.getLongitude(), first.getLatitude()));

        // Mountain 저장
        log.info("싸피산 Mountain 저장 또는 반환");
        Optional<Mountain> optionalMountain = mountainRepository.findByMntnCode("3000");

        Mountain mountain;

        if (optionalMountain.isPresent()) {
            mountain = optionalMountain.get();
        } else {
            mountain = Mountain.builder()
                    .mntnCode("3000")
                    .mountainName("싸피산")
                    .mountainLoc("광주")
                    .mountainHeight(1200)
                    .mountainDescription("싸피산입니다")
                    .level(Level.L)
                    .mountainLatitude(first.getLatitude())
                    .mountainLongitude(first.getLongitude())
                    .geom(gf.createPoint(new Coordinate(first.getLongitude(), first.getLatitude())))
                    .mountainBadge(null)
                    .build();

            mountainRepository.save(mountain);
        }

        log.info("싸피산 : Path 저장을 위해 LineString 생성 시작");
        // LineString 생성
        Coordinate[] lineCoords = coords.stream()
                .map(c -> new Coordinate(c.getLongitude(), c.getLatitude()))
                .toArray(Coordinate[]::new);

        LineString route = gf.createLineString(lineCoords);

        // centerPoint 계산
        Coordinate center = getCenterCoordinate(lineCoords);
        Point centerPoint = gf.createPoint(center);

        log.info("싸피산 : Path 저장 시작");
        // Path 저장
        Path path = Path.builder()
                .mountain(mountain)
                .pathName("주차장 등산로2")
                .pathLength(260.0)
                .level(Level.L)
                .pathTime("7")
                .route(route)
                .centerPoint(centerPoint)
                .build();

        pathRepository.save(path);

        log.info("싸피산 API 정상 응답 완료");
        return ResponseEntity.ok(Response.success("저장 완료"));
    }

    private Coordinate getCenterCoordinate(Coordinate[] coords) {
        double sumLat = 0;
        double sumLng = 0;

        for (Coordinate c : coords) {
            sumLat += c.getY();
            sumLng += c.getX();
        }

        return new Coordinate(sumLng / coords.length, sumLat / coords.length);
    }
}
