package bysj.pets.bec.utils;

import java.util.Map;

/**
 * 库存管理缓存键生成器
 */
public class InventoryCacheKeyGenerator {

    // 缓存键前缀
    private static final String INVENTORY_LIST_PREFIX = "inventory:list:";
    private static final String INVENTORY_DETAIL_PREFIX = "inventory:detail:";
    private static final String INVENTORY_HISTORY_PREFIX = "inventory:history:";

    /**
     * 生成库存列表缓存键
     * @param params 查询参数
     * @return 缓存键
     */
    public static String generateInventoryListKey(Map<String, Object> params) {
        StringBuilder key = new StringBuilder(INVENTORY_LIST_PREFIX);
        
        // 包含查询参数
        Integer pageNum = (Integer) params.get("pageNum");
        Integer pageSize = (Integer) params.get("pageSize");
        String productType = (String) params.get("productType");
        String stockStatus = (String) params.get("stockStatus");
        String keyword = (String) params.get("keyword");
        Long sellerId = (Long) params.get("sellerId");
        
        key.append("page_").append(pageNum)
           .append("_size_").append(pageSize);
        
        if (productType != null) {
            key.append("_type_").append(productType);
        }
        
        if (stockStatus != null) {
            key.append("_status_").append(stockStatus);
        }
        
        if (keyword != null) {
            key.append("_keyword_").append(keyword);
        }
        
        if (sellerId != null) {
            key.append("_seller_").append(sellerId);
        }
        
        return key.toString();
    }

    /**
     * 生成库存详情缓存键
     * @param inventoryId 库存ID
     * @return 缓存键
     */
    public static String generateInventoryDetailKey(Long inventoryId) {
        return INVENTORY_DETAIL_PREFIX + inventoryId;
    }

    /**
     * 生成库存历史记录缓存键
     * @param inventoryId 库存ID
     * @param pageNum 页码
     * @param pageSize 每页大小
     * @return 缓存键
     */
    public static String generateInventoryHistoryKey(Long inventoryId, Integer pageNum, Integer pageSize) {
        return INVENTORY_HISTORY_PREFIX + inventoryId + "_page_" + pageNum + "_size_" + pageSize;
    }

    /**
     * 生成库存列表缓存键的前缀，用于批量删除
     * @return 缓存键前缀
     */
    public static String getInventoryListPrefix() {
        return INVENTORY_LIST_PREFIX;
    }

    /**
     * 生成库存详情缓存键的前缀，用于批量删除
     * @return 缓存键前缀
     */
    public static String getInventoryDetailPrefix() {
        return INVENTORY_DETAIL_PREFIX;
    }

    /**
     * 生成库存历史记录缓存键的前缀，用于批量删除
     * @return 缓存键前缀
     */
    public static String getInventoryHistoryPrefix() {
        return INVENTORY_HISTORY_PREFIX;
    }
}
