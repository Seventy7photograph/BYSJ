package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Inventory;
import bysj.pets.bec.entity.vo.InventoryHistoryVO;
import bysj.pets.bec.entity.vo.InventoryItemVO;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

public interface InventoryMapper extends BaseMapper<Inventory> {

    /**
     * 获取库存列表
     */
    List<InventoryItemVO> selectInventoryList(
            @Param("productType") String productType,
            @Param("stockStatus") String stockStatus,
            @Param("keyword") String keyword,
            @Param("sellerId") Long sellerId
    );

    /**
     * 获取库存总数
     */
    long selectInventoryTotal(
            @Param("productType") String productType,
            @Param("stockStatus") String stockStatus,
            @Param("keyword") String keyword,
            @Param("sellerId") Long sellerId
    );

    /**
     * 获取库存详情
     */
    InventoryItemVO selectInventoryDetail(@Param("inventoryId") Long inventoryId);

    /**
     * 更新库存
     */
    boolean updateProductStock(@Param("inventoryId") Long inventoryId, @Param("newStock") Integer newStock);

    /**
     * 同时更新库存和安全库存
     */
    boolean updateProductStockAndMinStock(@Param("inventoryId") Long inventoryId, 
                                        @Param("newStock") Integer newStock, 
                                        @Param("minStock") Integer minStock);

    /**
     * 设置安全库存
     */
    boolean updateMinStock(@Param("inventoryId") Long inventoryId, @Param("minStock") Integer minStock);
}
