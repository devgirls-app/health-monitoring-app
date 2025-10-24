package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.MLInsightsDTO;
import com.devgirls.healthmonitor.entity.HealthTrends;
import com.devgirls.healthmonitor.entity.MLInsights;
import com.devgirls.healthmonitor.repository.HealthTrendsRepository;
import com.devgirls.healthmonitor.service.MLInsightsService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/ml-insights")
@CrossOrigin(origins = "*")
public class MLInsightsController {

    private final MLInsightsService service;
    private final HealthTrendsRepository trendsRepo;

    public MLInsightsController(MLInsightsService service, HealthTrendsRepository trendsRepo) {
        this.service = service;
        this.trendsRepo = trendsRepo;
    }

    @GetMapping
    public List<MLInsightsDTO> getAll() {
        return service.getAll().stream().map(this::toDTO).collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    public MLInsightsDTO getById(@PathVariable Long id) {
        MLInsights insight = service.getById(id);
        return (insight != null) ? toDTO(insight) : null;
    }

    @PostMapping
    public MLInsightsDTO create(@RequestBody MLInsightsDTO dto) {
        MLInsights insight = fromDTO(dto);
        return toDTO(service.save(insight));
    }

    @PutMapping("/{id}")
    public MLInsightsDTO update(@PathVariable Long id, @RequestBody MLInsightsDTO dto) {
        MLInsights insight = fromDTO(dto);
        insight.setInsightId(id);
        return toDTO(service.save(insight));
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }

    // ===== Helpers =====

    private MLInsightsDTO toDTO(MLInsights entity) {
        MLInsightsDTO dto = new MLInsightsDTO();
        dto.setInsightId(entity.getInsightId());
        dto.setTrendId(entity.getTrend().getTrendId());
        dto.setPredictionType(entity.getPredictionType());
        dto.setConfidenceScore(entity.getConfidenceScore());
        dto.setResultDescription(entity.getResultDescription());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    private MLInsights fromDTO(MLInsightsDTO dto) {
        HealthTrends trend = trendsRepo.findById(dto.getTrendId())
                .orElseThrow(() -> new IllegalArgumentException("Trend not found with ID: " + dto.getTrendId()));

        return MLInsights.builder()
                .insightId(dto.getInsightId())
                .trend(trend)
                .predictionType(dto.getPredictionType())
                .confidenceScore(dto.getConfidenceScore())
                .resultDescription(dto.getResultDescription())
                .createdAt(dto.getCreatedAt() != null ? dto.getCreatedAt() : java.time.LocalDateTime.now())
                .updatedAt(java.time.LocalDateTime.now())
                .build();
    }
}