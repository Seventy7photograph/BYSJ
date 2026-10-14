package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.OrderItem;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 订单项Mapper接口
 */
public interface OrderItemMapper extends BaseMapper<OrderItem> {
    /**
     * 批量插入订单项
     */
    boolean insertBatch(@Param("orderItems") List<OrderItem> orderItems);
    
    /**
     * 根据订单ID查询订单项
     */
    List<OrderItem> selectByOrderId(@Param("orderId") Long orderId);
}
