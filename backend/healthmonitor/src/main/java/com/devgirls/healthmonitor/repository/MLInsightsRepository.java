package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.MLInsights;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface MLInsightsRepository extends JpaRepository<MLInsights, Long> {
    List<MLInsights> findByAggregate_User_UserIdAndAggregate_DateBetweenOrderByAggregate_DateAsc(
            Long userId,
            LocalDate start,
            LocalDate end
    );
}