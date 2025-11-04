package com.devgirls.healthmonitor.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class HealthDataDTO {
    private Long userId;
    private LocalDateTime timestamp;
    private Integer heartRate;
    private Integer steps;
    private Double calories;
    private Double sleepHours;
    private String source;
}

