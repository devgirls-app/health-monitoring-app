package com.devgirls.healthmonitor.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthDataDTO {
    private Long userId;
    private LocalDateTime timestamp;
    private Integer heartRate;
    private Integer steps;
    private Double calories;
    private Double sleepHours;
    private String source;
}

