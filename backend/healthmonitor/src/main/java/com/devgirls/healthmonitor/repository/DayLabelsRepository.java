package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.DayLabels;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DayLabelsRepository extends JpaRepository<DayLabels, Long> {
}
