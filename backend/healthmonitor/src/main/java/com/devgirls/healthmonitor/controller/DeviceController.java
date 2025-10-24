package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.DeviceDTO;
import com.devgirls.healthmonitor.entity.Device;
import com.devgirls.healthmonitor.service.DeviceService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/devices")
@CrossOrigin(origins = "*")

public class DeviceController {
    private final DeviceService service;
    public DeviceController(DeviceService service) {
        this.service = service;
    }

    @GetMapping
    public List<DeviceDTO> getAll() {
        List<Device> entities = service.getAll();
        return service.toDTOList(entities);
    }

    @GetMapping("/{id}")
    public Device getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PostMapping
    public DeviceDTO create(@RequestBody DeviceDTO dto) {
        Device device = service.fromDTO(dto);
        return service.toDTO(service.save(device));
    }

    @PutMapping("/{id}")
    public DeviceDTO update(@PathVariable Long id, @RequestBody DeviceDTO dto) {
        Device device = service.fromDTO(dto);
        device.setDeviceId(id);
        return service.toDTO(service.save(device));
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }

    @GetMapping("/byUser/{userId}")
    public List<DeviceDTO> getDevicesByUserId(@PathVariable Long userId) {
        List<Device> userDevices = service.findByUserId(userId);
        return service.toDTOList(userDevices);
    }
}