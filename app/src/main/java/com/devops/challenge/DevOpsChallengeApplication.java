package com.devops.challenge;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties
public class DevOpsChallengeApplication {

    public static void main(String[] args) {
        SpringApplication.run(DevOpsChallengeApplication.class, args);
    }
} 