package com.devgirls.healthmonitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KafkaLogs {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long logId;

    private String topicName;
    private String messageId;
    private String status;

    private LocalDateTime timestamp = LocalDateTime.now();
    private LocalDateTime createdAt = LocalDateTime.now();
}
