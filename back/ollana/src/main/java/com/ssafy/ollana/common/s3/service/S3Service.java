package com.ssafy.ollana.common.s3.service;

import com.ssafy.ollana.common.s3.exception.S3Exception;
import io.awspring.cloud.s3.S3Template;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.web.servlet.MultipartProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final MultipartProperties multipartProperties;
    @Value("${spring.cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${spring.cloud.aws.region.static}")
    private String region;

    @Value("${app.default-profile-image-url}")
    private String defaultProfileImageUrl;

    // 허용되는 확장자 목록
    private static final Set<String> ALLOWED_IMAGE_EXTENSIONS = Set.of("jpg", "jpeg", "png");

    private final S3Template s3Template;

    // S3에 파일 업로드
    public String uploadFile(MultipartFile file, String dirName) {
        // 파일 유효성 검사
        validateFile(file);

        try {
            // 파일 이름 생성
            String fileName = dirName + "/" + UUID.randomUUID() + "-" + file.getOriginalFilename();

            // 파일 업로드
            s3Template.upload(bucket, fileName, file.getInputStream());

            // S3 url 생성
            return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + fileName;
        } catch (IOException e) {
            throw S3Exception.uploadFailed(e);
        }
    }

    // 파일 유효성 검사
    private void validateFile(MultipartFile file) {
        // 파일이 비어있는지
        if (file.isEmpty()) {
            throw S3Exception.invalidFileType();
        }

        // 파일 크기 확인
        if (file.getSize() > multipartProperties.getMaxFileSize().toBytes()) {
            throw S3Exception.fileSizeExceeded();
        }

        // 파일 확장자 확인
        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null) {
            String extension = getFileExtension(originalFilename).toLowerCase();
            if (!ALLOWED_IMAGE_EXTENSIONS.contains(extension)) {
                throw S3Exception.invalidFileType();
            }
        } else {
            throw S3Exception.invalidFileType();
        }
    }

    // 기본 프로필 이미지 제공
    public String getDefaultProfileImageUrl() {
        return defaultProfileImageUrl;
    }

    // S3에 업로드 된 파일 삭제
    public void deleteFile(String fileUrl) {
        String key = extractKeyFromFileUrl(fileUrl);
        s3Template.deleteObject(bucket, key);
    }


    // 파일 확장자 가져오기
    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex > 0) {
            return filename.substring(lastDotIndex + 1);
        }
        return "";
    }

    // url에서 S3 객체 키 추출
    private String extractKeyFromFileUrl(String fileUrl) {
        String[] parts = fileUrl.split(".amazonaws.com/");
        return parts[1];
    }
}
