package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.HealthData;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.sql.Timestamp;
import java.util.List;
import java.util.Map;

public interface HealthDataRepository extends JpaRepository<HealthData, Long> {

    // ✅ Исправленный метод
    List<HealthData> findAllByUser_UserId(Long userId);

    @Query(value = """
        SELECT 
          COALESCE(SUM(steps),0)                                  AS steps,
          COALESCE(SUM(calories),0)::numeric                      AS calories,
          COALESCE(AVG(NULLIF(heart_rate,0)),0)::numeric          AS hr_mean,
          COALESCE(MAX(heart_rate),0)                             AS hr_max,
          COALESCE(SUM(sleep_hours),0)::numeric                   AS sleep
        FROM health_data
        WHERE user_id = :userId AND "timestamp" >= :from AND "timestamp" < :to
        """, nativeQuery = true)
    Map<String, Object> aggregateRange(@Param("userId") Long userId,
                                       @Param("from") Timestamp from,
                                       @Param("to") Timestamp to);
}
