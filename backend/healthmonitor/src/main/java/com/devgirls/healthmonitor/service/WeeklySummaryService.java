package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.MLInsights;
import com.devgirls.healthmonitor.repository.MLInsightsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Service responsible for generating weekly fatigue summaries
 * based on daily ML insights (fatigue probabilities).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WeeklySummaryService {

    private final MLInsightsRepository mlInsightsRepository;
    private final RecommendationsService recommendationsService;

    /**
     * Generates a weekly fatigue summary for the given user and week end date.
     * <p>
     * Example: if weekEnd = 2025-11-10, the method will consider the period
     * from 2025-11-04 to 2025-11-10 (7 days).
     *
     * @param userId  the user ID
     * @param weekEnd the last day of the week (inclusive)
     * @return the text of the weekly recommendation (for debugging / UI)
     */
    public String generateWeeklyFatigueSummary(Long userId, LocalDate weekEnd) {
        LocalDate weekStart = weekEnd.minusDays(6);

        List<MLInsights> insights = mlInsightsRepository
                .findByAggregate_User_UserIdAndAggregate_DateBetweenOrderByAggregate_DateAsc(
                        userId, weekStart, weekEnd
                );

        if (insights.isEmpty()) {
            String message = String.format(
                    "No ML insights found for user %d between %s and %s",
                    userId, weekStart, weekEnd
            );
            log.warn(message);
            return "Not enough data to generate a weekly fatigue summary.";
        }

        // --- 1) Group by day and pick one probability per day (max) ---
        Map<LocalDate, Double> dailyProbabilities = insights.stream()
                .filter(ins -> ins.getAggregate() != null && ins.getAggregate().getDate() != null)
                .collect(java.util.stream.Collectors.toMap(
                        ins -> ins.getAggregate().getDate(),
                        ins -> ins.getProbability() != null ? ins.getProbability().doubleValue() : 0.0,
                        // if multiple insights per day -> take the highest probability
                        Double::max
                ));

        int n = dailyProbabilities.size(); // number of days in the week we actually have data for

        double sumProb = 0.0;
        double maxProb = 0.0;
        int highRiskDays = 0;      // prob > 0.7
        int moderateRiskDays = 0;  // 0.4 < prob <= 0.7
        int lowRiskDays = 0;       // prob <= 0.4

        for (double p : dailyProbabilities.values()) {
            sumProb += p;
            if (p > maxProb) {
                maxProb = p;
            }

            if (p > 0.7) {
                highRiskDays++;
            } else if (p > 0.4) {
                moderateRiskDays++;
            } else {
                lowRiskDays++;
            }
        }

        double avgProb = sumProb / n;

        // --- 2) Build weekly recommendation text based on days, not raw rows ---
        String recommendationText;
        String severity;

        if (highRiskDays >= 3 || maxProb > 0.85) {
            severity = "critical";
            recommendationText = String.format(
                    "This week shows frequent signs of high fatigue. " +
                            "High-risk days: %d out of %d. " +
                            "Consider planning 1–2 full rest days, reducing physical load, " +
                            "and prioritizing sleep and recovery.",
                    highRiskDays, n
            );
        } else if (moderateRiskDays >= 3 || avgProb > 0.5) {
            severity = "warning";
            recommendationText = String.format(
                    "This week was moderately demanding. " +
                            "Days with elevated fatigue risk: %d out of %d. " +
                            "Try to keep a consistent sleep schedule and avoid overloading yourself.",
                    (moderateRiskDays + highRiskDays), n
            );
        } else {
            severity = "advisory";
            recommendationText = String.format(
                    "Overall, this week looks balanced. " +
                            "Most days had low fatigue risk (%d out of %d). " +
                            "Keep maintaining your current sleep and activity habits.",
                    lowRiskDays, n
            );
        }

        recommendationsService.create(
                userId,
                recommendationText,
                "weekly_summary",
                severity
        );

        log.info(
                "Weekly fatigue summary created for user {} for period {}..{} | severity={} | text={}",
                userId, weekStart, weekEnd, severity, recommendationText
        );

        return recommendationText;
    }
}