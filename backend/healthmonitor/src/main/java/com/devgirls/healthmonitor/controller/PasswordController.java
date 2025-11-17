package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.*;
import com.devgirls.healthmonitor.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/password")
@RequiredArgsConstructor
public class PasswordController {

    private final AuthService authService;

    @PostMapping("/request-reset")
    public ResponseEntity<?> requestReset(@RequestBody ForgotPasswordRequest request) {
        try {
            authService.requestPasswordReset(request.getEmail());
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            // В целях безопасности часто возвращают 200, даже если email не найден,
            // но для отладки оставим badRequest
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/reset")
    public ResponseEntity<?> resetPassword(@RequestBody ResetPasswordRequest request) {
        try {
            authService.resetPassword(request.getToken(), request.getNewPassword());
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
