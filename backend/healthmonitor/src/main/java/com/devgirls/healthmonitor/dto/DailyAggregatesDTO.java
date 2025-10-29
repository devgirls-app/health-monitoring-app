package com.devgirls.healthmonitor.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
public class DailyAggregatesDTO {
    private Long aggId;
    private Long userId;
    private LocalDate date;
    private Integer stepsTotal;
    private BigDecimal caloriesTotal;
    private BigDecimal hrMean;
    private Integer hrMax;
    private BigDecimal sleepHoursTotal;
}

