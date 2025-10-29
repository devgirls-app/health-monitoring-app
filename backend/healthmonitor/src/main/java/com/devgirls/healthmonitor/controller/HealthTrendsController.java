package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.HealthTrendsDTO;
import com.devgirls.healthmonitor.entity.HealthTrends;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.UserRepository;
import com.devgirls.healthmonitor.service.HealthTrendsService;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/health-trends")
@CrossOrigin(origins = "*")
public class HealthTrendsController {

    private final HealthTrendsService service;
    private final UserRepository userRepo;

    public HealthTrendsController(HealthTrendsService service, UserRepository userRepo) {
        this.service = service;
        this.userRepo = userRepo;
    }

    // ===== CRUD API =====

    @GetMapping
    public List<HealthTrendsDTO> getAll() {
        return service.getAll().stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    public HealthTrendsDTO getById(@PathVariable Long id) {
        HealthTrends trend = service.getById(id);
        return (trend != null) ? toDTO(trend) : null;
    }

    @PostMapping
    public HealthTrendsDTO create(@RequestBody HealthTrendsDTO dto) {
        HealthTrends trend = fromDTO(dto);
        return toDTO(service.save(trend));
    }

    @PutMapping("/{id}")
    public HealthTrendsDTO update(@PathVariable Long id, @RequestBody HealthTrendsDTO dto) {
        HealthTrends trend = fromDTO(dto);
        trend.setTrendId(id);
        return toDTO(service.save(trend));
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }

    // ===== Helper conversion methods =====

    private HealthTrendsDTO toDTO(HealthTrends entity) {
        HealthTrendsDTO dto = new HealthTrendsDTO();
        dto.setTrendId(entity.getTrendId());
        dto.setUserId(entity.getUser().getUserId());
        dto.setAvgHeartRate(entity.getAvgHeartRate() != null ? entity.getAvgHeartRate().doubleValue() : null);
        dto.setDailySteps(entity.getDailySteps());
        dto.setTrendLabel(entity.getTrendLabel());
        dto.setDate(entity.getDate());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    private HealthTrends fromDTO(HealthTrendsDTO dto) {
        User user = userRepo.findById(dto.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("User not found with ID: " + dto.getUserId()));

        return HealthTrends.builder()
                .trendId(dto.getTrendId())
                .user(user)
                .avgHeartRate(dto.getAvgHeartRate() != null ? BigDecimal.valueOf(dto.getAvgHeartRate()) : null)
                .dailySteps(dto.getDailySteps())
                .trendLabel(dto.getTrendLabel())
                .date(dto.getDate())
                .createdAt(dto.getCreatedAt() != null ? dto.getCreatedAt() : java.time.LocalDateTime.now())
                .updatedAt(java.time.LocalDateTime.now())
                .build();
    }
}
