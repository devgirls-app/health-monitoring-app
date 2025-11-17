package com.devgirls.healthmonitor.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List; // Если решите возвращать рекомендации сразу

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {
    private Long userId;
    private String email;
    private String surname;
    private String name;
    private Integer age;
    private String gender;
    private Double height;
    private Double weight;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}