package bysj.pets.bec.service;

import com.baomidou.mybatisplus.extension.service.IService;
import bysj.pets.bec.entity.Orders;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * 订单服务接口
 */
@Service
public interface OrderService extends IService<Orders> {
    /**
     * 从购物车创建订单，支持直接购买
     */
    Map<String, Object> createOrderFromCart(String username, List<Long> productIds, Integer quantity, Integer leaseTerm);
    
    /**
     * 获取临时订单信息（不创建正式订单）
     */
    Map<String, Object> getTempOrder(String username, List<Long> productIds, Integer quantity, Integer leaseTerm);

    /**
     * 获取用户订单列表
     */
    Map<String, Object> getOrderList(String username, String type, String status, String orderNo, Integer pageNum, Integer pageSize);

    /**
     * 模拟支付订单
     */
    Map<String, Object> simulatePay(Long orderId, String paymentMethod, Long addressId);
    
    /**
     * 获取单个订单详情
     */
    Map<String, Object> getOrderDetail(String username, Long orderId);
    
    /**
     * 通过订单号获取单个订单详情
     */
    Map<String, Object> getOrderDetailByOrderNo(String username, String orderNo);
    
    /**
     * 取消订单
     */
    void cancelOrder(Long orderId);
    
    /**
     * 确认收货
     */
    void confirmReceive(Long orderId);
    
    /**
     * 商家发货
     */
    void sellerShip(Long orderId);
    
    /**
     * 归还租赁商品
     */
    void returnRental(Long orderId);
    
    /**
     * 商家确认归还
     */
    void confirmReturn(Long orderId);
    
    /**
     * 检查是否有未付款的订单
     */
    Map<String, Object> checkPendingOrder(String username, List<Long> productIds);
    
    /**
     * 更新超过14天的订单状态为已完成
     */
    void updateOverdueOrdersToCompleted();
    
    /**
     * 更新订单状态
     */
    void updateOrderStatus(Long orderId, Integer status);
}
