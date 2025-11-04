package com.devgirls.healthmonitor.runner;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.kafka.producer.HealthDataProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class TestKafkaRunner implements CommandLineRunner {

    private final HealthDataProducer producer;
    private final ObjectMapper objectMapper;

    public TestKafkaRunner(HealthDataProducer producer, ObjectMapper objectMapper) {
        this.producer = producer;
        this.objectMapper = objectMapper;
    }

    @Override
    public void run(String... args) throws Exception {
        HealthDataDTO dto = HealthDataDTO.builder()
                .userId(1L) // use a valid user ID from your DB
                .timestamp(LocalDateTime.now())
                .heartRate(85)
                .steps(5000)
                .calories(2200.0)
                .sleepHours(7.0)
                .source("TestRunner")
                .build();

        String json = objectMapper.writeValueAsString(dto);

        producer.sendHealthData(json);
    }
}