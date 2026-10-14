package bysj.pets.bec.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Redis自定义配置（解决序列化问题）
 */
@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(factory);

        // 1. 创建JSON序列化器
        Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<>(Object.class);
        ObjectMapper objectMapper = new ObjectMapper();
        // 允许序列化所有字段
        objectMapper.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        // 开启类型信息，反序列化时能识别对象类型（解决多类型反序列化问题）
        objectMapper.activateDefaultTyping(LaissezFaireSubTypeValidator.instance, ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(objectMapper);

        // 2. String序列化器（键用String）
        StringRedisSerializer stringRedisSerializer = new StringRedisSerializer();

        // 3. 配置序列化规则
        redisTemplate.setKeySerializer(stringRedisSerializer);          // 键序列化
        redisTemplate.setHashKeySerializer(stringRedisSerializer);     // Hash键序列化
        redisTemplate.setValueSerializer(jackson2JsonRedisSerializer); // 值序列化
        redisTemplate.setHashValueSerializer(jackson2JsonRedisSerializer); // Hash值序列化

        redisTemplate.afterPropertiesSet();
        return redisTemplate;
    }
}