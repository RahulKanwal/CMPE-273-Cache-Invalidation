package com.eds.user.controller;

import com.eds.user.model.*;
import com.eds.user.service.JwtService;
import com.eds.user.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    
    private final UserService userService;
    private final JwtService jwtService;

    public AuthController(UserService userService, JwtService jwtService) {
        this.userService = userService;
        this.jwtService = jwtService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            User user = userService.registerUser(request);
            String token = jwtService.generateToken(user.getEmail(), user.getRole().toString());
            return ResponseEntity.ok(new AuthResponse(token, user));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        Optional<User> userOpt = userService.findByEmail(request.getEmail());
        
        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body("Invalid credentials");
        }

        User user = userOpt.get();
        if (!userService.validatePassword(request.getPassword(), user.getPassword())) {
            return ResponseEntity.badRequest().body("Invalid credentials");
        }

        String token = jwtService.generateToken(user.getEmail(), user.getRole().toString());
        return ResponseEntity.ok(new AuthResponse(token, user));
    }

    @PostMapping("/validate")
    public ResponseEntity<?> validateToken(@RequestHeader("Authorization") String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return ResponseEntity.badRequest().body("Invalid token format");
            }

            String token = authHeader.substring(7);
            String email = jwtService.extractEmail(token);
            
            if (jwtService.validateToken(token, email)) {
                Optional<User> userOpt = userService.findByEmail(email);
                if (userOpt.isPresent()) {
                    User user = userOpt.get();
                    return ResponseEntity.ok(new AuthResponse(token, user));
                }
            }
            
            return ResponseEntity.badRequest().body("Invalid token");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Invalid token");
        }
    }
}