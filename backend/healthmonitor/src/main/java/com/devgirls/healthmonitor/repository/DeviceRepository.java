package com.devgirls.healthmonitor.repository;

import com.devgirls.healthmonitor.entity.Device;
import com.devgirls.healthmonitor.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DeviceRepository extends JpaRepository<Device, Long> {
    List<Device> findByUser(User user);
    List<Device> findByUserId(Long userId);
}