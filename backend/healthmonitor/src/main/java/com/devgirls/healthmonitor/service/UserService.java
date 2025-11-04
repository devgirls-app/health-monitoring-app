package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class UserService {

    private final UserRepository repo;

    public UserService(UserRepository repo) {
        this.repo = repo;
    }

    public List<User> getAll() {
        return repo.findAllWithDetails(); // <-- ИЗМЕНЕНО
    }

    public User getById(Long id) {
        return repo.findByIdWithDetails(id).orElse(null); // <-- ИЗМЕНЕНО
    }

    public User save(User user) {
        return repo.save(user);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }

    public User update(Long id, User updatedUser) {
        // Используем findByIdWithDetails, чтобы избежать N+1 при обновлении
        User existing = repo.findByIdWithDetails(id).orElse(null); // <-- ИЗМЕНЕНО
        if (existing == null) return null;

        existing.setName(updatedUser.getName());
        existing.setAge(updatedUser.getAge());
        existing.setGender(updatedUser.getGender());
        existing.setHeight(updatedUser.getHeight());
        existing.setWeight(updatedUser.getWeight());
        existing.setUpdatedAt(java.time.LocalDateTime.now());

        return repo.save(existing);
    }
}