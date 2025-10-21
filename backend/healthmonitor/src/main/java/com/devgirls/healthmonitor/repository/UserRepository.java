package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {}

