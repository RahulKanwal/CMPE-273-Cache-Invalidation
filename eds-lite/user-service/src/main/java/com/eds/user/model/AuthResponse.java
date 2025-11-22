package com.eds.user.model;

public class AuthResponse {
    private String token;
    private String email;
    private String firstName;
    private String lastName;
    private User.UserRole role;

    public AuthResponse(String token, User user) {
        this.token = token;
        this.email = user.getEmail();
        this.firstName = user.getFirstName();
        this.lastName = user.getLastName();
        this.role = user.getRole();
    }

    // Getters and setters
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public User.UserRole getRole() { return role; }
    public void setRole(User.UserRole role) { this.role = role; }
}