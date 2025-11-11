package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.service.WeeklySummaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/ml-test")
@RequiredArgsConstructor
public class WeeklySummaryController {

    private final WeeklySummaryService weeklySummaryService;

    /**
     * Example: POST /ml-test/weekly-fatigue/2/2025-11-10
     * weekEnd = 2025-11-10 → analyze 2025-11-04 ... 2025-11-10
     */
    @PostMapping("/weekly-fatigue/{userId}/{weekEnd}")
    public ResponseEntity<?> generateWeeklySummary(
            @PathVariable Long userId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekEnd
    ) {
        String text = weeklySummaryService.generateWeeklyFatigueSummary(userId, weekEnd);
        return ResponseEntity.ok(
                Map.of(
                        "userId", userId,
                        "weekEnd", weekEnd,
                        "message", text
                )
        );
    }
}