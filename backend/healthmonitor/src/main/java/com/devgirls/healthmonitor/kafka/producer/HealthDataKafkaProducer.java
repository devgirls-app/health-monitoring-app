package com.devgirls.healthmonitor.kafka.producer;

import com.devgirls.healthmonitor.entity.KafkaLogs;
import com.devgirls.healthmonitor.service.KafkaLogsService;
import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HealthDataKafkaProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final KafkaLogsService logsService;

    public void sendHealthData(String data) {
        sendAndLog("health_data", data);
    }

    private void sendAndLog(String topic, String message) {
        kafkaTemplate.send(topic, message).whenComplete((result, ex) -> {
            KafkaLogs log = KafkaLogs.builder()
                    .topicName(topic)
                    .messageId(UUID.randomUUID().toString())
                    .build();

            if (ex == null) {
                log.setStatus("SUCCESS");
                log.setTimestamp(LocalDateTime.now());
            } else {
                log.setStatus("FAILED");
                log.setTimestamp(LocalDateTime.now());
            }
            logsService.save(log);
        });
    }
}