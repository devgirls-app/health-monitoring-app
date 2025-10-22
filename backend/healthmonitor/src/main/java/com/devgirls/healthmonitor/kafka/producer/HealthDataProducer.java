package com.devgirls.healthmonitor.kafka.producer;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class HealthDataProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;

    public HealthDataProducer(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void sendHealthData(String data) {
        kafkaTemplate.send("health_data", data);
    }
}
