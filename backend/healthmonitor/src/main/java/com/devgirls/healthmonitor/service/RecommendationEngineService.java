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

        if (agg.getDSleep7d() != null && agg.getDSteps7d() != null
                && agg.getDSleep7d().doubleValue() < -0.8   // Сон ЗНАЧИТЕЛЬНО ниже нормы
                && agg.getDSteps7d().doubleValue() > 0.8) { // Активность ЗНАЧИТЕЛЬНО выше нормы

            recommendationsService.create(
                    userId,
                    "Your sleep is well below normal while your activity is high. This pattern leads to fatigue. Remember to rest.",
                    "rules",
                    "warning"
            );
        }

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

        if (prob > 0.8) {
            recommendationsService.create(
                    userId,
                    "High fatigue risk detected by the ML model — take a rest or avoid heavy workouts today.",
                    "ml_model",
                    "warning"
            );
        } else if (prob > 0.6) {
            recommendationsService.create(
                    userId,
                    "Moderate fatigue risk detected — take short breaks and ensure enough sleep tonight.",
                    "ml_model",
                    "advisory"
            );
        }
    }
}