package com.ssafy.ollana.common.util;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class Response<T> {
    private boolean status;  // 요청 성공 여부
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private T data;          // 응답 데이터
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private String message;  // 에러 메시지
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private String code;        // 에러 코드


    // 성공 응답
    public static <T> Response<T> success(T data) {
        Response<T> response = new Response<T>();
        response.status = true;
        response.data = data;
        return response;
    }

    public static <T> Response<T> success() {
        Response<T> response = new Response<T>();
        response.status = true;
        return response;
    }

    // 실패 응답
    public static <T> Response<T> fail(String message, String code) {
        Response<T> response = new Response<T>();
        response.status = false;
        response.message = message;
        response.code = code;
        return response;
    }

}
