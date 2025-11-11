package com.devgirls.healthmonitor.kafka.producer;

import com.devgirls.healthmonitor.entity.KafkaLogs;
import com.devgirls.healthmonitor.service.KafkaLogsService;
import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HealthDataProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final KafkaLogsService logsService;

    public void sendHealthData(String data) {
        sendAndLog("health_data", data);
    }

    public void sendAlert(String data) {
        sendAndLog("alerts", data);
    }

    private void sendAndLog(String topic, String message) {
        kafkaTemplate.send(topic, message);

        KafkaLogs log = KafkaLogs.builder()
                .topicName(topic)
                .messageId(UUID.randomUUID().toString())
                .status("SENT")
                .build();

        logsService.save(log);
    }
}