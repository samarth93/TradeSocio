package com.devops.challenge.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.devops.challenge.service.MetricsService;
import com.fasterxml.jackson.databind.ObjectMapper;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;

@SpringBootTest
class ApiControllerTest {

    private MockMvc mockMvc;

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
    }

    @Test
    void testGetRequest() throws Exception {
        mockMvc.perform(get("/api")
                .header("X-Custom-Header", "test-value")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("GET"))
                .andExpect(jsonPath("$.headers").exists())
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.requestUri").value("/api"));
    }

    @Test
    void testPostRequest() throws Exception {
        String requestBody = "{\"message\": \"Hello World\", \"timestamp\": \"2024-01-01T00:00:00Z\"}";
        
        mockMvc.perform(post("/api")
                .header("X-Custom-Header", "test-value")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("POST"))
                .andExpect(jsonPath("$.headers").exists())
                .andExpect(jsonPath("$.body").exists())
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.requestUri").value("/api"));
    }

    @Test
    void testPutRequest() throws Exception {
        String requestBody = "{\"update\": \"data\"}";
        
        mockMvc.perform(put("/api")
                .header("X-Custom-Header", "test-value")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("PUT"))
                .andExpect(jsonPath("$.headers").exists())
                .andExpect(jsonPath("$.body").exists())
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.requestUri").value("/api"));
    }

    @Test
    void testDeleteRequest() throws Exception {
        mockMvc.perform(delete("/api")
                .header("X-Custom-Header", "test-value")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("DELETE"))
                .andExpect(jsonPath("$.headers").exists())
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.requestUri").value("/api"));
    }

    @Test
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("DevOps Challenge API"))
                .andExpect(jsonPath("$.version").value("1.0.0"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void testInfoEndpoint() throws Exception {
        mockMvc.perform(get("/api/info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.application").value("DevOps Challenge API"))
                .andExpect(jsonPath("$.version").value("1.0.0"))
                .andExpect(jsonPath("$.description").value("A simple cloud-native API service"))
                .andExpect(jsonPath("$.endpoints").exists());
    }

    @Test
    void testPostRequestWithInvalidJson() throws Exception {
        String invalidJson = "invalid json content";
        
        mockMvc.perform(post("/api")
                .header("X-Custom-Header", "test-value")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("POST"))
                .andExpect(jsonPath("$.body").value(invalidJson))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void testRequestWithMultipleHeaders() throws Exception {
        mockMvc.perform(get("/api")
                .header("X-Custom-Header", "test-value")
                .header("X-Another-Header", "another-value")
                .header("Authorization", "Bearer token123")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("GET"))
                .andExpect(jsonPath("$.headers['X-Custom-Header']").value("test-value"))
                .andExpect(jsonPath("$.headers['X-Another-Header']").value("another-value"))
                .andExpect(jsonPath("$.headers['Authorization']").value("Bearer token123"));
    }
} 