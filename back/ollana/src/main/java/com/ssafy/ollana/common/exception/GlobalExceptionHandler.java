package com.ssafy.ollana.common.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.ollana.common.util.Response;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 커스텀 비즈니스 예외 처리
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Response<Void>> handleBusinessException(BusinessException e) {
        log.error("BusinessException 발생 : ", e);
        Response<Void> response = Response.fail(e.getMessage(), e.getErrorCode());
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * @Valid 유효성 검사 실패 처리
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Response<Void>> handleValidationException(MethodArgumentNotValidException e) {
        FieldError fieldError = e.getBindingResult().getFieldError();
        String message = (fieldError != null) ? fieldError.getDefaultMessage() : "유효하지 않은 요청입니다.";
        log.warn("MethodArgumentNotValidException 발생 : ", e);
        return ResponseEntity.badRequest().body(Response.fail(message, "E-001"));
    }

    /**
     * 잘못된 요청 처리
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Response<Void>> handleIllegalArgumentException(IllegalArgumentException e) {
        log.error("IllegalArgumentException 발생 : ", e);
        return ResponseEntity.badRequest().body(Response.fail("잘못된 요청입니다.", "E-002"));
    }

    /**
     * 예기치 못한 모든 예외 처리
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Response<Void>> handleException(Exception e) {
        log.error("Exception 발생 : ", e);
        return ResponseEntity.internalServerError().body(Response.fail("서버 내부 오류가 발생했습니다.", "E-000"));
    }
}
