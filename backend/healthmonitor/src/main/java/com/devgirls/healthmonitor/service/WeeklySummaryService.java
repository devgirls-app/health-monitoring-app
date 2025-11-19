package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.entity.MLInsights;
import com.devgirls.healthmonitor.entity.Recommendations;
import com.devgirls.healthmonitor.repository.MLInsightsRepository;
import com.devgirls.healthmonitor.repository.RecommendationsRepository; // ✅ Добавлен для дедупликации
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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
    private final RecommendationsRepository recommendationsRepository;

    @Transactional
    public String generateWeeklyFatigueSummary(Long userId, LocalDate weekEnd) {
        LocalDate weekStart = weekEnd.minusDays(6);

        List<MLInsights> insights = mlInsightsRepository
                .findByAggregate_User_UserIdAndAggregate_DateBetweenOrderByAggregate_DateAsc(
                        userId, weekStart, weekEnd
                );

        if (insights.isEmpty()) {
            return "Not enough data to generate a weekly fatigue summary.";
        }

        Map<LocalDate, Double> dailyProbabilities = insights.stream()
                .filter(ins -> ins.getAggregate() != null && ins.getAggregate().getDate() != null)
                .collect(Collectors.toMap(
                        ins -> ins.getAggregate().getDate(),
                        ins -> ins.getProbability() != null ? ins.getProbability().doubleValue() : 0.0,
                        Double::max
                ));

        int n = dailyProbabilities.size();
        double sumProb = 0.0;
        double maxProb = 0.0;
        int highRiskDays = 0;
        int moderateRiskDays = 0;
        int lowRiskDays = 0;

        for (double p : dailyProbabilities.values()) {
            sumProb += p;
            if (p > maxProb) maxProb = p;

            if (p > 0.7) highRiskDays++;
            else if (p > 0.4) moderateRiskDays++;
            else lowRiskDays++;
        }

        double avgProb = sumProb / n;
        String recommendationText;
        String severity;

        if (highRiskDays >= 3 || maxProb > 0.85) {
            severity = "critical";
            recommendationText = String.format(
                    "This week shows frequent signs of high fatigue. High-risk days: %d out of %d.",
                    highRiskDays, n
            );
        } else if (moderateRiskDays >= 3 || avgProb > 0.5) {
            severity = "warning";
            recommendationText = String.format(
                    "This week was moderately demanding. Elevated fatigue risk: %d out of %d.",
                    (moderateRiskDays + highRiskDays), n
            );
        } else {
            severity = "advisory";
            recommendationText = String.format(
                    "Overall, this week looks balanced. Low risk days: %d out of %d.",
                    lowRiskDays, n
            );
        }

        LocalDateTime reportDate = weekEnd.atTime(20, 0);
        LocalDateTime from = weekEnd.atStartOfDay();
        LocalDateTime to = from.plusDays(1);

        List<Recommendations> existingSummaries = recommendationsRepository
                .findByUser_UserIdAndSourceAndCreatedAtBetween(userId, "weekly_summary", from, to);

        if (!existingSummaries.isEmpty()) {
            recommendationsRepository.deleteAll(existingSummaries);
            log.warn("Removed {} old weekly summaries for user {} on date {}", existingSummaries.size(), userId, weekEnd);
        }

        recommendationsService.create(
                userId,
                recommendationText,
                "weekly_summary",
                severity,
                reportDate
        );

        log.info("Weekly fatigue summary created for user {} | date={}", userId, reportDate);

        return recommendationText;
    }
}