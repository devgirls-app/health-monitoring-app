package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.Recommendations;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class RecommendationEngineService {

    private final RecommendationsService recommendationsService;
    private final UserRepository userRepository;

    public RecommendationEngineService(RecommendationsService recommendationsService,
                                       UserRepository userRepository) {
        this.recommendationsService = recommendationsService;
        this.userRepository = userRepository;
    }

    public void analyzeAndGenerate(HealthData data) {
        String recommendationText = null;

        if (data.getHeartRate() != null && data.getHeartRate() > 120) {
            recommendationText = "⚠️ High heart rate detected. Try resting and staying hydrated.";
        } else if (data.getSteps() != null && data.getSteps() < 3000) {
            recommendationText = "👟 Low activity detected. Try walking at least 5000 steps today.";
        } else if (data.getSleepHours() != null
                && data.getSleepHours().compareTo(BigDecimal.valueOf(5)) < 0) {
            recommendationText = "😴 You slept less than 5 hours. Aim for 7–8 hours of rest.";
        }

        if (recommendationText != null) {
            Recommendations rec = new Recommendations();
            rec.setRecommendationText(recommendationText);
            rec.setSource("RuleEngine");

            // Use data.getUser() instead of dto.getUserId()
            User user = data.getUser();
            if (user != null) {
                rec.setUser(user);
            }

            recommendationsService.save(rec);

            System.out.println("✅ Generated recommendation for user " +
                    (user != null ? user.getUserId() : "Unknown") + ": " + recommendationText);
        }
    }
}
