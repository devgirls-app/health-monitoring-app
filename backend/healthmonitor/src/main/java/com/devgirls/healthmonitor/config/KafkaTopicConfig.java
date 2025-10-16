package com.devgirls.healthmonitor.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class KafkaTopicConfig {
    @Bean
    public NewTopic healthDataTopic() {
        return new NewTopic("health_data", 1, (short) 1);
    }

    @Bean
    public NewTopic alertsTopic() {
        return new NewTopic("alerts", 1, (short) 1);
    }
}