package bysj.pets.bec.service;

import bysj.pets.bec.entity.Refund;
import java.util.Map;

public interface RefundService {
    /**
     * 申请退款
     */
    Map<String, Object> applyRefund(String username, Long orderId, String refundReason, String refundDescription);
    
    /**
     * 处理退款（模拟）
     */
    Map<String, Object> processRefund(Long refundId, Integer status);
    
    /**
     * 获取退款信息
     */
    Refund getRefundByOrderId(Long orderId);
    
    /**
     * 检查订单是否可以退款
     */
    boolean canRefund(String username, Long orderId);

    /**
     * 商家获取退款列表
     */
    Map<String, Object> getMerchantRefundList(String status, String orderNo, Long merchantId, Integer page, Integer pageSize);
}