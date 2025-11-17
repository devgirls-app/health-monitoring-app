package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.UserDTO;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public UserDTO getUserProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        return mapToDTO(user);
    }


    @Transactional
    public UserDTO updateUserProfile(Long userId, UserDTO dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));


        if (dto.getAge() != null) user.setAge(dto.getAge());
        if (dto.getGender() != null) user.setGender(dto.getGender());
        if (dto.getHeight() != null) user.setHeight(BigDecimal.valueOf(dto.getHeight()));
        if (dto.getWeight() != null) user.setWeight(BigDecimal.valueOf(dto.getWeight()));

        User savedUser = userRepository.save(user);
        return mapToDTO(savedUser);
    }

    private UserDTO mapToDTO(User user) {
        return UserDTO.builder()
                .userId(user.getUserId())
                .email(user.getEmail())
                .name(user.getName())
                .surname(user.getSurname())
                .age(user.getAge())
                .gender(user.getGender())
                .height(user.getHeight() != null ? user.getHeight().doubleValue() : null)
                .weight(user.getWeight() != null ? user.getWeight().doubleValue() : null)
                .createdAt(user.getCreatedAt())
                .build();
    }
}