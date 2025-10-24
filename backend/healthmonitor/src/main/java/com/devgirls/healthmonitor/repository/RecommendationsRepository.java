package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.Recommendations;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecommendationsRepository extends JpaRepository<Recommendations, Long> {

    // ✅ Custom query methods if needed
    List<Recommendations> findByUserId(Long userId);

    List<Recommendations> findBySource(String source);
}
