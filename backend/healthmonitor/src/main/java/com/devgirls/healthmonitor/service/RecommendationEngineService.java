package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.DailyAggregates;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.DailyAggregatesRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
public class RecommendationEngineService {

    private final RecommendationsService recommendationsService;
    private final DailyAggregatesRepository dailyAggregatesRepository;
    private final UserRepository userRepository;

    public RecommendationEngineService(RecommendationsService recommendationsService,
                                       UserRepository userRepository, DailyAggregatesRepository dailyAggregatesRepository) {
        this.recommendationsService = recommendationsService;
        this.userRepository = userRepository;
        this.dailyAggregatesRepository = dailyAggregatesRepository;
    }

    public void analyzeAndGenerate(HealthData data) {
        String recommendationText = null;

        if (data.getSteps() != null && data.getSteps() < 5000) {
            recommendationText = "👟 Low activity detected. Try walking at least 5000 steps today.";
        } else if (data.getSleepHours() != null
                && data.getSleepHours().compareTo(BigDecimal.valueOf(7)) < 0) {
            recommendationText = "😴 You slept less than 7 hours. Aim for 7–8 hours of rest.";
        }

        if (recommendationText != null) {
            String severity = "advisory";
            User user = data.getUser();

            if (user != null) {
                // Используем .create для автоматической проверки и обновления существующей рекомендации
                recommendationsService.create(
                        user.getUserId(),
                        recommendationText,
                        "RuleEngine",
                        severity,
                        data.getTimestamp() != null ? data.getTimestamp() : LocalDateTime.now()
                );
            }

            System.out.println("Generated recommendation for user " +
                    (user != null ? user.getUserId() : "Unknown") + ": " + recommendationText);
        }
    }

    // Analysis of aggregates
    public void evaluate(DailyAggregates agg, double prob) {
        if (agg == null) return;

        Long userId = agg.getUserId();
        if (userId == null) return;

        LocalDateTime recDate = LocalDateTime.now();
        if (agg.getDate() != null) {
            recDate = agg.getDate().atTime(10, 0);
        }

        // --- Rule-based recommendation #1 ---
        if (agg.getDSleep7d() != null && agg.getDSteps7d() != null
                && agg.getDSleep7d().doubleValue() < -0.8
                && agg.getDSteps7d().doubleValue() > 0.8) {

            recommendationsService.create(
                    userId,
                    "Your sleep is well below normal while your activity is high. This pattern leads to fatigue.",
                    "rules",
                    "warning",
                    recDate
            );
        }

        // --- Rule-based recommendation #2 ---
        Integer yesterdaySteps =
                dailyAggregatesRepository.findStepsTotal(userId, agg.getDate().minusDays(1));

        if ((agg.getStepsTotal() != null && agg.getStepsTotal() < 3000)
                && (yesterdaySteps != null && yesterdaySteps < 3000)) {

            recommendationsService.create(
                    userId,
                    "Two consecutive days of low activity — take a 15–20 minute light walk.",
                    "rules",
                    "advisory",
                    recDate
            );
        }

        // --- ML-based dynamic recommendations ---
        String recText;
        String severity;

        java.util.Random rand = new java.util.Random();

        java.util.List<String> lowTexts = java.util.List.of(
                "Fatigue risk is low. Consider a light workout to stay active.",
                "Energy levels look stable — stay consistent with your daily routine.",
                "Everything looks great — keep up your healthy habits!"
        );
        java.util.List<String> moderateTexts = java.util.List.of(
                "Your fatigue risk is moderate. Try taking short breaks.",
                "You might be slightly overworked. Stay hydrated.",
                "Moderate fatigue detected — take some rest after work."
        );
        java.util.List<String> highTexts = java.util.List.of(
                "High fatigue risk detected — take a rest day.",
                "You’re showing signs of fatigue. Prioritize rest.",
                "Severe fatigue risk — avoid stress and physical exertion."
        );

        if (prob <= 0.4) {
            recText = lowTexts.get(rand.nextInt(lowTexts.size()));
            severity = "advisory";
        } else if (prob <= 0.7) {
            recText = moderateTexts.get(rand.nextInt(moderateTexts.size()));
            severity = "warning";
        } else {
            recText = highTexts.get(rand.nextInt(highTexts.size()));
            severity = "critical";
        }

        recommendationsService.create(
                userId,
                recText,
                "ml_model",
                severity,
                recDate
        );

        System.out.printf(
                "🧠 [ML Recommendation] user=%d | prob=%.3f | severity=%s | date=%s%n",
                userId, prob, severity, recDate
        );
    }
}