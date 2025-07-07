package com.devops.challenge.controller;

import com.devops.challenge.dto.ApiResponse;
import com.devops.challenge.service.MetricsService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class ApiController {

    private static final Logger logger = LoggerFactory.getLogger(ApiController.class);
    
    private final MetricsService metricsService;
    private final ObjectMapper objectMapper;
    private final Counter apiCallCounter;
    private final Counter getRequestCounter;
    private final Counter postRequestCounter;
    private final Counter putRequestCounter;
    private final Counter deleteRequestCounter;

    @Autowired
    public ApiController(MetricsService metricsService, 
                        ObjectMapper objectMapper,
                        MeterRegistry meterRegistry) {
        this.metricsService = metricsService;
        this.objectMapper = objectMapper;
        
        // Initialize custom metrics
        this.apiCallCounter = Counter.builder("api_calls_total")
                .description("Total number of API calls")
                .register(meterRegistry);
                
        this.getRequestCounter = Counter.builder("api_get_requests_total")
                .description("Total number of GET requests")
                .register(meterRegistry);
                
        this.postRequestCounter = Counter.builder("api_post_requests_total")
                .description("Total number of POST requests")
                .register(meterRegistry);
                
        this.putRequestCounter = Counter.builder("api_put_requests_total")
                .description("Total number of PUT requests")
                .register(meterRegistry);
                
        this.deleteRequestCounter = Counter.builder("api_delete_requests_total")
                .description("Total number of DELETE requests")
                .register(meterRegistry);
    }

    @GetMapping
    @Timed(value = "api_get_requests", description = "Time taken to process GET requests")
    public ResponseEntity<ApiResponse> handleGetRequest(HttpServletRequest request) {
        logger.info("Received GET request to /api");
        
        // Increment counters
        apiCallCounter.increment();
        getRequestCounter.increment();
        metricsService.incrementApiCalls();
        
        ApiResponse response = buildApiResponse(request, "GET", null);
        return ResponseEntity.ok(response);
    }

    @PostMapping
    @Timed(value = "api_post_requests", description = "Time taken to process POST requests")
    public ResponseEntity<ApiResponse> handlePostRequest(HttpServletRequest request, 
                                                        @RequestBody(required = false) String body) {
        logger.info("Received POST request to /api");
        
        // Increment counters
        apiCallCounter.increment();
        postRequestCounter.increment();
        metricsService.incrementApiCalls();
        
        ApiResponse response = buildApiResponse(request, "POST", body);
        return ResponseEntity.ok(response);
    }

    @PutMapping
    @Timed(value = "api_put_requests", description = "Time taken to process PUT requests")
    public ResponseEntity<ApiResponse> handlePutRequest(HttpServletRequest request, 
                                                       @RequestBody(required = false) String body) {
        logger.info("Received PUT request to /api");
        
        // Increment counters
        apiCallCounter.increment();
        putRequestCounter.increment();
        metricsService.incrementApiCalls();
        
        ApiResponse response = buildApiResponse(request, "PUT", body);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping
    @Timed(value = "api_delete_requests", description = "Time taken to process DELETE requests")
    public ResponseEntity<ApiResponse> handleDeleteRequest(HttpServletRequest request) {
        logger.info("Received DELETE request to /api");
        
        // Increment counters
        apiCallCounter.increment();
        deleteRequestCounter.increment();
        metricsService.incrementApiCalls();
        
        ApiResponse response = buildApiResponse(request, "DELETE", null);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        health.put("service", "DevOps Challenge API");
        health.put("version", "1.0.0");
        
        return ResponseEntity.ok(health);
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> getInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("application", "DevOps Challenge API");
        info.put("version", "1.0.0");
        info.put("description", "A simple cloud-native API service");
        info.put("build-time", LocalDateTime.now());
        info.put("endpoints", Map.of(
            "api", "/api (GET, POST, PUT, DELETE)",
            "health", "/api/health",
            "info", "/api/info",
            "actuator", "/actuator/*"
        ));
        
        return ResponseEntity.ok(info);
    }

    private ApiResponse buildApiResponse(HttpServletRequest request, String method, String body) {
        try {
            Map<String, String> headers = extractHeaders(request);
            Object parsedBody = parseBody(body);
            
            return ApiResponse.builder()
                    .method(method)
                    .headers(headers)
                    .body(parsedBody)
                    .timestamp(LocalDateTime.now())
                    .requestUri(request.getRequestURI())
                    .queryString(request.getQueryString())
                    .remoteAddr(request.getRemoteAddr())
                    .userAgent(request.getHeader("User-Agent"))
                    .contentType(request.getContentType())
                    .build();
                    
        } catch (Exception e) {
            logger.error("Error building API response", e);
            return ApiResponse.builder()
                    .method(method)
                    .headers(Collections.emptyMap())
                    .body("Error parsing request")
                    .timestamp(LocalDateTime.now())
                    .error("Failed to parse request: " + e.getMessage())
                    .build();
        }
    }

    private Map<String, String> extractHeaders(HttpServletRequest request) {
        Map<String, String> headers = new HashMap<>();
        Enumeration<String> headerNames = request.getHeaderNames();
        
        while (headerNames.hasMoreElements()) {
            String headerName = headerNames.nextElement();
            String headerValue = request.getHeader(headerName);
            headers.put(headerName, headerValue);
        }
        
        return headers;
    }

    private Object parseBody(String body) {
        if (body == null || body.trim().isEmpty()) {
            return null;
        }
        
        try {
            // Try to parse as JSON
            return objectMapper.readValue(body, Object.class);
        } catch (JsonProcessingException e) {
            // If not valid JSON, return as string
            return body;
        }
    }
} 