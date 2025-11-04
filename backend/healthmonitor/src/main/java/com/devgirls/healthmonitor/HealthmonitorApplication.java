package com.devgirls.healthmonitor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class HealthmonitorApplication {

    public static void main(String[] args) {
        var context = SpringApplication.run(HealthmonitorApplication.class, args);
        System.out.println("Healthmonitor started");
    }

}