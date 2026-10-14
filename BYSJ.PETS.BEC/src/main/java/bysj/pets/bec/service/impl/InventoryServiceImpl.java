package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.Inventory;
import bysj.pets.bec.entity.InventoryHistory;
import bysj.pets.bec.entity.vo.InventoryHistoryVO;
import bysj.pets.bec.entity.vo.InventoryItemVO;
import bysj.pets.bec.mapper.InventoryHistoryMapper;
import bysj.pets.bec.mapper.InventoryMapper;
import bysj.pets.bec.service.InventoryService;
import bysj.pets.bec.utils.InventoryCacheKeyGenerator;
import bysj.pets.bec.utils.RedisCacheUtil;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * 库存管理服务实现类
 */
@Service
@Slf4j
public class InventoryServiceImpl extends ServiceImpl<InventoryMapper, Inventory> implements InventoryService {
    
    @Autowired
    private InventoryMapper inventoryMapper;
    
    @Autowired
    private InventoryHistoryMapper inventoryHistoryMapper;
    
    @Autowired
    private RedisCacheUtil redisCacheUtil;

    @Autowired
    private bysj.pets.bec.mapper.ProductMapper productMapper;
    
    @Override
    public IPage<InventoryItemVO> getInventoryList(Map<String, Object> params) {
        // 生成缓存键
        String cacheKey = InventoryCacheKeyGenerator.generateInventoryListKey(params);
        
        // 尝试从缓存获取
        try {
            Object cachedData = redisCacheUtil.getCache(cacheKey);
            if (cachedData != null && cachedData instanceof Page) {
                return (IPage<InventoryItemVO>) cachedData;
            }
        } catch (Exception e) {
            // 缓存异常，降级到数据库查询
            System.err.println("Redis缓存异常: " + e.getMessage());
        }
        
        // 从数据库查询
        Integer pageNum = (Integer) params.get("pageNum");
        Integer pageSize = (Integer) params.get("pageSize");
        String productType = (String) params.get("productType");
        String stockStatus = (String) params.get("stockStatus");
        String keyword = (String) params.get("keyword");
        Long sellerId = (Long) params.get("sellerId");
        
        // 创建分页对象
        Page<InventoryItemVO> page = new Page<>(pageNum, pageSize);
        
        // 查询库存列表
        List<InventoryItemVO> inventoryList = inventoryMapper.selectInventoryList(productType, stockStatus, keyword, sellerId);
        page.setRecords(inventoryList);
        
        // 查询总数
        long total = inventoryMapper.selectInventoryTotal(productType, stockStatus, keyword, sellerId);
        page.setTotal(total);
        
        // 缓存结果，过期时间5分钟
        try {
            redisCacheUtil.setCache(cacheKey, page, 300);
        } catch (Exception e) {
            // 缓存异常，不影响业务
            System.err.println("Redis缓存设置异常: " + e.getMessage());
        }
        
        return page;
    }
    
