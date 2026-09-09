package bysj.pets.bec.entity;

import bysj.pets.bec.dto.OrderItemDTO;
import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName("orders")
public class Orders {
    @TableId(type = IdType.AUTO)
    private Long orderId;
    private String orderNo;
    private Long userId;
    private Long sellerId;
    private BigDecimal totalAmount;
    private BigDecimal shippingFee;
    private BigDecimal payAmount;
    private Integer orderStatus;
    private String paymentMethod;
    private Long addressId;
    private String recipient;
    private String phone;
    private String province;
    private String city;
    private String district;
    private String detail;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
    // 支付时间
    private LocalDateTime payTime;
    // 支付流水号
    private String transactionId;
    
    // 订单项列表，不存储到数据库
    @TableField(exist = false)
    private List<OrderItemDTO> items;
}
