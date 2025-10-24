package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.KafkaLogs;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class KafkaProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final KafkaLogsService logsService;

    public KafkaProducer(KafkaTemplate<String, String> kafkaTemplate, KafkaLogsService logsService) {
        this.kafkaTemplate = kafkaTemplate;
        this.logsService = logsService;
    }

    public void sendHealthData(String message) {
        kafkaTemplate.send("health_data", message);
        saveLog("health_data", "SENT");
    }

    public void sendAlert(String message) {
        kafkaTemplate.send("alerts", message);
        saveLog("alerts", "SENT");
    }

    private void saveLog(String topic, String status) {
        KafkaLogs log = KafkaLogs.builder()
                .topicName(topic)
                .messageId(UUID.randomUUID().toString())
                .status(status)
                .build();
        logsService.save(log);
    }
}