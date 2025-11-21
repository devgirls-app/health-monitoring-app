package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.Recommendations;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RecommendationsRepository extends JpaRepository<Recommendations, Long> {

    List<Recommendations> findByUser_UserIdAndSourceAndCreatedAtBetween(
            Long userId,
            String source,
            LocalDateTime from,
            LocalDateTime to
    );

    Optional<Recommendations> findFirstByUser_UserIdAndSourceAndCreatedAtBetween(
            Long userId,
            String source,
            LocalDateTime from,
            LocalDateTime to
    );
}
