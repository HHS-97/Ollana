package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Path;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PathRepository extends JpaRepository<Path, Integer> {

    List<Path> findByMountainId(Integer mountainId);
}
