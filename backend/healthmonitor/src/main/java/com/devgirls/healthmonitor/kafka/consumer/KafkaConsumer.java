package com.devgirls.healthmonitor.service;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumer {

    @KafkaListener(topics = "health_data", groupId = "health-group")
    public void consumeHealthData(String message) {
        System.out.println("Received health_data: " + message);
    }

    @KafkaListener(topics = "alerts", groupId = "health-group")
    public void consumeAlerts(String message) {
        System.out.println("Received alert: " + message);
    }
}
