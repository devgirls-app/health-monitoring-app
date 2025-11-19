package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.UserRepository;
import com.devgirls.healthmonitor.service.AggregationService; // <--- 1. Импорт
import com.devgirls.healthmonitor.service.HealthDataService;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/healthdata")
@CrossOrigin(origins = "*")
public class HealthDataController {

    private final HealthDataService healthDataService;
    private final UserRepository userRepository;
    private final AggregationService aggregationService;

    public HealthDataController(HealthDataService healthDataService,
                                UserRepository userRepository,
                                AggregationService aggregationService) {
        this.healthDataService = healthDataService;
        this.userRepository = userRepository;
        this.aggregationService = aggregationService;
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
}