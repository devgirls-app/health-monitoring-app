package com.devgirls.healthmonitor.service;
import com.devgirls.healthmonitor.entity.MLInsights;
import com.devgirls.healthmonitor.repository.MLInsightsRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MLInsightsService {

    private final MLInsightsRepository repo;

    public MLInsightsService(MLInsightsRepository repo) {
        this.repo = repo;
    }

    // ✅ Get all ML insights
    public List<MLInsights> getAll() {
        return repo.findAll();
    }

    // ✅ Get a specific ML insight by ID
    public MLInsights getById(Long id) {
        return repo.findById(id).orElse(null);
    }

    // ✅ Create or update an ML insight
    public MLInsights save(MLInsights insight) {
        return repo.save(insight);
    }

    // ✅ Delete an ML insight by ID
    public void delete(Long id) {
        repo.deleteById(id);
    }
}