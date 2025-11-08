package com.devgirls.healthmonitor.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "ml_insights")
public class MLInsights {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "insight_id")
    private Long insightId;

    @Column(name = "prediction_type")
    private String predictionType;
    @Column(name = "confidence_score")
    private BigDecimal confidenceScore;
    @Column(name = "result_description")
    private String resultDescription;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @ManyToOne
    @JoinColumn(name = "trend_id", nullable = true)
    @JsonBackReference
    private HealthTrends trend;

    @ManyToOne
    @JoinColumn(name = "agg_id")
    private DailyAggregates aggregate;

    @Column(name = "probability")
    private java.math.BigDecimal probability;

    @ManyToOne
    @JoinColumn(name = "model_id")
    private ModelRegistry model;
}