package bysj.pets.bec.utils;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Redis分布式锁工具类测试
 */
class RedisDistributedLockUtilTest {

    @Mock
    private RedisTemplate<String, Object> redisTemplate;

    @Mock
    private ValueOperations<String, Object> valueOperations;

    private RedisDistributedLockUtil redisDistributedLockUtil;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        redisDistributedLockUtil = new RedisDistributedLockUtil();
        // 使用反射设置redisTemplate
        try {
            java.lang.reflect.Field field = RedisDistributedLockUtil.class.getDeclaredField("redisTemplate");
            field.setAccessible(true);
            field.set(redisDistributedLockUtil, redisTemplate);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    void testAcquireLock_Success() {
        // 模拟获取锁成功
        when(valueOperations.setIfAbsent("testLock", "requestId1", 30, TimeUnit.SECONDS)).thenReturn(true);

        boolean result = redisDistributedLockUtil.acquireLock("testLock", "requestId1", 30);
        assertTrue(result);
        verify(valueOperations, times(1)).setIfAbsent("testLock", "requestId1", 30, TimeUnit.SECONDS);
    }

    @Test
    void testAcquireLock_Failure() {
        // 模拟获取锁失败
        when(valueOperations.setIfAbsent("testLock", "requestId1", 30, TimeUnit.SECONDS)).thenReturn(false);

        boolean result = redisDistributedLockUtil.acquireLock("testLock", "requestId1", 30);
        assertFalse(result);
        verify(valueOperations, times(1)).setIfAbsent("testLock", "requestId1", 30, TimeUnit.SECONDS);
    }

    @Test
    void testReleaseLock_Success() {
        // 模拟锁存在且请求标识匹配
        when(valueOperations.get("testLock")).thenReturn("requestId1");
        when(redisTemplate.delete("testLock")).thenReturn(true);

        boolean result = redisDistributedLockUtil.releaseLock("testLock", "requestId1");
        assertTrue(result);
        verify(valueOperations, times(1)).get("testLock");
        verify(redisTemplate, times(1)).delete("testLock");
    }

    @Test
    void testReleaseLock_Failure_RequestIdMismatch() {
        // 模拟锁存在但请求标识不匹配
        when(valueOperations.get("testLock")).thenReturn("requestId2");

        boolean result = redisDistributedLockUtil.releaseLock("testLock", "requestId1");
        assertFalse(result);
        verify(valueOperations, times(1)).get("testLock");
        verify(redisTemplate, never()).delete("testLock");
    }

    @Test
    void testReleaseLock_Failure_LockNotExist() {
        // 模拟锁不存在
        when(valueOperations.get("testLock")).thenReturn(null);

        boolean result = redisDistributedLockUtil.releaseLock("testLock", "requestId1");
        assertFalse(result);
        verify(valueOperations, times(1)).get("testLock");
        verify(redisTemplate, never()).delete("testLock");
    }

    @Test
    void testIsLockExist_Exists() {
        // 模拟锁存在
        when(redisTemplate.hasKey("testLock")).thenReturn(true);

        boolean result = redisDistributedLockUtil.isLockExist("testLock");
        assertTrue(result);
        verify(redisTemplate, times(1)).hasKey("testLock");
    }

    @Test
    void testIsLockExist_NotExists() {
        // 模拟锁不存在
        when(redisTemplate.hasKey("testLock")).thenReturn(false);

        boolean result = redisDistributedLockUtil.isLockExist("testLock");
        assertFalse(result);
        verify(redisTemplate, times(1)).hasKey("testLock");
    }

    @Test
    void testExtendLockExpireTime_Success() {
        // 模拟锁存在且请求标识匹配
        when(valueOperations.get("testLock")).thenReturn("requestId1");
        when(redisTemplate.expire("testLock", 60, TimeUnit.SECONDS)).thenReturn(true);

        boolean result = redisDistributedLockUtil.extendLockExpireTime("testLock", "requestId1", 60);
        assertTrue(result);
        verify(valueOperations, times(1)).get("testLock");
        verify(redisTemplate, times(1)).expire("testLock", 60, TimeUnit.SECONDS);
    }

    @Test
    void testExtendLockExpireTime_Failure_RequestIdMismatch() {
        // 模拟锁存在但请求标识不匹配
        when(valueOperations.get("testLock")).thenReturn("requestId2");

        boolean result = redisDistributedLockUtil.extendLockExpireTime("testLock", "requestId1", 60);
        assertFalse(result);
        verify(valueOperations, times(1)).get("testLock");
        verify(redisTemplate, never()).expire(anyString(), anyLong(), any(TimeUnit.class));
    }
}
