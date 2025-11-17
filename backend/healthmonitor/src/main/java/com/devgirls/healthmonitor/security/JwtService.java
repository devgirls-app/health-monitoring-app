package com.devgirls.healthmonitor.security;

import com.devgirls.healthmonitor.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    // ВАЖНО: Это секретный ключ. В реальном проекте он должен быть в application.yml
    // Он должен быть длинным (минимум 256 бит / 32 символа)
    // Здесь используется Hex-строка для примера.
    private static final String SECRET_KEY = "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970";

    // Генерация токена для пользователя
    public String generateToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        // Можно добавить в токен дополнительные данные, например ID или роль
        claims.put("id", user.getId());
        claims.put("name", user.getName());

        return createToken(claims, user.getEmail());
    }

    // Создание самого токена
    private String createToken(Map<String, Object> extraClaims, String subject) {
        return Jwts.builder()
                .claims(extraClaims)
                .subject(subject) // В качестве subject используем email
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 24)) // Действует 24 часа
                .signWith(getSigningKey())
                .compact();
    }

    // Извлечение email (username) из токена
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    // Проверка валидности токена
    public boolean isTokenValid(String token, String userEmail) {
        final String username = extractUsername(token);
        return (username.equals(userEmail)) && !isTokenExpired(token);
    }

    // --- Вспомогательные методы ---

    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(SECRET_KEY);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
