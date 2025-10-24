package com.devgirls.healthmonitor.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class RecommendationsDTO {

    private Long recId;
    private String recText;
    private String source;
    private Long userId;

    private LocalDateTime timestamp;
}