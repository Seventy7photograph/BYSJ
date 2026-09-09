package bysj.pets.bec.service;

import bysj.pets.bec.entity.Inventory;
import bysj.pets.bec.entity.vo.InventoryItemVO;
import bysj.pets.bec.entity.vo.InventoryHistoryVO;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;
import java.util.Map;

/**
 * 库存管理服务接口
 */
public interface InventoryService extends IService<Inventory> {
    
    /**
     * 获取库存列表
     */
    IPage<InventoryItemVO> getInventoryList(Map<String, Object> params);
    
    /**
     * 获取库存详情
     */
    InventoryItemVO getInventoryDetail(Long inventoryId);
    
    /**
     * 调整库存
     */
    boolean adjustInventory(Long inventoryId, String adjustType, Integer adjustQuantity, String reason, Integer minStock);
    
    /**
     * 获取库存变更历史
     */
    IPage<InventoryHistoryVO> getInventoryHistory(Long inventoryId, Integer pageNum, Integer pageSize);
    
    /**
     * 设置安全库存
     */
    boolean setMinStock(Long inventoryId, Integer minStock);
}