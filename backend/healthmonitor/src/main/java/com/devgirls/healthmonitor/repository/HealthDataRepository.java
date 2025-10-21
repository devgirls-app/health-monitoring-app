package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.HealthData;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface HealthDataRepository extends JpaRepository<HealthData, Long> {
    List<HealthData> findByUserUserId(Long userId);  // fetch health data for a specific user
}
