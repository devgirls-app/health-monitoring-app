package com.devgirls.healthmonitor.runner;

import com.devgirls.healthmonitor.service.KafkaProducer;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class TestKafkaRunner implements CommandLineRunner {

    private final KafkaProducer producer;

    public TestKafkaRunner(KafkaProducer producer) {
        this.producer = producer;
    }

    @Override
    public void run(String... args) throws Exception {
        producer.sendHealthData("Test health data message");
        producer.sendAlert("Test alert message");
    }
}
