package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.HealthDataRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
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
        // 1. Get user
        if (data.getUser() != null && data.getUser().getUserId() != null) {
            User user = userRepository.findById(data.getUser().getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with id " + data.getUser().getUserId()));
            data.setUser(user);
        } else {
            throw new RuntimeException("User must be set on HealthData");
        }

        if (data.getTimestamp() == null) {
            throw new RuntimeException("Timestamp must be set on HealthData");
        }

        // 2. Find day
        LocalDate day = data.getTimestamp().toLocalDate();
        data.setDay(day);

        // 3. Find existed data for the day + source
        String source = data.getSource();
        if (source == null) {
            source = "unknown";
            data.setSource(source);
        }

        var existingOpt = healthDataRepository.findFirstByUser_UserIdAndDayAndSource(
                data.getUser().getUserId(),
                day,
                source
        );

        HealthData toSave;
        if (existingOpt.isPresent()) {
            // ---- UPDATE ----
            HealthData existing = existingOpt.get();
            existing.setTimestamp(data.getTimestamp());
            existing.setHeartRate(data.getHeartRate());
            existing.setSteps(data.getSteps());
            existing.setCalories(data.getCalories());
            existing.setSleepHours(data.getSleepHours());
            existing.setUpdatedAt(LocalDateTime.now());
            toSave = existing;
        } else {
            data.setCreatedAt(LocalDateTime.now());
            data.setUpdatedAt(LocalDateTime.now());
            toSave = data;
        }

        HealthData saved = healthDataRepository.save(toSave);

        // 4. Recommendations
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
