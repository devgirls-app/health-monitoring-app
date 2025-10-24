package com.devgirls.healthmonitor.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class UserDTO {
    private Long userId;
    private String name;
    private Integer age;
    private String gender;
    private Double height;
    private Double weight;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}