package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.DailyAggregatesDTO;
import com.devgirls.healthmonitor.entity.DailyAggregates;
import com.devgirls.healthmonitor.repository.DailyAggregatesRepository;
import com.devgirls.healthmonitor.service.AggregationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;

@RestController
@RequestMapping("/aggregates")
@RequiredArgsConstructor
public class AggregatesController {
    private final AggregationService aggSvc;
    private final DailyAggregatesRepository repo;

    @PostMapping("/rebuild/{userId}")
    public ResponseEntity<?> rebuildToday(@PathVariable Long userId) {
        var saved = aggSvc.aggregateDay(userId, LocalDate.now(ZoneOffset.UTC));
        return ResponseEntity.ok(saved);
    }

    @PostMapping("/run/{userId}/{date}")
    public ResponseEntity<?> run(@PathVariable Long userId, @PathVariable LocalDate date) {
        DailyAggregates entity = aggSvc.aggregateDay(userId, date);
        DailyAggregatesDTO dto = aggSvc.convertToDTO(entity);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/{userId}/{date}")
    public ResponseEntity<?> getOne(@PathVariable Long userId, @PathVariable LocalDate date) {
        return aggSvc.findExistingDto(userId, date)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(404)
                        .body("Daily aggregate not found for userId=" + userId + ", date=" + date));
    }

    @GetMapping("/{userId}")
    public List<DailyAggregates> list(@PathVariable Long userId,
                                      @RequestParam LocalDate from,
                                      @RequestParam LocalDate to) {
        return repo.findRange(userId, from, to);
    }
}