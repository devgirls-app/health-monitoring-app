package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.DailyAggregates;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.Recommendations;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.DailyAggregatesRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

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

        if (data.getSteps() != null && data.getSteps() < 3000) {
            recommendationText = "👟 Low activity detected. Try walking at least 5000 steps today.";
        } else if (data.getSleepHours() != null
                && data.getSleepHours().compareTo(BigDecimal.valueOf(5)) < 0) {
            recommendationText = "😴 You slept less than 5 hours. Aim for 7–8 hours of rest.";
        }

        if (recommendationText != null) {
            Recommendations rec = new Recommendations();
            rec.setRecommendationText(recommendationText);
            rec.setSource("RuleEngine");

            User user = data.getUser();
            if (user != null) {
                rec.setUser(user);
            }

            recommendationsService.save(rec);

            System.out.println("✅ Generated recommendation for user " +
                    (user != null ? user.getUserId() : "Unknown") + ": " + recommendationText);
        }
    }

    /**
     * Этот метод вызывается ПОСЛЕ аггрегации и ПОСЛЕ запуска ML-модели.
     * Он использует и агрегаты (agg), и предсказание (prob) для правил.
     */
    public void evaluate(DailyAggregates agg, double prob) {
        if (agg == null) return;

        Long userId = agg.getUserId();
        if (userId == null) return;

        // --- Rule-based recommendation #1: Low sleep + high HR ---
        if (agg.getDSleep7d() != null && agg.getDSteps7d() != null
                && agg.getDSleep7d().doubleValue() < -0.8   // Sleep significantly below normal
                && agg.getDSteps7d().doubleValue() > 0.8) { // Activity significantly above normal

            recommendationsService.create(
                    userId,
                    "Your sleep is well below normal while your activity is high. This pattern leads to fatigue. Remember to rest.",
                    "rules",
                    "warning"
            );
        }

        // --- Rule-based recommendation #2: Two days of low steps ---
        Integer yesterdaySteps =
                dailyAggregatesRepository.findStepsTotal(userId, agg.getDate().minusDays(1));

        if ((agg.getStepsTotal() != null && agg.getStepsTotal() < 3000)
                && (yesterdaySteps != null && yesterdaySteps < 3000)) {

            recommendationsService.create(
                    userId,
                    "Two consecutive days of low activity — take a 15–20 minute light walk.",
                    "rules",
                    "advisory"
            );
        }

        // --- ML-based dynamic recommendations ---
        String recText;
        String severity;

        // Randomize text selection for more natural variation
        java.util.Random rand = new java.util.Random();

        java.util.List<String> lowTexts = java.util.List.of(
                "You're doing well today! Keep maintaining balanced sleep and activity.",
                "Energy levels look stable — stay consistent with your daily routine.",
                "Everything looks great — keep up your healthy habits!"
        );

        java.util.List<String> moderateTexts = java.util.List.of(
                "Your fatigue risk is moderate. Try taking short breaks and ensure at least 7 hours of sleep tonight.",
                "You might be slightly overworked. Stay hydrated and avoid intense exercise today.",
                "Moderate fatigue detected — take some rest after work and go to bed early."
        );

        java.util.List<String> highTexts = java.util.List.of(
                "High fatigue risk detected — take a rest day or reduce physical load.",
                "You’re showing signs of fatigue. Prioritize rest, proper sleep, and light meals today.",
                "Severe fatigue risk — avoid stress and physical exertion, and focus on recovery."
        );

        // --- Choose message and severity based on probability ---
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
                severity
        );

        // Log output for debugging
        System.out.printf(
                "🧠 [ML Recommendation] user=%d | prob=%.3f | severity=%s | text=%s%n",
                userId, prob, severity, recText
        );
    }
}