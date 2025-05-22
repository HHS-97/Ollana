package com.ssafy.ollana.user.repository;

import com.ssafy.ollana.tracking.web.dto.response.FriendInfoResponseDto;

import java.util.List;

public interface UserRepositoryCustom {
    List<FriendInfoResponseDto> searchFriends(String nickname, Integer mountainId, Integer pathId, Integer userId);
}
