package com.devgirls.healthmonitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "kafka_logs")
public class KafkaLogs {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "log_id")
    private Long logId;

    @Column(name = "topic_name")
    private String topicName;
    @Column(name = "message_id")
    private String messageId;
    @Column(name = "status")
    private String status;

    @Column(name = "timestamp")
    private LocalDateTime timestamp = LocalDateTime.now();
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
