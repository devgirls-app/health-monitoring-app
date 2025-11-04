package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.HealthTrends;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HealthTrendsRepository extends JpaRepository<HealthTrends, Long> {
}
