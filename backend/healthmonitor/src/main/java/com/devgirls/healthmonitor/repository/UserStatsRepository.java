package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.UserStats;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserStatsRepository extends JpaRepository<UserStats, Long> {
}
