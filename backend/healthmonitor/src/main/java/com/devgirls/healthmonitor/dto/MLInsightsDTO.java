package com.devgirls.healthmonitor.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class MLInsightsDTO {
    private Long insightId;
    private Long trendId;
    private String predictionType;
    private Double confidenceScore;
    private String resultDescription;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}