package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.Orders;
import bysj.pets.bec.entity.Refund;
import bysj.pets.bec.entity.OrderItem;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.mapper.RefundMapper;
import bysj.pets.bec.mapper.OrderItemMapper;
import bysj.pets.bec.mapper.ProductMapper;
import bysj.pets.bec.mapper.OrderMapper;
import bysj.pets.bec.service.OrderService;
import bysj.pets.bec.service.RefundService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.ArrayList;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class RefundServiceImpl implements RefundService {

    @Autowired
    private RefundMapper refundMapper;

    @Autowired
    private OrderService orderService;
    
    @Autowired
    private OrderItemMapper orderItemMapper;
    
    @Autowired
    private ProductMapper productMapper;
    
    @Autowired
    private OrderMapper orderMapper;

    @Override
    @Transactional
    public Map<String, Object> applyRefund(String username, Long orderId, String refundReason, String refundDescription) {
        // 检查订单是否可以退款
        if (!canRefund(username, orderId)) {
            throw new RuntimeException("该订单无法申请退款");
        }

        // 获取订单信息
        Map<String, Object> orderDetail = orderService.getOrderDetail(username, orderId);
        Orders order = (Orders) orderDetail.get("order");

        // 创建退款记录
        Refund refund = new Refund();
        refund.setOrderId(orderId);
        refund.setUserId(order.getUserId());
        refund.setRefundAmount(order.getPayAmount());
        refund.setRefundStatus(0); // 申请中
        refund.setRefundReason(refundReason);
        refund.setRefundDescription(refundDescription);
        refund.setRefundMethod(order.getPaymentMethod());
        refund.setApplyTime(LocalDateTime.now());
        refund.setCreateTime(LocalDateTime.now());
        refund.setUpdateTime(LocalDateTime.now());

        refundMapper.insert(refund);

        // 更新订单状态为退款处理中
        orderService.updateOrderStatus(orderId, bysj.pets.bec.entity.enumtype.OrderStatus.REFUNDING.getCode());

        Map<String, Object> result = new HashMap<>();
        result.put("refundId", refund.getRefundId());
        result.put("refundAmount", refund.getRefundAmount());
        result.put("applyTime", refund.getApplyTime());
        return result;
    }

    @Override
    @Transactional
    public Map<String, Object> processRefund(Long refundId, Integer status) {
        Refund refund = refundMapper.selectById(refundId);
        if (refund == null) {
            throw new RuntimeException("退款记录不存在");
        }

        refund.setRefundStatus(status);
        refund.setRefundTime(LocalDateTime.now());
        refund.setUpdateTime(LocalDateTime.now());

        refundMapper.updateById(refund);

        // 更新订单状态
        if (status == 1) {
            orderService.updateOrderStatus(refund.getOrderId(), bysj.pets.bec.entity.enumtype.OrderStatus.REFUND_SUCCESS.getCode()); // 退款成功
        } else if (status == 2) {
            orderService.updateOrderStatus(refund.getOrderId(), bysj.pets.bec.entity.enumtype.OrderStatus.REFUND_FAILED.getCode()); // 退款失败
        }

        Map<String, Object> result = new HashMap<>();
        result.put("refundId", refund.getRefundId());
        result.put("refundStatus", refund.getRefundStatus());
        result.put("refundTime", refund.getRefundTime());
        return result;
    }

    @Override
    public Refund getRefundByOrderId(Long orderId) {
        LambdaQueryWrapper<Refund> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Refund::getOrderId, orderId);
        return refundMapper.selectOne(wrapper);
    }

    @Override
    public boolean canRefund(String username, Long orderId) {
        Map<String, Object> orderDetail = orderService.getOrderDetail(username, orderId);
        Orders order = (Orders) orderDetail.get("order");
        
        // 检查订单状态：已付款或待发货状态可以申请退款
        Integer orderStatus = order.getOrderStatus();
        return orderStatus == 1 || orderStatus == 2;
    }

    @Override
    public Map<String, Object> getMerchantRefundList(String status, String orderNo, Long merchantId, Integer page, Integer pageSize) {
        // 1. 先查询所有退款记录
        LambdaQueryWrapper<Refund> queryWrapper = new LambdaQueryWrapper<>();
        
        // 添加状态筛选
        if (status != null && !status.isEmpty()) {
            queryWrapper.eq(Refund::getRefundStatus, Integer.parseInt(status));
        }
        
        // 按创建时间倒序排序
        queryWrapper.orderByDesc(Refund::getCreateTime);
        
        // 2. 查询所有符合条件的退款记录（不分页），用于计算总数
        List<Refund> allRefunds = refundMapper.selectList(queryWrapper);
        
        // 3. 过滤出属于当前商家的退款记录
        List<Refund> merchantRefunds = new ArrayList<>();
        for (Refund refund : allRefunds) {
            Orders order = orderMapper.selectById(refund.getOrderId());
            if (order != null) {
                // 订单号筛选
                if (orderNo != null && !orderNo.isEmpty() && !order.getOrderNo().contains(orderNo)) {
                    continue;
                }
                
                List<OrderItem> orderItems = orderItemMapper.selectByOrderId(order.getOrderId());
                for (OrderItem item : orderItems) {
                    Product product = productMapper.selectById(item.getProductId());
                    if (product != null && product.getSellerId() != null && product.getSellerId().equals(merchantId)) {
                        merchantRefunds.add(refund);
                        break;
                    }
                }
            }
        }
        
        // 4. 计算总数
        int total = merchantRefunds.size();
        
        // 5. 分页处理
        int start = (page - 1) * pageSize;
        int end = Math.min(start + pageSize, total);
        List<Refund> paginatedRefunds = new ArrayList<>();
        if (start < total) {
            paginatedRefunds = merchantRefunds.subList(start, end);
        }
        
        // 6. 构建返回结果
        List<Map<String, Object>> refundList = new ArrayList<>();
        for (Refund refund : paginatedRefunds) {
            Orders order = orderMapper.selectById(refund.getOrderId());
            if (order != null) {
                Map<String, Object> refundMap = new HashMap<>();
                refundMap.put("refundId", refund.getRefundId());
                refundMap.put("orderId", refund.getOrderId());
                refundMap.put("refundAmount", refund.getRefundAmount());
                refundMap.put("refundStatus", refund.getRefundStatus());
                refundMap.put("refundReason", refund.getRefundReason());
                refundMap.put("refundDescription", refund.getRefundDescription());
                refundMap.put("applyTime", refund.getApplyTime());
                refundMap.put("createTime", refund.getCreateTime());
                refundMap.put("orderNo", order.getOrderNo());
                
                // 查询用户信息
                String userName = "未知用户";
                
                // 查询订单商品信息
                List<Map<String, Object>> items = new ArrayList<>();
                List<OrderItem> orderItems = orderItemMapper.selectByOrderId(order.getOrderId());
                for (OrderItem item : orderItems) {
                    Map<String, Object> itemMap = new HashMap<>();
                    itemMap.put("productId", item.getProductId());
                    itemMap.put("quantity", item.getQuantity());
                    
                    // 查询商品信息
                    Product product = productMapper.selectById(item.getProductId());
                    if (product != null) {
                        itemMap.put("productName", product.getModel());
                        // 查询品牌名称
                        String brandName = productMapper.selectBrandNameByProductId(item.getProductId());
                        itemMap.put("brandName", brandName != null ? brandName : "未知品牌");
                    }
                    
                    items.add(itemMap);
                }
                refundMap.put("items", items);
                
                refundList.add(refundMap);
            }
        }
        
        Map<String, Object> map = new HashMap<>();
        map.put("list", refundList);
        map.put("total", total);
        map.put("page", page);
        map.put("pageSize", pageSize);
        
        return map;
    }
}