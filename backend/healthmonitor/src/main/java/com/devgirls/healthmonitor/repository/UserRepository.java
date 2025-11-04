package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    // --- РЕШЕНИЕ ДЛЯ 'findById' ---
    @Query("SELECT u FROM User u " +
            "LEFT JOIN FETCH u.devices " +
            "LEFT JOIN FETCH u.healthData " +
            "LEFT JOIN FETCH u.healthTrends ht " +
            "LEFT JOIN FETCH ht.mlInsights " + // Вложенный JOIN FETCH
            "LEFT JOIN FETCH u.recommendations " +
            "WHERE u.userId = :id")
    Optional<User> findByIdWithDetails(@Param("id") Long id);


    // --- РЕШЕНИЕ ДЛЯ 'findAll' ---
    @Query("SELECT DISTINCT u FROM User u " + // DISTINCT важен
            "LEFT JOIN FETCH u.devices " +
            "LEFT JOIN FETCH u.healthData " +
            "LEFT JOIN FETCH u.healthTrends ht " +
            "LEFT JOIN FETCH ht.mlInsights " +
            "LEFT JOIN FETCH u.recommendations")
    List<User> findAllWithDetails();
}