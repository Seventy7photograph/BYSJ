package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Orders;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.apache.ibatis.annotations.Param;

/**
 * 订单Mapper接口
 */
public interface OrderMapper extends BaseMapper<Orders> {
    /**
     * 查询用户订单列表（购买的订单）
     */
    IPage<Orders> selectUserOrders(Page<Orders> page, @Param("userId") Long userId);
    
    /**
     * 查询商家订单列表（销售的订单）
     */
    IPage<Orders> selectSellerOrders(Page<Orders> page, @Param("sellerId") Long sellerId);
    
    /**
     * 查询用户订单列表（购买的订单），支持类型过滤
     */
    IPage<Orders> selectUserOrdersByType(Page<Orders> page, @Param("userId") Long userId, @Param("type") String type);
    
    /**
     * 查询商家订单列表（销售的订单），支持类型过滤
     */
    IPage<Orders> selectSellerOrdersByType(Page<Orders> page, @Param("sellerId") Long sellerId, @Param("type") String type);
}
