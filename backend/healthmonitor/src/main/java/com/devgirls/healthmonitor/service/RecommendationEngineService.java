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

    public void evaluate(DailyAggregates agg) {
        if (agg == null) return;

        Long userId = agg.getUser() != null ? agg.getUser().getUserId() : agg.getUserId();
        if (userId == null) return;

        // --- Правило #1: мало сна + высокий z-HR ---
        if (agg.getSleepHoursTotal() != null && agg.getZHrMean() != null
                && agg.getSleepHoursTotal().doubleValue() < 6.0
                && agg.getZHrMean().doubleValue() > 0.8) {

            recommendationsService.create(
                    userId,
                    "Сон ниже нормы и пульс выше — сделайте 10-мин дыхательное упражнение и ложитесь раньше.",
                    "rules",
                    "warning"
            );
        }

        // --- Правило #2: два дня подряд < 3000 шагов ---
        Integer todaySteps = agg.getStepsTotal() != null ? agg.getStepsTotal() : 0;
        Integer yesterdaySteps =
                dailyAggregatesRepository.findStepsTotal(userId, agg.getDate().minusDays(1));

        if ((agg.getStepsTotal() != null && agg.getStepsTotal() < 3000)
                && (yesterdaySteps != null && yesterdaySteps < 3000)) {
            recommendationsService.create(
                    userId,
                    "Два дня низкой активности — пройдитесь 15–20 минут лёгким шагом.",
                    "rules",
                    "advisory"
            );
        }
    }
}
