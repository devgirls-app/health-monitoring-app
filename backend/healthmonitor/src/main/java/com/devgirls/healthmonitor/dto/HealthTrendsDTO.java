package com.devgirls.healthmonitor.dto;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class HealthTrendsDTO {
    private Long trendId;
    private Long userId;
    private Double avgHeartRate;
    private Integer dailySteps;
    private String trendLabel;
    private LocalDate date;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
