package com.devgirls.healthmonitor.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeviceDTO {
    private Long deviceId;
    private Long userId;
    private String type;
    private String osVersion;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

