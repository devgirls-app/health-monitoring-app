package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.KafkaLogs;
import org.springframework.data.jpa.repository.JpaRepository;

public interface KafkaLogsRepository extends JpaRepository<KafkaLogs, Long> {
}