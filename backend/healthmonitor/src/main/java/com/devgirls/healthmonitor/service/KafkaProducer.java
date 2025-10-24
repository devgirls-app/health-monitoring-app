package com.devgirls.healthmonitor.service;

<<<<<<< HEAD
import com.devgirls.healthmonitor.entity.KafkaLogs;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;

=======
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

>>>>>>> origin/ios-full-restore
@Service
public class KafkaProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;
<<<<<<< HEAD
    private final KafkaLogsService logsService;

    public KafkaProducer(KafkaTemplate<String, String> kafkaTemplate, KafkaLogsService logsService) {
        this.kafkaTemplate = kafkaTemplate;
        this.logsService = logsService;
=======

    public KafkaProducer(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
>>>>>>> origin/ios-full-restore
    }

    public void sendHealthData(String message) {
        kafkaTemplate.send("health_data", message);
<<<<<<< HEAD
        saveLog("health_data", "SENT");
=======
>>>>>>> origin/ios-full-restore
    }

    public void sendAlert(String message) {
        kafkaTemplate.send("alerts", message);
<<<<<<< HEAD
        saveLog("alerts", "SENT");
    }

    private void saveLog(String topic, String status) {
        KafkaLogs log = KafkaLogs.builder()
                .topicName(topic)
                .messageId(UUID.randomUUID().toString())
                .status(status)
                .build();
        logsService.save(log);
=======
>>>>>>> origin/ios-full-restore
    }
}