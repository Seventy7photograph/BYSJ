package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.InventoryHistory;
import bysj.pets.bec.entity.vo.InventoryHistoryVO;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface InventoryHistoryMapper extends BaseMapper<InventoryHistory> {

    /**
     * 获取库存变更历史
     */
    List<InventoryHistoryVO> selectInventoryHistory(
            @Param("inventoryId") Long inventoryId
    );

    /**
     * 获取库存变更历史总数
     */
    long selectInventoryHistoryTotal(@Param("inventoryId") Long inventoryId);

    /**
     * 插入库存变更历史
     */
    boolean insertInventoryHistory(@Param("history") InventoryHistory history);
}
