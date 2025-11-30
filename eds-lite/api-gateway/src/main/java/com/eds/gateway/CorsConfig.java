package com.eds.gateway;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfig = new CorsConfiguration();
        
        // Use allowedOriginPatterns instead of allowedOrigins for better compatibility
        corsConfig.addAllowedOriginPattern("https://marketplace-ui-tau.vercel.app");
        corsConfig.addAllowedOriginPattern("http://localhost:3000");
        
        // Allow all HTTP methods
        corsConfig.addAllowedMethod("*");
        
        // Allow all headers
        corsConfig.addAllowedHeader("*");
        
        // Expose all headers
        corsConfig.addExposedHeader("*");
        
        // Allow credentials
        corsConfig.setAllowCredentials(true);
        
        // Cache preflight for 1 hour
        corsConfig.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfig);

        return new CorsWebFilter(source);
    }
}
