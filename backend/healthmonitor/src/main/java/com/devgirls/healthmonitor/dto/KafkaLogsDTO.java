package com.devgirls.healthmonitor.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class KafkaLogsDTO {
    private Long logId;
    private String topicName;
    private String messageId;
    private LocalDateTime timestamp;
    private String status;
    private LocalDateTime createdAt;
}