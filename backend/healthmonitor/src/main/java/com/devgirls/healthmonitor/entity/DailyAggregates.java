package com.devgirls.healthmonitor.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "daily_aggregates",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id","date"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyAggregates {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "agg_id")
    private Long aggId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonBackReference
    private User user;

    @Column(name = "date", nullable = false)
    private LocalDate date;

    @Column(name = "steps_total")
    private Integer stepsTotal;

    @Column(name = "calories_total")
    private BigDecimal caloriesTotal;

    @Column(name = "hr_mean")
    private BigDecimal hrMean;

    @Column(name = "hr_max")
    private Integer hrMax;

    @Column(name = "sleep_hours_total")
    private BigDecimal sleepHoursTotal;

    @Column(name = "z_hr_mean")
    private BigDecimal zHrMean;

    @Column(name = "z_steps")
    private BigDecimal zSteps;

    @Column(name = "d_steps_7d")
    private BigDecimal dSteps7d;

    @Column(name = "d_sleep_7d")
    private BigDecimal dSleep7d;

    @Column(name = "created_at", insertable=false, updatable=false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", insertable=false, updatable=false)
    private LocalDateTime updatedAt;
}
