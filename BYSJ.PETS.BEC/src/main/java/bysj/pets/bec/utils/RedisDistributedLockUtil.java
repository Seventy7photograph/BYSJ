package bysj.pets.bec.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import jakarta.annotation.Resource;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Redis分布式锁工具类
 * 实现基于Redis的分布式锁机制，确保在分布式环境下的资源竞争安全
 */
@Component
public class RedisDistributedLockUtil {

    private static final Logger logger = LoggerFactory.getLogger(RedisDistributedLockUtil.class);

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    // 本地锁，用于防止同一JVM内的并发问题
    private final Lock localLock = new ReentrantLock();

    /**
     * 获取分布式锁
     * @param lockKey 锁的键
     * @param requestId 请求标识（用于防止误释放）
     * @param expireTime 过期时间（秒）
     * @return 是否获取成功
     */
    public boolean acquireLock(String lockKey, String requestId, long expireTime) {
        try {
            // 先获取本地锁，防止同一JVM内的并发
            localLock.lock();

            // 使用Redis的setnx命令获取分布式锁
            Boolean result = redisTemplate.opsForValue().setIfAbsent(lockKey, requestId, expireTime, TimeUnit.SECONDS);
            if (Boolean.TRUE.equals(result)) {
                logger.info("获取分布式锁成功，锁键: {}, 请求标识: {}", lockKey, requestId);
                return true;
            } else {
                logger.info("获取分布式锁失败，锁键: {}, 请求标识: {}", lockKey, requestId);
                return false;
            }
        } catch (Exception e) {
            logger.error("获取分布式锁异常，锁键: {}", lockKey, e);
            return false;
        } finally {
            localLock.unlock();
        }
    }

    /**
     * 释放分布式锁
     * @param lockKey 锁的键
     * @param requestId 请求标识（用于防止误释放）
     * @return 是否释放成功
     */
    public boolean releaseLock(String lockKey, String requestId) {
        try {
            // 先获取本地锁，防止同一JVM内的并发
            localLock.lock();

            // 获取锁对应的请求标识
            Object currentRequestId = redisTemplate.opsForValue().get(lockKey);
            if (currentRequestId != null && currentRequestId.equals(requestId)) {
                // 只有当锁的请求标识与当前请求标识一致时，才释放锁
                Boolean result = redisTemplate.delete(lockKey);
                if (Boolean.TRUE.equals(result)) {
                    logger.info("释放分布式锁成功，锁键: {}, 请求标识: {}", lockKey, requestId);
                    return true;
                } else {
                    logger.info("释放分布式锁失败，锁键: {}, 请求标识: {}", lockKey, requestId);
                    return false;
                }
            } else {
                logger.info("释放分布式锁失败，锁键: {}, 请求标识不匹配或锁不存在", lockKey);
                return false;
            }
        } catch (Exception e) {
            logger.error("释放分布式锁异常，锁键: {}", lockKey, e);
            return false;
        } finally {
            localLock.unlock();
        }
    }

    /**
     * 尝试获取分布式锁，带重试机制
     * @param lockKey 锁的键
     * @param requestId 请求标识
     * @param expireTime 过期时间（秒）
     * @param retryTimes 重试次数
     * @param retryInterval 重试间隔（毫秒）
     * @return 是否获取成功
     */
    public boolean tryAcquireLock(String lockKey, String requestId, long expireTime, int retryTimes, long retryInterval) {
        boolean acquired = acquireLock(lockKey, requestId, expireTime);
        int currentRetry = 0;

        while (!acquired && currentRetry < retryTimes) {
            try {
                Thread.sleep(retryInterval);
                acquired = acquireLock(lockKey, requestId, expireTime);
                currentRetry++;
            } catch (InterruptedException e) {
                logger.error("重试获取分布式锁被中断", e);
                Thread.currentThread().interrupt();
                break;
            }
        }

        if (!acquired) {
            logger.warn("尝试获取分布式锁失败，已达到最大重试次数，锁键: {}", lockKey);
        }

        return acquired;
    }

    /**
     * 检查锁是否存在
     * @param lockKey 锁的键
     * @return 是否存在
     */
    public boolean isLockExist(String lockKey) {
        try {
            return redisTemplate.hasKey(lockKey);
        } catch (Exception e) {
            logger.error("检查锁是否存在异常，锁键: {}", lockKey, e);
            return false;
        }
    }

    /**
     * 延长锁的过期时间
     * @param lockKey 锁的键
     * @param requestId 请求标识
     * @param expireTime 新的过期时间（秒）
     * @return 是否延长成功
     */
    public boolean extendLockExpireTime(String lockKey, String requestId, long expireTime) {
        try {
            // 先获取本地锁，防止同一JVM内的并发
            localLock.lock();

            // 获取锁对应的请求标识
            Object currentRequestId = redisTemplate.opsForValue().get(lockKey);
            if (currentRequestId != null && currentRequestId.equals(requestId)) {
                // 只有当锁的请求标识与当前请求标识一致时，才延长锁的过期时间
                Boolean result = redisTemplate.expire(lockKey, expireTime, TimeUnit.SECONDS);
                if (Boolean.TRUE.equals(result)) {
                    logger.info("延长分布式锁过期时间成功，锁键: {}, 请求标识: {}, 新过期时间: {}秒", lockKey, requestId, expireTime);
                    return true;
                } else {
                    logger.info("延长分布式锁过期时间失败，锁键: {}, 请求标识: {}", lockKey, requestId);
                    return false;
                }
            } else {
                logger.info("延长分布式锁过期时间失败，锁键: {}, 请求标识不匹配或锁不存在", lockKey);
                return false;
            }
        } catch (Exception e) {
            logger.error("延长分布式锁过期时间异常，锁键: {}", lockKey, e);
            return false;
        } finally {
            localLock.unlock();
        }
    }
}
