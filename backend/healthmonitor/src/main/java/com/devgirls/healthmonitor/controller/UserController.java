package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.UserDTO;
import com.devgirls.healthmonitor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
//@CrossOrigin(origins = "*")
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getById(@PathVariable Long id) {
        UserDTO userDTO = userService.getUserProfile(id);
        return ResponseEntity.ok(userDTO);
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> update(@PathVariable Long id, @RequestBody UserDTO userDTO) {
        UserDTO updatedUser = userService.updateUserProfile(id, userDTO);
        return ResponseEntity.ok(updatedUser);
    }
}