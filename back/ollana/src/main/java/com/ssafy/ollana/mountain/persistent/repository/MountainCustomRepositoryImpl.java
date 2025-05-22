package com.ssafy.ollana.mountain.persistent.repository;

import com.ssafy.ollana.mountain.persistent.entity.Mountain;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class MountainCustomRepositoryImpl implements MountainCustomRepository {

    private final EntityManager em;

    @Override
    public Optional<Mountain> findNearestMountain(double lat, double lng) {
        String sql = """
            SELECT * FROM mountain
            WHERE ST_DWithin(
                ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
                geom::geography,
                15000
            )
            ORDER BY ST_Distance(
                ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
                geom::geography
            )
            LIMIT 1
        """;

        List<Mountain> result = em.createNativeQuery(sql, Mountain.class)
                .setParameter("lat", lat)
                .setParameter("lng", lng)
                .getResultList();

        return result.stream().findFirst();
    }

    @Override
    public boolean isMountainWithin10km(Integer mountainId, double lat, double lng) {
        String sql = """
        SELECT COUNT(*) FROM mountain
        WHERE mountain_id = :mountainId
          AND ST_DWithin(
              ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
              geom::geography,
              15000
          )
    """;

        Object result = em.createNativeQuery(sql)
                .setParameter("lat", lat)
                .setParameter("lng", lng)
                .setParameter("mountainId", mountainId)
                .getSingleResult();

        return ((Number) result).intValue() > 0;
    }

}
