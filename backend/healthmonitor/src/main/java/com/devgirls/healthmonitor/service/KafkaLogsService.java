package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.KafkaLogs;
import com.devgirls.healthmonitor.repository.KafkaLogsRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class KafkaLogsService {

    private final KafkaLogsRepository repo;

    public KafkaLogsService(KafkaLogsRepository repo) {
        this.repo = repo;
    }

    public List<KafkaLogs> getAll() {
        return repo.findAll();
    }

    public KafkaLogs getById(Long id) {
        return repo.findById(id).orElse(null);
    }

    public KafkaLogs save(KafkaLogs log) {
        return repo.save(log);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }
}