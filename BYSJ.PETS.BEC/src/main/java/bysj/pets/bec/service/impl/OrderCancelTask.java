package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.OrderItem;
import bysj.pets.bec.entity.Orders;
import bysj.pets.bec.mapper.OrderItemMapper;
import bysj.pets.bec.mapper.OrderMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 订单自动取消任务
 * 未付款订单超过5分钟自动取消
 */
@Component
public class OrderCancelTask {

    @Autowired
    private OrderMapper orderMapper;

    @Autowired
    private OrderItemMapper orderItemMapper;

    /**
     * 每1分钟执行一次，检查未付款订单
     */
    @Scheduled(cron = "0 */1 * * * ?")
    @Transactional(rollbackFor = Exception.class)
    public void cancelOverdueOrders() {
        // 获取当前时间
        LocalDateTime now = LocalDateTime.now();
        // 计算5分钟前的时间
        LocalDateTime fiveMinutesAgo = now.minusMinutes(5);

        // 查询所有状态为待付款（0）且创建时间超过5分钟的订单
        LambdaQueryWrapper<Orders> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Orders::getOrderStatus, 0)
                .lt(Orders::getCreateTime, fiveMinutesAgo);

        List<Orders> overdueOrders = orderMapper.selectList(queryWrapper);

        // 如果有符合条件的订单，更新状态为已取消（4）
        if (!overdueOrders.isEmpty()) {
            for (Orders order : overdueOrders) {
                // 更新订单状态
                order.setOrderStatus(4);
                order.setUpdateTime(now);
                orderMapper.updateById(order);

                // 更新订单项状态
                LambdaQueryWrapper<OrderItem> itemQueryWrapper = new LambdaQueryWrapper<>();
                itemQueryWrapper.eq(OrderItem::getOrderId, order.getOrderId());
                List<OrderItem> orderItems = orderItemMapper.selectList(itemQueryWrapper);

                for (OrderItem orderItem : orderItems) {
                    orderItem.setItemStatus(4); // 已取消
                    orderItem.setUpdateTime(now);
                    orderItemMapper.updateById(orderItem);
                }

                // 打印日志
                System.out.println("订单" + order.getOrderNo() + "因超过5分钟未付款被自动取消");
            }
        }
    }
}