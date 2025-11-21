package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.DailyAggregates;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.DailyAggregatesRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

@Service
public class RecommendationEngineService {

    private final RecommendationsService recommendationsService;
    private final DailyAggregatesRepository dailyAggregatesRepository;
    private final UserRepository userRepository;

    public RecommendationEngineService(RecommendationsService recommendationsService,
                                       UserRepository userRepository,
                                       DailyAggregatesRepository dailyAggregatesRepository) {
        this.recommendationsService = recommendationsService;
        this.userRepository = userRepository;
        this.dailyAggregatesRepository = dailyAggregatesRepository;
    }

    public void analyzeAndGenerate(HealthData data) {
    }

    public void evaluate(DailyAggregates agg, double mlProbability) {
        if (agg == null) return;
        User user = agg.getUser();
        if (user == null) return;

        Long userId = user.getUserId();
        LocalDateTime recDate = LocalDateTime.now();
        if (agg.getDate() != null) {
            recDate = agg.getDate().atTime(10, 0);
        }

        String finalRecText = null;
        String finalSource = null;
        String finalSeverity = null;

        double weight = (user.getWeight() != null) ? user.getWeight().doubleValue() : 70.0;
        double heightM = (user.getHeight() != null) ? user.getHeight().doubleValue() / 100.0 : 1.75;
        double bmi = weight / (heightM * heightM);

        boolean isOverweight = bmi > 25.0;

        int steps = (agg.getStepsTotal() != null) ? agg.getStepsTotal() : 0;
        boolean highActivity = steps > 8000;
        boolean lowActivity = steps < 4000;


        if (agg.getSleepHoursTotal() != null && agg.getSleepHoursTotal().doubleValue() > 0.1 && agg.getSleepHoursTotal().doubleValue() < 5.0) {
            finalRecText = "\uD83D\uDE34 Severe sleep deprivation. Regardless of your goals, you need recovery tonight.";
            finalSource = "RuleEngine";
            finalSeverity = "critical";
        }
        else if (steps < 2000 && mlProbability < 0.4) {
            finalRecText = isOverweight
                    ? "\uD83D\uDC5F You haven't moved much today. For your metabolism, a 20-min walk is crucial."
                    : "\uD83D\uDC5F Energy is stagnant. A quick walk will help you sleep better.";
            finalSource = "RuleEngine";
            finalSeverity = "warning";
        }

        if (finalRecText == null) {
            finalSource = "ml_model_contextual";
            Random rand = new Random();

            if (mlProbability > 0.7) {
                if (highActivity) {
                    finalRecText = "💪 You've worked hard today! This fatigue is productive. Focus on high-protein food and sleep to recover.";
                    finalSeverity = "warning";
                } else {
                    finalRecText = "⚠️ High fatigue detected despite low activity. This suggests stress or burnout. Try meditation or early sleep.";
                    finalSeverity = "critical";
                }
            }

            else if (mlProbability > 0.4) {
                if (isOverweight && lowActivity) {
                    finalRecText = "📉 Fatigue risk is moderate. Don't let it stop you—a light walk actually reduces fatigue!";
                    finalSeverity = "warning";
                } else {
                    finalRecText = "⚖️ Moderate fatigue. You are in the yellow zone. Hydrate and avoid late caffeine.";
                    finalSeverity = "advisory";
                }
            }

            else {
                if (highActivity) {
                    finalRecText = "🚀 Impressive! High activity and low fatigue risk. Your endurance is improving.";
                    finalSeverity = "advisory";
                } else {
                    List<String> tips = List.of(
                            "✨ All systems normal. Keep maintaining your healthy rhythm.",
                            "🌿 Your vitals look stable. Great day to focus on mental tasks.",
                            "✅ Low fatigue risk. Ready for tomorrow!"
                    );
                    finalRecText = tips.get(rand.nextInt(tips.size()));
                    finalSeverity = "advisory";
                }
            }
        }


        recommendationsService.create(
                userId,
                finalRecText,
                finalSource,
                finalSeverity,
                recDate
        );

        System.out.printf("🧠 [SmartRec] User=%d | BMI=%.1f | Steps=%d | ML=%.2f | Verdict: %s%n",
                userId, bmi, steps, mlProbability, finalRecText);
    }
}