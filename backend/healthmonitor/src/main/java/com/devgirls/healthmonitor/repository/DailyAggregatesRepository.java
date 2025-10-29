package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.DailyAggregates;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.*;

public interface DailyAggregatesRepository extends JpaRepository<DailyAggregates, Long> {
    Optional<DailyAggregates> findByUser_UserIdAndDate(Long userId, LocalDate date);

    @Query(value = """

            SELECT steps_total
        FROM daily_aggregates
        WHERE user_id = :userId AND date = :date
        LIMIT 1
        """, nativeQuery = true)
    Integer findStepsTotal(@Param("userId") Long userId,
                           @Param("date") LocalDate date);

    @Query(value = """
        SELECT *
        FROM daily_aggregates
        WHERE user_id = :userId AND date BETWEEN :from AND :to
        ORDER BY date
        """, nativeQuery = true)
    List<DailyAggregates> findRange(@Param("userId") Long userId,
                                    @Param("from") LocalDate from,
                                    @Param("to") LocalDate to);
}