package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.DailyAggregatesDTO;
import com.devgirls.healthmonitor.entity.*;
import com.devgirls.healthmonitor.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.*;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AggregationService {
    private final HealthDataRepository healthDataRepository;
    private final DailyAggregatesRepository dailyAggregatesRepository;
    private final UserRepository userRepository;
    private final RecommendationEngineService recommendationEngineService;
    private final MLInferenceService mlInferenceService;
    private final MLInsightsRepository mlInsightsRepository;
    private final ModelRegistryRepository modelRegistryRepository;

    private BigDecimal toBig(Object o) {
        if (o == null) return BigDecimal.ZERO;
        if (o instanceof BigDecimal bd) return bd;
        if (o instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        throw new IllegalArgumentException("Cannot convert to BigDecimal: " + o);
    }

    @Transactional
    public DailyAggregates aggregateDay(Long userId, LocalDate day) {
        var user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        var start = Timestamp.valueOf(day.atStartOfDay());
        var end = Timestamp.valueOf(day.plusDays(1).atStartOfDay());

        Map<String, Object> m = healthDataRepository.aggregateRange(userId, start, end);

        BigDecimal steps      = toBig(m.get("steps"));
        BigDecimal calories   = toBig(m.get("calories"));
        BigDecimal hrMean     = toBig(m.get("hr_mean"));
        BigDecimal sleepHours = toBig(m.get("sleep"));
        Integer hrMax = m.get("hr_max") != null ? ((Number) m.get("hr_max")).intValue() : 0;

        DailyAggregates agg = dailyAggregatesRepository
                .findByUser_UserIdAndDate(userId, day)
                .orElseGet(DailyAggregates::new);

        agg.setUser(user);
        agg.setDate(day);
        agg.setStepsTotal(steps != null ? steps.intValue() : null);
        agg.setCaloriesTotal(calories);
        agg.setHrMean(hrMean);
        agg.setHrMax(hrMax);
        agg.setSleepHoursTotal(sleepHours);

        LocalDate from = day.minusDays(6);
        LocalDate to = day.minusDays(1);

        var prevAggs = dailyAggregatesRepository
                .findByUser_UserIdAndDateBetweenOrderByDateAsc(userId, from, to);

        double sumSteps = 0.0;
        int countSteps = 0;

        double sumSleep = 0.0;
        int countSleep = 0;

        for (DailyAggregates prev : prevAggs) {
            if (prev.getStepsTotal() != null) {
                sumSteps += prev.getStepsTotal();
                countSteps++;
            }
            if (prev.getSleepHoursTotal() != null) {
                sumSleep += prev.getSleepHoursTotal().doubleValue();
                countSleep++;
            }
        }

        if (steps != null) {
            sumSteps += steps.doubleValue();
            countSteps++;
        }
        if (sleepHours != null) {
            sumSleep += sleepHours.doubleValue();
            countSleep++;
        }

        Double meanSteps = (countSteps > 0) ? (sumSteps / countSteps) : null;
        Double meanSleep = (countSleep > 0) ? (sumSleep / countSleep) : null;

        BigDecimal dSteps7d = null;
        BigDecimal dSleep7d = null;

        if (steps != null && meanSteps != null) {
            dSteps7d = BigDecimal.valueOf(steps.doubleValue() - meanSteps);
        }
        if (sleepHours != null && meanSleep != null) {
            dSleep7d = BigDecimal.valueOf(sleepHours.doubleValue() - meanSleep);
        }

        agg.setZHrMean(null);
        agg.setZSteps(null);
        agg.setDSteps7d(dSteps7d);
        agg.setDSleep7d(dSleep7d);

        var saved = dailyAggregatesRepository.save(agg);

        try {
            double prob = mlInferenceService.predictFatigue(saved);

            ModelRegistry model = modelRegistryRepository
                    .findFirstByNameAndIsActiveTrueOrderByCreatedAtDesc("fatigue_risk")
                    .orElse(null);

            MLInsights insight = MLInsights.builder()
                    .aggregate(saved)
                    .predictionType("fatigue_risk")
                    .probability(BigDecimal.valueOf(prob))
                    .confidenceScore(BigDecimal.valueOf(prob)) // при желании можно завести отдельную метрику
                    .resultDescription(String.format("Fatigue risk: %.2f", prob))
                    .model(model)
                    .build();

            mlInsightsRepository.save(insight);

            recommendationEngineService.evaluate(saved, prob);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return saved;
    }

    public DailyAggregatesDTO convertToDTO(DailyAggregates agg) {
        return DailyAggregatesDTO.builder()
                .aggId(agg.getAggId())
                .userId(agg.getUser() != null ? agg.getUser().getUserId() : null)
                .date(agg.getDate())
                .stepsTotal(agg.getStepsTotal())
                .caloriesTotal(agg.getCaloriesTotal())
                .hrMean(agg.getHrMean())
                .hrMax(agg.getHrMax())
                .sleepHoursTotal(agg.getSleepHoursTotal())
                .build();
    }

    public Optional<DailyAggregatesDTO> findExistingDto(Long userId, LocalDate day) {
        return dailyAggregatesRepository.findByUser_UserIdAndDate(userId, day)
                .map(this::convertToDTO);
    }
}