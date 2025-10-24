package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.entity.KafkaLogs;
import com.devgirls.healthmonitor.service.KafkaLogsService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/kafka-logs")
@CrossOrigin(origins = "*")
public class KafkaLogsController {

    private final KafkaLogsService service;

    public KafkaLogsController(KafkaLogsService service) {
        this.service = service;
    }

    @GetMapping
    public List<KafkaLogs> getAll() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    public KafkaLogs getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PostMapping
    public KafkaLogs create(@RequestBody KafkaLogs log) {
        return service.save(log);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}