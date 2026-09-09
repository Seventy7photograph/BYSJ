package bysj.pets.bec.service.impl;

import bysj.pets.bec.service.InventoryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 库存管理服务性能测试
 */
@SpringBootTest
public class InventoryServicePerformanceTest {

    @Autowired
    private InventoryService inventoryService;

    /**
     * 测试库存列表查询性能
     */
    @Test
    public void testInventoryListPerformance() {
        // 构建查询参数
        Map<String, Object> params = new HashMap<>();
        params.put("pageNum", 1);
        params.put("pageSize", 10);
        
        // 预热缓存
        System.out.println("预热缓存...");
        for (int i = 0; i < 5; i++) {
            inventoryService.getInventoryList(params);
        }
        
        // 测试缓存查询性能
        System.out.println("测试缓存查询性能...");
        long cacheStartTime = System.nanoTime();
        for (int i = 0; i < 100; i++) {
            inventoryService.getInventoryList(params);
        }
        long cacheEndTime = System.nanoTime();
        long cacheDuration = TimeUnit.NANOSECONDS.toMillis(cacheEndTime - cacheStartTime);
        System.out.println("缓存查询100次耗时: " + cacheDuration + "ms");
        System.out.println("缓存查询平均耗时: " + (cacheDuration / 100.0) + "ms");
    }

    /**
     * 测试库存详情查询性能
     */
    @Test
    public void testInventoryDetailPerformance() {
        // 假设存在库存ID为1的记录
        Long inventoryId = 1L;
        
        // 预热缓存
        System.out.println("预热缓存...");
        for (int i = 0; i < 5; i++) {
            inventoryService.getInventoryDetail(inventoryId);
        }
        
        // 测试缓存查询性能
        System.out.println("测试缓存查询性能...");
        long cacheStartTime = System.nanoTime();
        for (int i = 0; i < 100; i++) {
            inventoryService.getInventoryDetail(inventoryId);
        }
        long cacheEndTime = System.nanoTime();
        long cacheDuration = TimeUnit.NANOSECONDS.toMillis(cacheEndTime - cacheStartTime);
        System.out.println("缓存查询100次耗时: " + cacheDuration + "ms");
        System.out.println("缓存查询平均耗时: " + (cacheDuration / 100.0) + "ms");
    }

    /**
     * 测试库存历史记录查询性能
     */
    @Test
    public void testInventoryHistoryPerformance() {
        // 假设存在库存ID为1的记录
        Long inventoryId = 1L;
        Integer pageNum = 1;
        Integer pageSize = 10;
        
        // 预热缓存
        System.out.println("预热缓存...");
        for (int i = 0; i < 5; i++) {
            inventoryService.getInventoryHistory(inventoryId, pageNum, pageSize);
        }
        
        // 测试缓存查询性能
        System.out.println("测试缓存查询性能...");
        long cacheStartTime = System.nanoTime();
        for (int i = 0; i < 100; i++) {
            inventoryService.getInventoryHistory(inventoryId, pageNum, pageSize);
        }
        long cacheEndTime = System.nanoTime();
        long cacheDuration = TimeUnit.NANOSECONDS.toMillis(cacheEndTime - cacheStartTime);
        System.out.println("缓存查询100次耗时: " + cacheDuration + "ms");
        System.out.println("缓存查询平均耗时: " + (cacheDuration / 100.0) + "ms");
    }
}
