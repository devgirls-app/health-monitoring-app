package com.devgirls.healthmonitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name="model_registry",
        uniqueConstraints=@UniqueConstraint(columnNames={"name","version"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ModelRegistry {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "model_id")
    private Long modelId;

    @Column(name = "name", nullable = false)
    private String name;     // e.g. stress_level

    @Column(name = "version", nullable = false)
    private String version;  // e.g. v1

    @Column(name = "path", nullable = false)
    private String path;     // e.g. s3://...

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "created_at", insertable=false, updatable=false)
    private LocalDateTime createdAt;
}
