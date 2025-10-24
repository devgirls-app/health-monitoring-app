package com.devgirls.healthmonitor.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "Recommendations")
public class Recommendations {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long recId;

    @Column(name = "recommendation_text")
    private String recommendationText;

    private String source;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @JsonBackReference
    private User user;
}