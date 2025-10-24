package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.RecommendationsDTO;
import com.devgirls.healthmonitor.entity.Recommendations;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.RecommendationsRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RecommendationsService {

    private final RecommendationsRepository repo;
    private final UserRepository userRepository;

    public RecommendationsService(RecommendationsRepository repo, UserRepository userRepository) {
        this.repo = repo;
        this.userRepository = userRepository;
    }

    public List<Recommendations> getAll() {
        return repo.findAll();
    }

    public Recommendations getById(Long id) {
        return repo.findById(id).orElse(null);
    }

    public Recommendations save(Recommendations recommendation) {
        return repo.save(recommendation);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }

    public Recommendations fromDTO(RecommendationsDTO dto) {
        Recommendations rec = new Recommendations();
        // Always ignore recId for new records
        rec.setRecommendationText(dto.getRecText());
        rec.setSource(dto.getSource());

        if (dto.getUserId() != null) {
            User user = userRepository.findById(dto.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with id " + dto.getUserId()));
            rec.setUser(user);
        } else {
            throw new RuntimeException("UserId is required");
        }

        return rec;
    }

    public RecommendationsDTO toDTO(Recommendations rec) {
        RecommendationsDTO dto = new RecommendationsDTO();
        dto.setRecId(rec.getRecId());
        dto.setRecText(rec.getRecommendationText());
        dto.setSource(rec.getSource());
        dto.setTimestamp(rec.getCreatedAt());

        if (rec.getUser() != null) {
            dto.setUserId(rec.getUser().getUserId());
        }

        return dto;
    }

    public List<RecommendationsDTO> toDTOList(List<Recommendations> list) {
        return list.stream().map(this::toDTO).collect(Collectors.toList());
    }
}