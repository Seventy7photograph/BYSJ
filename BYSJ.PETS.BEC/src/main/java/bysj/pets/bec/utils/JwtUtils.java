package bysj.pets.bec.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.security.Key;
import java.util.Date;
import java.util.function.Function;

@Component
public class JwtUtils {


    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expire}") // 有效期（毫秒），86400000=24小时
    private long expire;

    // 生成256位(32字节)的HMAC-SHA256密钥
    //private static final SecretKey SECRET_KEY = Keys.secretKeyFor(SignatureAlgorithm.HS256);

    // 生成JWT令牌，包含角色信息（重载方法，支持默认角色）
    public String generateToken(String username) {
        // 默认角色为空数组
        return generateToken(username, new String[]{});
    }

    // 生成JWT令牌，包含角色信息
    public String generateToken(String username, String[] roles) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + expire);

        Key key = Keys.hmacShaKeyFor(secret.getBytes());

        return Jwts.builder()
                .setSubject(username)
                .claim("roles", roles)
                .setIssuedAt(new Date())
                .setExpiration(expiration)
                .signWith(key)
                .compact();
    }


    // 从令牌中获取用户名
    public String getUsernameFromToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(Keys.hmacShaKeyFor(secret.getBytes()))
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
            return claims.getSubject();
        } catch (Exception e) {
            // 令牌无效，返回null
            return null;
        }
    }

    // 验证令牌是否有效
    public boolean validateToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(Keys.hmacShaKeyFor(secret.getBytes()))
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
            // 检查token是否过期
            Date expiration = claims.getExpiration();
            if (expiration.before(new Date())) {
                return false;
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }


    // 从令牌中提取用户名
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    // 验证令牌是否有效（包含用户名匹配和令牌未过期检查）
    public boolean isTokenValid(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    // 辅助方法：从令牌中提取声明
    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    // 辅助方法：从令牌中提取所有声明
    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(Keys.hmacShaKeyFor(secret.getBytes()))
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    // 辅助方法：检查令牌是否过期
    private boolean isTokenExpired(String token) {
        final Date expiration = extractExpiration(token);
        return expiration.before(new Date());
    }

    // 从令牌中提取过期时间
    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
    
    // 从令牌中提取角色列表
    public String[] getRolesFromToken(String token) {
        Claims claims = extractAllClaims(token);
        Object rolesObj = claims.get("roles");
        
        // 处理不同类型的角色数据
        if (rolesObj != null) {
            if (rolesObj instanceof String[]) {
                return (String[]) rolesObj;
            } else if (rolesObj instanceof java.util.List<?>) {
                // 处理JWT解析时String[]转为List<String>的情况
                java.util.List<?> rolesList = (java.util.List<?>) rolesObj;
                return rolesList.stream()
                        .filter(item -> item instanceof String)
                        .map(item -> (String) item)
                        .toArray(String[]::new);
            } else if (rolesObj instanceof String) {
                // 处理单个角色的情况
                return new String[]{(String) rolesObj};
            }
        }
        return new String[0];
    }

// ... 现有 validateToken 方法 ...
}