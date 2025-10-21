package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.repository.HealthDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service class for handling business logic related to health data.
 */
@Service
public class HealthDataService {

    private final HealthDataRepository healthDataRepository;

    @Autowired
    public HealthDataService(HealthDataRepository healthDataRepository) {
        this.healthDataRepository = healthDataRepository;
    }

    /**
     * Fetches all health data records from the database and converts them to DTOs.
     * @return A list of HealthDataDTO objects.
     */
    public List<HealthDataDTO> findAllHealthData() {
        return healthDataRepository.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Converts a HealthData entity to a HealthDataDTO.
     * @param healthData The entity to convert.
     * @return The resulting DTO.
     */
    private HealthDataDTO convertToDTO(HealthData healthData) {
        return HealthDataDTO.builder()
                .userId(healthData.getUser() != null ? healthData.getUser().getId() : null)
                .timestamp(healthData.getTimestamp())
                .heartRate(healthData.getHeartRate())
                .steps(healthData.getSteps())
                .calories(healthData.getCalories())
                .sleepHours(healthData.getSleepHours())
                .source(healthData.getSource())
                .build();
    }
}
