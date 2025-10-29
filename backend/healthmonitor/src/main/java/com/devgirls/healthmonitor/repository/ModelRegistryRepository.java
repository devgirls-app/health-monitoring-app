package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.ModelRegistry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ModelRegistryRepository extends JpaRepository<ModelRegistry, Long> {
    Optional<com.devgirls.healthmonitor.entity.ModelRegistry> findFirstByNameAndIsActiveTrue(String name);
}
