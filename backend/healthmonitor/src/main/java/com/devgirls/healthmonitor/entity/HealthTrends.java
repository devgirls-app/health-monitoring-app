package com.devgirls.healthmonitor.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthTrends {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long trendId;

    private Double avgHeartRate;
    private Integer dailySteps;
    private String trendLabel;
    private LocalDate date;

    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    @JsonBackReference
    private User user;

    @OneToMany(mappedBy = "trend", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private Set<MLInsights> mlInsights;
}