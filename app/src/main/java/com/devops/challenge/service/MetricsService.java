package com.devops.challenge.service;

import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicLong;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

@Service
public class MetricsService {
    
    private static final Logger logger = LoggerFactory.getLogger(MetricsService.class);
    
    private final MeterRegistry meterRegistry;
    private final Counter apiCallsCounter;
    private final Counter errorCounter;
    private final Timer responseTimer;
    private final AtomicLong activeConnections;
    private final AtomicLong totalRequests;
    
    @Autowired
    public MetricsService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.activeConnections = new AtomicLong(0);
        this.totalRequests = new AtomicLong(0);
        
        // Initialize custom metrics
        this.apiCallsCounter = Counter.builder("devops_api_calls_total")
                .description("Total number of API calls made to the service")
                .tag("service", "devops-challenge")
                .register(meterRegistry);
                
        this.errorCounter = Counter.builder("devops_api_errors_total")
                .description("Total number of API errors")
                .tag("service", "devops-challenge")
                .register(meterRegistry);
                
        this.responseTimer = Timer.builder("devops_api_response_time")
                .description("Response time for API calls")
                .tag("service", "devops-challenge")
                .register(meterRegistry);
        
        // Register gauges
        Gauge.builder("devops_api_active_connections", this, MetricsService::getActiveConnections)
                .description("Number of active connections")
                .tag("service", "devops-challenge")
                .register(meterRegistry);
                
        Gauge.builder("devops_api_total_requests", this, MetricsService::getTotalRequests)
                .description("Total number of requests processed")
                .tag("service", "devops-challenge")
                .register(meterRegistry);
                
        Gauge.builder("devops_api_uptime_seconds", this, MetricsService::getUptimeSeconds)
                .description("Application uptime in seconds")
                .tag("service", "devops-challenge")
                .register(meterRegistry);
        
        logger.info("MetricsService initialized with custom metrics");
    }
    
    /**
     * Increment the API calls counter
     */
    public void incrementApiCalls() {
        apiCallsCounter.increment();
        totalRequests.incrementAndGet();
        logger.debug("API calls counter incremented");
    }
    
    /**
     * Increment the error counter
     */
    public void incrementErrors() {
        errorCounter.increment();
        logger.debug("Error counter incremented");
    }
    
    /**
     * Record response time
     */
    public void recordResponseTime(long milliseconds) {
        responseTimer.record(milliseconds, java.util.concurrent.TimeUnit.MILLISECONDS);
        logger.debug("Response time recorded: {} ms", milliseconds);
    }
    
    /**
     * Increment active connections
     */
    public void incrementActiveConnections() {
        activeConnections.incrementAndGet();
        logger.debug("Active connections incremented: {}", activeConnections.get());
    }
    
    /**
     * Decrement active connections
     */
    public void decrementActiveConnections() {
        activeConnections.decrementAndGet();
        logger.debug("Active connections decremented: {}", activeConnections.get());
    }
    
    /**
     * Get current active connections count
     */
    public long getActiveConnections() {
        return activeConnections.get();
    }
    
    /**
     * Get total requests count
     */
    public long getTotalRequests() {
        return totalRequests.get();
    }
    
    /**
     * Get application uptime in seconds
     */
    public double getUptimeSeconds() {
        // This is a simple implementation - in a real app, you'd track the start time
        return System.currentTimeMillis() / 1000.0;
    }
    
    /**
     * Create a custom counter with tags
     */
    public Counter createCustomCounter(String name, String description, String... tags) {
        Counter.Builder builder = Counter.builder(name).description(description);
        
        // Add tags in pairs
        for (int i = 0; i < tags.length; i += 2) {
            if (i + 1 < tags.length) {
                builder.tag(tags[i], tags[i + 1]);
            }
        }
        
        return builder.register(meterRegistry);
    }
    
    /**
     * Create a custom timer with tags
     */
    public Timer createCustomTimer(String name, String description, String... tags) {
        Timer.Builder builder = Timer.builder(name).description(description);
        
        // Add tags in pairs
        for (int i = 0; i < tags.length; i += 2) {
            if (i + 1 < tags.length) {
                builder.tag(tags[i], tags[i + 1]);
            }
        }
        
        return builder.register(meterRegistry);
    }
    
    /**
     * Get metrics summary
     */
    public MetricsSummary getMetricsSummary() {
        return new MetricsSummary(
            apiCallsCounter.count(),
            errorCounter.count(),
            activeConnections.get(),
            totalRequests.get(),
            LocalDateTime.now()
        );
    }
    
    /**
     * Inner class for metrics summary
     */
    public static class MetricsSummary {
        private final double totalApiCalls;
        private final double totalErrors;
        private final long activeConnections;
        private final long totalRequests;
        private final LocalDateTime timestamp;
        
        public MetricsSummary(double totalApiCalls, double totalErrors, 
                            long activeConnections, long totalRequests, 
                            LocalDateTime timestamp) {
            this.totalApiCalls = totalApiCalls;
            this.totalErrors = totalErrors;
            this.activeConnections = activeConnections;
            this.totalRequests = totalRequests;
            this.timestamp = timestamp;
        }
        
        // Getters
        public double getTotalApiCalls() { return totalApiCalls; }
        public double getTotalErrors() { return totalErrors; }
        public long getActiveConnections() { return activeConnections; }
        public long getTotalRequests() { return totalRequests; }
        public LocalDateTime getTimestamp() { return timestamp; }
    }
} 