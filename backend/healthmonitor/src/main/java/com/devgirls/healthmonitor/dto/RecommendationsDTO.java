package com.devgirls.healthmonitor.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class RecommendationsDTO {
    private Long recId;
    private String recommendationText;
    private String source;
    private Long userId;
    private String severity;
    private LocalDateTime createdAt;
}