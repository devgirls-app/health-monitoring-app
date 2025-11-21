package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.HealthData;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.sql.Timestamp;
import java.util.List;
import java.util.Map;

import java.time.LocalDate;
import java.util.Optional;

public interface HealthDataRepository extends JpaRepository<HealthData, Long> {

    List<HealthData> findAllByUser_UserId(Long userId);

    Optional<HealthData> findFirstByUser_UserIdAndDay(
            Long userId,
            LocalDate day
    );

    @Query(value = """
        SELECT 
          COALESCE(SUM(steps),0)                                  AS steps,
          COALESCE(SUM(calories),0)::numeric                      AS calories,
          COALESCE(AVG(CASE WHEN heart_rate > 0 THEN heart_rate END), 0) AS hr_mean,
          COALESCE(MAX(heart_rate), 0) AS hr_max,
          COALESCE(MAX(sleep_hours),0)::numeric                   AS sleep
        FROM health_data
        WHERE user_id = :userId AND "timestamp" >= :from AND "timestamp" < :to
        """, nativeQuery = true)
    Map<String, Object> aggregateRange(@Param("userId") Long userId,
                                       @Param("from") Timestamp from,
                                       @Param("to") Timestamp to);
}
