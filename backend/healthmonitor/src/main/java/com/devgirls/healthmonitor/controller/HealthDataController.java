package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.UserRepository;
import com.devgirls.healthmonitor.service.HealthDataService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/healthdata")
@CrossOrigin(origins = "*")
public class HealthDataController {

    private final HealthDataService healthDataService;
    private final UserRepository userRepository;

    public HealthDataController(HealthDataService healthDataService, UserRepository userRepository) {
        this.healthDataService = healthDataService;
        this.userRepository = userRepository;
    }

    // GET /healthdata → all records
    @GetMapping
    public List<HealthDataDTO> getAll() {
        return healthDataService.findAll();
    }

    // GET /healthdata/user/{userId} → records for a user
    @GetMapping("/user/{userId}")
    public List<HealthDataDTO> getByUser(@PathVariable Long userId) {
        return healthDataService.findByUserId(userId);
    }

    // POST /healthdata → create new record
    @PostMapping
    public HealthDataDTO create(@RequestBody HealthDataDTO dto) {
        User user = null;
        if (dto.getUserId() != null) {
            user = userRepository.findById(dto.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with id " + dto.getUserId()));
        }

        HealthData data = HealthData.builder()
                .user(user)
                .timestamp(dto.getTimestamp())
                .heartRate(dto.getHeartRate())
                .steps(dto.getSteps())
                .calories(dto.getCalories())
                .sleepHours(dto.getSleepHours())
                .source(dto.getSource())
                .build();


        HealthData saved = healthDataService.save(data);
        return healthDataService.convertToDTO(saved);
    }
}