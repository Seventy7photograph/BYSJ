package bysj.pets.bec.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import jakarta.annotation.Resource;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.TimeUnit;

/**
 * Redis缓存工具类
 */
@Component
public class RedisCacheUtil {

    private static final Logger logger = LoggerFactory.getLogger(RedisCacheUtil.class);

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    // 缓存命中计数器
    private static final AtomicLong cacheHitCount = new AtomicLong(0);
    // 缓存未命中计数器
    private static final AtomicLong cacheMissCount = new AtomicLong(0);

    /**
     * 设置缓存
     * @param key 缓存键
     * @param value 缓存值
     * @param expireTime 过期时间（秒）
     */
    public void setCache(String key, Object value, long expireTime) {
        try {
            redisTemplate.opsForValue().set(key, value, expireTime, TimeUnit.SECONDS);
            logger.info("Redis缓存设置成功，键: {}, 过期时间: {}秒", key, expireTime);
        } catch (Exception e) {
            logger.error("Redis缓存设置失败，键: {}", key, e);
            throw e;
        }
    }

    /**
     * 获取缓存
     * @param key 缓存键
     * @return 缓存值
     */
    public Object getCache(String key) {
        try {
            Object value = redisTemplate.opsForValue().get(key);
            if (value != null) {
                cacheHitCount.incrementAndGet();
                logger.debug("Redis缓存命中，键: {}", key);
            } else {
                cacheMissCount.incrementAndGet();
                logger.debug("Redis缓存未命中，键: {}", key);
            }
            return value;
        } catch (Exception e) {
            logger.error("Redis缓存获取失败，键: {}", key, e);
            return null;
        }
    }

    /**
     * 删除缓存
     * @param key 缓存键
     */
    public void deleteCache(String key) {
        try {
            redisTemplate.delete(key);
            logger.info("Redis缓存删除成功，键: {}", key);
        } catch (Exception e) {
            logger.error("Redis缓存删除失败，键: {}", key, e);
        }
    }

    /**
     * 缓存是否存在
     * @param key 缓存键
     * @return 是否存在
     */
    public boolean hasKey(String key) {
        try {
            return redisTemplate.hasKey(key);
        } catch (Exception e) {
            logger.error("Redis缓存检查失败，键: {}", key, e);
            return false;
        }
    }

    /**
     * 设置缓存过期时间
     * @param key 缓存键
     * @param expireTime 过期时间（秒）
     */
    public void expire(String key, long expireTime) {
        try {
            redisTemplate.expire(key, expireTime, TimeUnit.SECONDS);
            logger.info("Redis缓存过期时间设置成功，键: {}, 过期时间: {}秒", key, expireTime);
        } catch (Exception e) {
            logger.error("Redis缓存过期时间设置失败，键: {}", key, e);
        }
    }

    /**
     * 获取缓存命中率
     * @return 缓存命中率
     */
    public double getCacheHitRate() {
        long total = cacheHitCount.get() + cacheMissCount.get();
        if (total == 0) {
            return 0.0;
        }
        return (double) cacheHitCount.get() / total;
    }

    /**
     * 重置缓存统计计数器
     */
    public void resetCacheStats() {
        cacheHitCount.set(0);
        cacheMissCount.set(0);
        logger.info("Redis缓存统计计数器已重置");
    }

    /**
     * 获取缓存统计信息
     * @return 缓存统计信息
     */
    public String getCacheStats() {
        long hit = cacheHitCount.get();
        long miss = cacheMissCount.get();
        long total = hit + miss;
        double hitRate = total > 0 ? (double) hit / total : 0.0;
        
        return String.format("缓存统计: 总请求数=%d, 命中数=%d, 未命中数=%d, 命中率=%.2f%%", 
                total, hit, miss, hitRate * 100);
    }
}
