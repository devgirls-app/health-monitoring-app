package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.DeviceDTO;
import com.devgirls.healthmonitor.entity.Device;
import com.devgirls.healthmonitor.entity.User; // <-- ИМПОРТ
import com.devgirls.healthmonitor.repository.DeviceRepository;
import com.devgirls.healthmonitor.repository.UserRepository; // <-- ИМПОРТ
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class DeviceService {

    private final DeviceRepository repo;
    private final UserRepository userRepository;

    public DeviceService(DeviceRepository repo, UserRepository userRepository) {
        this.repo = repo;
        this.userRepository = userRepository;
    }

    public List<Device> getAll() {
        return repo.findAll();
    }

    public Device getById(Long id) {
        return repo.findById(id).orElse(null);
    }

    public Device save(Device device) {
        return repo.save(device);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }

    /**
     * Находит все устройства для конкретного пользователя.
     * @param userId ID пользователя
     * @return Список (List) сущностей Device
     */
    public List<Device> findByUserId(Long userId) {
        return repo.findByUserId(userId);
    }

    public Device fromDTO(DeviceDTO dto) {
        Device device = new Device();
        device.setDeviceId(dto.getDeviceId());

        if (dto.getUserId() != null) {
            User user = userRepository.findById(dto.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with id: " + dto.getUserId()));
            device.setUser(user);
        }

        device.setType(dto.getType());
        device.setOsVersion(dto.getOsVersion());
        return device;
    }

    public DeviceDTO toDTO(Device device) {
        DeviceDTO dto = new DeviceDTO();
        dto.setDeviceId(device.getDeviceId());
        if (device.getUser() != null) {
            dto.setUserId(device.getUser().getUserId());
        }
        dto.setType(device.getType());
        dto.setOsVersion(device.getOsVersion());
        dto.setCreatedAt(device.getCreatedAt());
        dto.setUpdatedAt(device.getUpdatedAt());
        return dto;
    }
    public List<DeviceDTO> toDTOList(List<Device> devices) {
        return devices.stream().map(this::toDTO).collect(Collectors.toList());
    }
}