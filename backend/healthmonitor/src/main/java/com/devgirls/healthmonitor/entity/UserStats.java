package com.devgirls.healthmonitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name="user_stats")
public class UserStats {
    @Id
    @Column(name = "user_id")
    private Long userId;

    @OneToOne(optional = false) @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "hr_mean_baseline")
    private BigDecimal hrMeanBaseline;

    @Column(name = "hr_mean_std")
    private BigDecimal hrMeanStd;

    @Column(name = "steps_baseline")
    private BigDecimal stepsBaseline;

    @Column(name = "steps_std")
    private BigDecimal stepsStd;

    @Column(name = "updated_at", insertable=false, updatable=false)
    private LocalDateTime updatedAt;
}