    @Override
    public InventoryItemVO getInventoryDetail(Long inventoryId) {
        // 生成缓存键
        String cacheKey = InventoryCacheKeyGenerator.generateInventoryDetailKey(inventoryId);
        
        // 尝试从缓存获取
        try {
            Object cachedData = redisCacheUtil.getCache(cacheKey);
            if (cachedData != null && cachedData instanceof InventoryItemVO) {
                return (InventoryItemVO) cachedData;
            }
        } catch (Exception e) {
            // 缓存异常，降级到数据库查询
            System.err.println("Redis缓存异常: " + e.getMessage());
        }
        
        // 从数据库查询
        InventoryItemVO inventoryDetail = inventoryMapper.selectInventoryDetail(inventoryId);
        
        // 缓存结果，过期时间10分钟
        try {
            if (inventoryDetail != null) {
                redisCacheUtil.setCache(cacheKey, inventoryDetail, 600);
            }
        } catch (Exception e) {
            // 缓存异常，不影响业务
            System.err.println("Redis缓存设置异常: " + e.getMessage());
        }
        
        return inventoryDetail;
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean adjustInventory(Long inventoryId, String adjustType, Integer adjustQuantity, String reason, Integer minStock) {
        // 查询当前库存
        Inventory inventory = inventoryMapper.selectById(inventoryId);
        if (inventory == null) {
            return false;
        }
        
        Integer currentStock = inventory.getCurrentStock();
        Integer newStock = currentStock;
        
        // 根据调整类型计算新库存
        if ("增加".equals(adjustType)) {
            newStock += adjustQuantity;
        } else if ("减少".equals(adjustType)) {
            newStock -= adjustQuantity;
        } else if ("直接设置".equals(adjustType)) {
            newStock = adjustQuantity;
        }
        
        // 更新库存和安全库存
        boolean updateResult;
        if (minStock != null) {
            updateResult = inventoryMapper.updateProductStockAndMinStock(inventoryId, newStock, minStock);
        } else {
            updateResult = inventoryMapper.updateProductStock(inventoryId, newStock);
        }
        
        if (!updateResult) {
            return false;
        }

        // 商家调整库存后，把权威库存(product.stock)一起更新。
        // 这一步原来靠数据库触发器隐式完成，而那个触发器会和下单时的
        // "product → inventory" 镜像互相冲突（MySQL 1442），已经去掉；
        // 现在两边都由业务代码显式、单向地维护。
        if (inventory.getProductId() != null) {
            productMapper.updateProductStock(inventory.getProductId(), newStock);
        }

        // 插入库存变更历史
        InventoryHistory history = new InventoryHistory();
        history.setInventoryId(inventoryId);
        history.setChangeTime(new Date());
        history.setChangeType(adjustType);
        history.setBeforeStock(currentStock);
        history.setAfterStock(newStock);
        history.setChangeQuantity("直接设置".equals(adjustType) ? newStock - currentStock : adjustQuantity);
        history.setReason(reason);
        history.setOperator("管理员");
        
        boolean insertResult = inventoryHistoryMapper.insert(history) > 0;
        
        // 清除相关缓存
        if (insertResult) {
            try {
                // 清除库存详情缓存
                String detailCacheKey = InventoryCacheKeyGenerator.generateInventoryDetailKey(inventoryId);
                redisCacheUtil.deleteCache(detailCacheKey);

                // 清除该商品的所有历史记录分页缓存
                redisCacheUtil.deleteByPrefix(
                        InventoryCacheKeyGenerator.getInventoryHistoryPrefix() + inventoryId);

                // 清除所有库存列表缓存（列表键包含查询条件，只能按前缀清）。
                // 原实现只把前缀算出来就结束了，一行都没删 —— 调整库存后列表会
                // 在最长 5 分钟内继续显示旧数字。
                redisCacheUtil.deleteByPrefix(InventoryCacheKeyGenerator.getInventoryListPrefix());
            } catch (Exception e) {
                // 缓存清除异常，不影响业务
                log.warn("库存调整后清理缓存失败: {}", e.getMessage());
            }
        }
        
        return insertResult;
    }
    
    @Override
    public IPage<InventoryHistoryVO> getInventoryHistory(Long inventoryId, Integer pageNum, Integer pageSize) {
        // 生成缓存键
        String cacheKey = InventoryCacheKeyGenerator.generateInventoryHistoryKey(inventoryId, pageNum, pageSize);
        
        // 尝试从缓存获取
        try {
            Object cachedData = redisCacheUtil.getCache(cacheKey);
            if (cachedData != null && cachedData instanceof Page) {
                return (IPage<InventoryHistoryVO>) cachedData;
            }
        } catch (Exception e) {
            // 缓存异常，降级到数据库查询
            System.err.println("Redis缓存异常: " + e.getMessage());
        }
        
        // 从数据库查询
        // 创建分页对象
        Page<InventoryHistoryVO> page = new Page<>(pageNum, pageSize);
        
        // 查询库存变更历史
        List<InventoryHistoryVO> historyList = inventoryHistoryMapper.selectInventoryHistory(inventoryId);
        page.setRecords(historyList);
        
        // 查询总数
        long total = inventoryHistoryMapper.selectInventoryHistoryTotal(inventoryId);
        page.setTotal(total);
        
        // 缓存结果，过期时间3分钟
        try {
            redisCacheUtil.setCache(cacheKey, page, 180);
        } catch (Exception e) {
            // 缓存异常，不影响业务
            System.err.println("Redis缓存设置异常: " + e.getMessage());
        }
        
        return page;
    }
    
    @Override
    public boolean setMinStock(Long inventoryId, Integer minStock) {
        boolean result = inventoryMapper.updateMinStock(inventoryId, minStock);
        
        // 清除相关缓存
        if (result) {
            try {
                // 清除库存详情缓存
                String detailCacheKey = InventoryCacheKeyGenerator.generateInventoryDetailKey(inventoryId);
                redisCacheUtil.deleteCache(detailCacheKey);

                // 安全库存影响列表里的库存状态判定，列表缓存同样要清
                redisCacheUtil.deleteByPrefix(InventoryCacheKeyGenerator.getInventoryListPrefix());
            } catch (Exception e) {
                // 缓存清除异常，不影响业务
                log.warn("安全库存变更后清理缓存失败: {}", e.getMessage());
            }
        }
        
        return result;
    }
}
