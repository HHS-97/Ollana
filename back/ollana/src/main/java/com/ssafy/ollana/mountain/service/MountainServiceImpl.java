package com.ssafy.ollana.mountain.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.mountain.exception.MountainNotFoundException;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.mountain.persistent.entity.MountainImg;
import com.ssafy.ollana.mountain.persistent.entity.Path;
import com.ssafy.ollana.mountain.persistent.repository.MountainImgRepository;
import com.ssafy.ollana.mountain.persistent.repository.MountainRepository;
import com.ssafy.ollana.mountain.persistent.repository.PathRepository;
import com.ssafy.ollana.mountain.web.dto.MountainWeatherDto;
import com.ssafy.ollana.mountain.web.dto.OpenWeatherDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainDetailResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainListResponseDto;
import com.ssafy.ollana.mountain.web.dto.response.MountainMapResponseDto;
import com.ssafy.ollana.tracking.web.dto.response.PathForTrackingResponseDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MountainServiceImpl implements MountainService {

    @Value("${api.service-key}")
    private String serviceKey;

    @Value("${openweather.api.key}")
    private String openweather;

    private final RestClient restClient;
    private final PathRepository pathRepository;
    private final MountainRepository mountainRepository;
    private final MountainImgRepository mountainImgRepository;

    @Override
    @Transactional(readOnly = true)
    public List<MountainMapResponseDto> getMountains() {
        List<Mountain> mountainList = mountainRepository.findAll();

        List<MountainMapResponseDto> response = mountainList.stream()
                .map(mountain -> new MountainMapResponseDto(
                        mountain.getId(),
                        mountain.getMountainName(),
                        mountain.getMountainLatitude(),
                        mountain.getMountainLongitude(),
                        mountain.getMountainHeight(),
                        mountain.getLevel().name(),
                        mountain.getMountainDescription()
                ))
                .toList();

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<MountainListResponseDto> getMountainList(int page, int size) {
        PageRequest pageRequest = PageRequest.of(page, size);
        Page<Mountain> mountainList = mountainRepository.findAll(pageRequest);

        Page<MountainListResponseDto> response = mountainList.map(mountain -> new MountainListResponseDto(
                        mountain.getId(),
                        mountain.getMountainName(),
                        mountain.getMountainLatitude(),
                        mountain.getMountainLongitude(),
                        mountain.getMountainHeight(),
                        mountain.getMountainLoc(),
                        mountain.getLevel().name(),
                        mountain.getMountainDescription(),
                        mountain.getMountainImgs().stream()
                                .map(MountainImg::getImage)
                                .toList()
                ));

        return new PageResponse<>("mountains", response);
    }

    @Override
    @Transactional(readOnly = true)
    public MountainDetailResponseDto getMountainDetail(int mountainId) {
        Mountain mountain = mountainRepository.findById(mountainId)
                .orElseThrow(MountainNotFoundException::new);

        // 등산로 가져오기
        List<Path> paths = pathRepository.findByMountainId(mountainId);

        // Path -> dto
        List<PathForTrackingResponseDto> pathDto = paths.stream()
                .map(PathForTrackingResponseDto::from)
                .toList();

        // 날씨 가져오기 (5일치)
        MountainWeatherDto weather = getWeather(mountain);

        MountainDetailResponseDto response = MountainDetailResponseDto.builder()
                .name(mountain.getMountainName())
                .altitude(mountain.getMountainHeight())
                .location(mountain.getMountainLoc())
                .level(mountain.getLevel().name())
                .description(mountain.getMountainDescription())
                .paths(pathDto)
                .images(mountain.getMountainImgs().stream()
                        .map(MountainImg::getImage)
                        .toList())
                .weather(weather)
                .build();

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public List<MountainListResponseDto> searchMountain(String mountainName) {
        List<Mountain> mountains = mountainRepository.findByMountainNameContaining(mountainName);

        List<MountainListResponseDto> response = mountains.stream()
                .map(mountain -> new MountainListResponseDto(
                        mountain.getId(),
                        mountain.getMountainName(),
                        mountain.getMountainLatitude(),
                        mountain.getMountainLongitude(),
                        mountain.getMountainHeight(),
                        mountain.getMountainLoc(),
                        mountain.getLevel().name(),
                        mountain.getMountainDescription(),
                        mountain.getMountainImgs().stream()
                                .map(MountainImg::getImage)
                                .toList()
                ))
                .toList();

        return response;
    }


    @Override
    @Transactional
    public void saveMountainImg() {
        // 산 코드 리스트 가져오기
        List<String> mntnCodeList = mountainRepository.findAllMntnCode();
        for (String mntnCode : mntnCodeList) {
            try {
                // 외부 api 호출
                String url = "https://apis.data.go.kr/1400000/service/cultureInfoService2/mntInfoImgOpenAPI2" +
                        "?mntiListNo=" + mntnCode + "&ServiceKey=" + serviceKey;

                // HttpURLConnection
                URL apiUrl = new URL(url);
                HttpURLConnection connection = (HttpURLConnection) apiUrl.openConnection();
                connection.setRequestMethod("GET");

                int responseCode = connection.getResponseCode();

                // 응답 읽기
                BufferedReader in;
                if (responseCode >= 200 && responseCode < 300) {
                    in = new BufferedReader(new InputStreamReader(connection.getInputStream(), StandardCharsets.UTF_8));
                } else {
                    in = new BufferedReader(new InputStreamReader(connection.getErrorStream(), StandardCharsets.UTF_8));
                }

                String inputLine;
                StringBuilder content = new StringBuilder();
                while ((inputLine = in.readLine()) != null) {
                    content.append(inputLine);
                }
                in.close();
                connection.disconnect();

                String xml = content.toString();

                // XML 파싱 및 처리
                if (xml.contains("SERVICE_ERROR") || xml.contains("<errMsg>")) {
                    System.out.println("API 오류 발생: " + xml);
                    continue;
                }

                // XML 문자열 -> DOM 객체로 파싱
                DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
                factory.setNamespaceAware(false); // 네임스페이스 무시
                DocumentBuilder builder = factory.newDocumentBuilder();
                Document document = builder.parse(new InputSource(new StringReader(xml)));

                // <item> 태그 목록 가져오기
                NodeList itemList = document.getElementsByTagName("item");

                // 해당 산 가져오기
                Mountain mountain = mountainRepository.findByMntnCode(mntnCode)
                        .orElseThrow(() -> new MountainNotFoundException());

                int count = itemList.getLength();
                for (int i = 0; i < count; i++) {
                    Element item = (Element) itemList.item(i);

                    // imgfilename 가져오기
                    String imgfilename = item.getElementsByTagName("imgfilename").item(0).getTextContent();

                    // 이미지 url 생성 및 저장
                    String imgUrl = "www.forest.go.kr/images/data/down/mountain/" + imgfilename;

                    // 산 이미지 테이블 생성 및 저장
                    MountainImg mountainImg = MountainImg.builder()
                            .mountain(mountain)
                            .image(imgUrl)
                            .build();
                    mountainImgRepository.save(mountainImg);
                }

            } catch (Exception e) {
                log.error("산 이미지 저장 중 오류 발생: mntnCode={}, error={}", mntnCode, e.getMessage());
            }
        }
    }

    // openweather api로 날씨 가져오기
    private MountainWeatherDto getWeather(Mountain mountain) {
        OpenWeatherDto response = restClient
                .get()
                .uri("https://api.openweathermap.org/data/3.0/onecall?lat={lat}&lon={lon}&exclude={exclude}&appid={appid}&units={units}",
                        mountain.getMountainLatitude(),
                        mountain.getMountainLongitude(),
                        "current,minutely,hourly,alerts",
                        openweather,
                        "metric")
                .retrieve()
                .body(OpenWeatherDto.class);

        return response.toMountainWeatherDto();
    }
}
