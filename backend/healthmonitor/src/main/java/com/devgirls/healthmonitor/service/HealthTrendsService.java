package com.devgirls.healthmonitor.service;
import com.devgirls.healthmonitor.entity.HealthTrends;
import com.devgirls.healthmonitor.repository.HealthTrendsRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class HealthTrendsService {

    private final HealthTrendsRepository repo;

    public HealthTrendsService(HealthTrendsRepository repo) {
        this.repo = repo;
    }

    // ✅ Get all health trends
    public List<HealthTrends> getAll() {
        return repo.findAll();
    }

    // ✅ Get a specific trend by ID
    public HealthTrends getById(Long id) {
        return repo.findById(id).orElse(null);
    }

    // ✅ Create or update a health trend
    public HealthTrends save(HealthTrends trend) {
        return repo.save(trend);
    }

    // ✅ Delete a trend by ID
    public void delete(Long id) {
        repo.deleteById(id);
    }
}