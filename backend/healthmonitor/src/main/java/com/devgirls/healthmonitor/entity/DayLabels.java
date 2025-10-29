package com.devgirls.healthmonitor.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name="day_labels",
        uniqueConstraints=@UniqueConstraint(columnNames={"user_id","date"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DayLabels {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "label_id")
    private Long labelId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "date", nullable = false)
    private LocalDate date;

    @Column(name = "stress_label")
    private Short stressLabel;

    @Column(name = "fatigue_label")
    private Short fatigueLabel;

    @Column(name = "note")
    private String note;

    @Column(name = "created_at", insertable=false, updatable=false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private LocalDateTime updatedAt;
}
