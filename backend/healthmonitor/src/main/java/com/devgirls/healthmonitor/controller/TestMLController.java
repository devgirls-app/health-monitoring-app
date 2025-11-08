// TestMLController.java
package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.entity.DailyAggregates;
import com.devgirls.healthmonitor.repository.DailyAggregatesRepository;
import com.devgirls.healthmonitor.service.MLInferenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/ml-test")
@RequiredArgsConstructor
public class TestMLController {

    private final DailyAggregatesRepository dailyAggregatesRepository;
    private final MLInferenceService mlInferenceService;

    @GetMapping("/fatigue/{aggId}")
    public ResponseEntity<?> testFatigue(@PathVariable Long aggId) throws Exception {
        DailyAggregates agg = dailyAggregatesRepository.findById(aggId)
                .orElseThrow(() -> new IllegalArgumentException("Aggregate not found: " + aggId));

        double prob = mlInferenceService.predictFatigue(agg);

        return ResponseEntity.ok(
                Map.of(
                        "aggId", aggId,
                        "userId", agg.getUserId(),
                        "probability", prob
                )
        );
    }
}