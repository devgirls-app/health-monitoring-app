package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // --- МЕТОДЫ ДЛЯ АВТОРИЗАЦИИ (ОБЯЗАТЕЛЬНО ДОБАВИТЬ) ---

    // Используется в AuthService.login и AuthService.requestPasswordReset
    // Spring Data JPA сам сгенерирует SQL запрос: SELECT * FROM users WHERE email = ?
    Optional<User> findByEmail(String email);

    // Используется в AuthService.register, чтобы проверить уникальность
    // SQL: SELECT count(*) > 0 FROM users WHERE email = ?
    boolean existsByEmail(String email);


    // --- ВАШИ СЛОЖНЫЕ ЗАПРОСЫ (ОСТАВЛЯЕМ КАК ЕСТЬ) ---

    // РЕШЕНИЕ ДЛЯ 'findById' (используйте для экрана профиля)
    @Query("SELECT u FROM User u " +
            "LEFT JOIN FETCH u.devices " +
            "LEFT JOIN FETCH u.healthData " +
            "LEFT JOIN FETCH u.healthTrends ht " +
            "LEFT JOIN FETCH ht.mlInsights " +
            "LEFT JOIN FETCH u.recommendations " +
            "WHERE u.userId = :id")
    Optional<User> findByIdWithDetails(@Param("id") Long id);


    // РЕШЕНИЕ ДЛЯ 'findAll'
    @Query("SELECT DISTINCT u FROM User u " +
            "LEFT JOIN FETCH u.devices " +
            "LEFT JOIN FETCH u.healthData " +
            "LEFT JOIN FETCH u.healthTrends ht " +
            "LEFT JOIN FETCH ht.mlInsights " +
            "LEFT JOIN FETCH u.recommendations")
    List<User> findAllWithDetails();
}