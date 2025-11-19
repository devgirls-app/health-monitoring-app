package com.devgirls.healthmonitor.service;

import com.devgirls.healthmonitor.dto.DailyAggregatesDTO;
import com.devgirls.healthmonitor.entity.*;
import com.devgirls.healthmonitor.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.*;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
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
        agg.setStepsTotal(steps.intValue());
        agg.setCaloriesTotal(calories);
        agg.setHrMean(hrMean);
        agg.setHrMax(hrMax);
        agg.setSleepHoursTotal(sleepHours);

        LocalDate from = day.minusDays(6);
        LocalDate to = day.minusDays(1);

        var prevAggs = dailyAggregatesRepository
                .findByUser_UserIdAndDateBetweenOrderByDateAsc(userId, from, to);

        double sumStepsPrev = 0.0;
        int countStepsPrev = 0;

        double sumSleepPrev = 0.0;
        int countSleepPrev = 0;

        for (DailyAggregates prev : prevAggs) {
            if (prev.getStepsTotal() != null && prev.getStepsTotal() > 0) {
                sumStepsPrev += prev.getStepsTotal();
                countStepsPrev++;
            }
            if (prev.getSleepHoursTotal() != null && prev.getSleepHoursTotal().compareTo(BigDecimal.ZERO) > 0) {
                sumSleepPrev += prev.getSleepHoursTotal().doubleValue();
                countSleepPrev++;
            }
        }

        BigDecimal meanStepsPrev = (countStepsPrev > 0)
                ? BigDecimal.valueOf(sumStepsPrev).divide(BigDecimal.valueOf(countStepsPrev), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        BigDecimal meanSleepPrev = (countSleepPrev > 0)
                ? BigDecimal.valueOf(sumSleepPrev).divide(BigDecimal.valueOf(countSleepPrev), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        BigDecimal dSteps7d = null;
        BigDecimal dSleep7d = null;

        dSteps7d = steps.subtract(meanStepsPrev).setScale(2, RoundingMode.HALF_UP);

        dSleep7d = sleepHours.subtract(meanSleepPrev).setScale(2, RoundingMode.HALF_UP);

        agg.setZHrMean(null);
        agg.setZSteps(null);
        agg.setDSteps7d(dSteps7d);
        agg.setDSleep7d(dSleep7d);

        var saved = dailyAggregatesRepository.save(agg);

        try {
            double prob = mlInferenceService.predictFatigue(saved);

            log.info("ML features calculated for user {} on {}: Steps Delta={}; Sleep Delta={}",
                    userId, day, dSteps7d, dSleep7d);
            log.info("ML Probability: {}", prob);


            ModelRegistry model = modelRegistryRepository
                    .findFirstByNameAndIsActiveTrueOrderByCreatedAtDesc("fatigue_risk")
                    .orElse(null);

            MLInsights insight = MLInsights.builder()
                    .aggregate(saved)
                    .predictionType("fatigue_risk")
                    .probability(BigDecimal.valueOf(prob))
                    .confidenceScore(BigDecimal.valueOf(prob))
                    .resultDescription(String.format("Fatigue risk: %.2f", prob))
                    .model(model)
                    .build();

            mlInsightsRepository.save(insight);

            recommendationEngineService.evaluate(saved, prob);

        } catch (Exception e) {
            log.error("ML Inference failed for user {} on date {}", userId, day, e);
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