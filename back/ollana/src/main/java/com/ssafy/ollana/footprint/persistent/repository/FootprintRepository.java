package com.ssafy.ollana.footprint.persistent.repository;

import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import com.ssafy.ollana.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FootprintRepository extends JpaRepository<Footprint, Integer> {
    Page<Footprint> findByUserId(Integer userId, Pageable pageable);
    Optional<Footprint> findByUserAndMountain(User user, Mountain mountain);
}
