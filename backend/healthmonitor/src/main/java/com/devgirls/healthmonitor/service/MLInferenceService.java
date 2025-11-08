package com.devgirls.healthmonitor.service;

import ai.onnxruntime.*;
import com.devgirls.healthmonitor.entity.DailyAggregates;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.ModelRegistryRepository; // Мы все еще можем внедрить его, просто не используем в init
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.nio.FloatBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class MLInferenceService {

    private final ModelRegistryRepository modelRegistryRepository;

    private OrtEnvironment env;
    private OrtSession session;
    private List<String> featureOrder;

    @PostConstruct
    public void init() throws Exception {

        log.info("Loading ML model and features from ClassPath...");

        // 1) Load ONNX model from classpath
        env = OrtEnvironment.getEnvironment();

        ClassPathResource onnxRes = new ClassPathResource("models/fatigue_model_v1.onnx");
        if (!onnxRes.exists()) {
            log.error("FATAL: ONNX model not found at {}", "models/fatigue_model_v1.onnx");
            throw new RuntimeException("Missing model file: models/fatigue_model_v1.onnx");
        }
        try (InputStream is = onnxRes.getInputStream()) {
            byte[] bytes = is.readAllBytes();
            session = env.createSession(bytes, new OrtSession.SessionOptions());
        }

        // 2) Load feature order from JSON
        ClassPathResource featRes = new ClassPathResource("models/fatigue_model_v1_features.json");
        if (!featRes.exists()) {
            log.error("FATAL: Features JSON not found at {}", "models/fatigue_model_v1_features.json");
            throw new RuntimeException("Missing features file: models/fatigue_model_v1_features.json");
        }
        try (InputStream is = featRes.getInputStream()) {
            ObjectMapper mapper = new ObjectMapper();

            Map<String, Object> jsonMap = mapper.readValue(is, new TypeReference<Map<String, Object>>() {});

            if (!jsonMap.containsKey("features")) {
                throw new RuntimeException("Features JSON is invalid: missing 'features' key");
            }

            featureOrder = (List<String>) jsonMap.get("features");
        }

        log.info("MLInferenceService initialized. Features ({}): {}", featureOrder.size(), featureOrder);
    }

    /**
     * Main method: builds feature vector from DailyAggregates + User and runs ONNX model.
     * @return probability of fatigue in range [0,1]
     */
    public double predictFatigue(DailyAggregates agg) throws Exception {
        if (session == null || featureOrder == null) {
            throw new IllegalStateException("MLInferenceService is not initialized");
        }

        User user = agg.getUser();
        if (user == null) {
            log.warn("DailyAggregates.user is null for agg_id: {}", agg.getAggId());
            throw new IllegalArgumentException("DailyAggregates.user is null");
        }

        Map<String, Double> f = new HashMap<>();
        f.put("steps_total",        agg.getStepsTotal() != null ? agg.getStepsTotal().doubleValue() : 0.0);
        f.put("calories_total",     agg.getCaloriesTotal() != null ? agg.getCaloriesTotal().doubleValue() : 0.0);
        f.put("sleep_hours_total",  agg.getSleepHoursTotal() != null ? agg.getSleepHoursTotal().doubleValue() : 0.0);
        f.put("age",                user.getAge() != null ? user.getAge().doubleValue() : 0.0);
        f.put("gender_numeric",     mapGender(user.getGender()));
        f.put("height_cm",          user.getHeight() != null ? user.getHeight().doubleValue() : 0.0);
        f.put("weight_kg",          user.getWeight() != null ? user.getWeight().doubleValue() : 0.0);
        f.put("d_sleep_7d",         agg.getDSleep7d() != null ? agg.getDSleep7d().doubleValue() : 0.0);
        f.put("d_steps_7d",         agg.getDSteps7d() != null ? agg.getDSteps7d().doubleValue() : 0.0);

        if (featureOrder.size() != 9) {
            log.error("Mismatch: model expects 9 features, but JSON specified {}", featureOrder.size());
            throw new IllegalStateException("Model/JSON feature count mismatch");
        }

        float[] input = new float[featureOrder.size()];
        for (int i = 0; i < featureOrder.size(); i++) {
            String name = featureOrder.get(i);
            Double val = f.getOrDefault(name, 0.0);
            input[i] = val.floatValue();
        }

        // 3) Create tensor [1, N]
        OnnxTensor tensor = OnnxTensor.createTensor(
                env,
                FloatBuffer.wrap(input),
                new long[]{1, featureOrder.size()}
        );

        String inputName = session.getInputNames().iterator().next();

        try (OrtSession.Result result = session.run(Map.of(inputName, tensor))) {
            String probabilityOutputName = null;
            for (String name : session.getOutputNames()) {
                if (name.toLowerCase().contains("prob")) {
                    probabilityOutputName = name;
                    break;
                }
            }
            if (probabilityOutputName == null && session.getOutputNames().size() > 1) {
                List<String> outputNames = new java.util.ArrayList<>(session.getOutputNames());
                probabilityOutputName = outputNames.get(1);
            }

            if (probabilityOutputName == null) {
                throw new IllegalStateException("Could not find probability output in ONNX model");
            }

            OnnxValue probValue = result.get(probabilityOutputName).orElseThrow();
            Object value = probValue.getValue();

            double prob = 0.0;

            if (value instanceof float[][]) {
                float[][] probs = (float[][]) value;
                prob = probs[0][1];
            } else if (value instanceof List) {
                List<Map<Long, Float>> probsList = (List<Map<Long, Float>>) value;
                Map<Long, Float> probs = probsList.get(0);
                prob = probs.getOrDefault(1L, 0.0f).doubleValue();
            } else {
                throw new RuntimeException("Unexpected ONNX output type: " + value.getClass().getName());
            }

            log.info("Predicted fatigue probability={} for user {}", prob, user.getUserId());
            return prob;
        }
    }

    private double mapGender(String gender) {
        if (gender == null) return 0.0;
        if (gender.toUpperCase().startsWith("M")) return 1.0; // Male
        if (gender.toUpperCase().startsWith("F")) return 0.0; // Female
        return 0.0;
    }
}