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

        // выполняем нативный SQL
        Map<String, Object> m = healthDataRepository.aggregateRange(userId, start, end);

        // Используем безопасное извлечение
        BigDecimal steps      = toBig(m.get("steps"));      // ← БЫЛО Integer, стало BigDecimal
        BigDecimal calories   = toBig(m.get("calories"));
        BigDecimal hrMean     = toBig(m.get("hr_mean"));
        BigDecimal sleepHours = toBig(m.get("sleep"));
        Integer hrMax = m.get("hr_max") != null ? ((Number)m.get("hr_max")).intValue() : 0;

        // Получаем или создаём DailyAggregates
        DailyAggregates agg = dailyAggregatesRepository
                .findByUser_UserIdAndDate(userId, day)
                .orElseGet(DailyAggregates::new);

        agg.setUser(user);
        agg.setDate(day);
        agg.setStepsTotal(steps.intValue());        // если поле Integer
        agg.setCaloriesTotal(calories);
        agg.setHrMean(hrMean);
        agg.setHrMax(hrMax);
        agg.setSleepHoursTotal(sleepHours);

        // остальные поля пока null
        agg.setZHrMean(null);
        agg.setZSteps(null);
        agg.setDSteps7d(null);
        agg.setDSleep7d(null);

//        return dailyAggregatesRepository.save(agg);
        var saved = dailyAggregatesRepository.save(agg);

        try {
            double prob = mlInferenceService.predictFatigue(saved);

            // find active model for reference
            ModelRegistry model = modelRegistryRepository
                    .findFirstByNameAndIsActiveTrueOrderByCreatedAtDesc("fatigue_risk")
                    .orElse(null);

            MLInsights insight = MLInsights.builder()
                    .aggregate(saved) // make sure MLInsights has a field: @ManyToOne DailyAggregates agg;
                    .predictionType("fatigue_risk")
                    .probability(BigDecimal.valueOf(prob))
                    .confidenceScore(BigDecimal.valueOf(prob)) // or something else
                    .resultDescription(String.format("Fatigue risk: %.2f", prob))
                    .model(model)
                    .build();

            mlInsightsRepository.save(insight);

            // call rules + ML-based recommendations
            recommendationEngineService.evaluate(saved, prob);

        } catch (Exception e) {
            // Do not break the request if ML fails
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