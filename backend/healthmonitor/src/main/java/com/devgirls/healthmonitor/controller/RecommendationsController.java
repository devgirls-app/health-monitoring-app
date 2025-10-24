package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.RecommendationsDTO;
import com.devgirls.healthmonitor.entity.Recommendations;
import com.devgirls.healthmonitor.service.RecommendationsService;
import com.devgirls.healthmonitor.service.UserService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/recommendations")
@CrossOrigin(origins = "*")
public class RecommendationsController {

    private final RecommendationsService service;
    private final UserService userService;

    public RecommendationsController(RecommendationsService service, UserService userService) {
        this.service = service;
        this.userService = userService;
    }

    @GetMapping
    public List<RecommendationsDTO> getAll() {
        return service.toDTOList(service.getAll());
    }

    @GetMapping("/{id}")
    public RecommendationsDTO getById(@PathVariable Long id) {
        Recommendations rec = service.getById(id);
        return rec != null ? service.toDTO(rec) : null;
    }

    @PostMapping
    public RecommendationsDTO create(@RequestBody RecommendationsDTO dto) {
        Recommendations rec = service.fromDTO(dto);
        return service.toDTO(service.save(rec));
    }

    @PutMapping("/{id}")
    public RecommendationsDTO update(@PathVariable Long id, @RequestBody RecommendationsDTO dto) {
        Recommendations rec = service.fromDTO(dto);
        rec.setRecId(id);
        return service.toDTO(service.save(rec));
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}