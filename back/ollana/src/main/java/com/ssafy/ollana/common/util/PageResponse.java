package com.ssafy.ollana.common.util;

import com.fasterxml.jackson.annotation.JsonAnyGetter;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.domain.Page;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Getter
@AllArgsConstructor
public class PageResponse<T> {
    private final Map<String, List<T>> data = new HashMap<>();
    private int currentPage;
    private int totalPages;
    private long totalElements;
    private boolean isLast;

    public PageResponse(String key, Page<T> page) {
        this.data.put(key, page.getContent());
        this.currentPage = page.getNumber();
        this.totalPages = page.getTotalPages();
        this.totalElements = page.getTotalElements();
        this.isLast = page.isLast();

    }

    @JsonAnyGetter
    public Map<String, List<T>> getData() {
        return data;
    }

}

