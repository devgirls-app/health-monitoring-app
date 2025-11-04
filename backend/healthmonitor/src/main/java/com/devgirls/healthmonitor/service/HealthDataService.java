package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.HealthDataRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class HealthDataService {

    private final HealthDataRepository healthDataRepository;
    private final UserRepository userRepository;
    private final RecommendationEngineService recommendationEngineService;

    public HealthDataService(HealthDataRepository healthDataRepository,
                             UserRepository userRepository,
                             RecommendationEngineService recommendationEngineService) {
        this.healthDataRepository = healthDataRepository;
        this.userRepository = userRepository;
        this.recommendationEngineService = recommendationEngineService;
    }

    // Save health data and trigger recommendation engine
    public HealthData save(HealthData data) {
        // Attach user entity if userId is provided
        if (data.getUser() != null && data.getUser().getUserId() != null) {
            User user = userRepository.findById(data.getUser().getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with id " + data.getUser().getUserId()));
            data.setUser(user);
        }

        HealthData saved = healthDataRepository.save(data);

        // Trigger recommendation engine
        recommendationEngineService.analyzeAndGenerate(saved);

        return saved;
    }

    // Fetch all health data and convert to DTO
    public List<HealthDataDTO> findAll() {
        return healthDataRepository.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Convert entity to DTO
    public HealthDataDTO convertToDTO(HealthData data) {
        return HealthDataDTO.builder()
                .userId(data.getUser() != null ? data.getUser().getUserId() : null)
                .timestamp(data.getTimestamp())
                .heartRate(data.getHeartRate())
                .steps(data.getSteps())
                .calories(data.getCalories() != null ? data.getCalories().doubleValue() : null)
                .sleepHours(data.getSleepHours() != null ? data.getSleepHours().doubleValue() : null)
                .source(data.getSource())
                .build();
    }

    // Fetch by user
    public List<HealthDataDTO> findByUserId(Long userId) {
        return healthDataRepository.findAllByUser_UserId(userId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
}
