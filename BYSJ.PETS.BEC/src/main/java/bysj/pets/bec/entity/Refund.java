package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("refund")
public class Refund {
    @TableId(type = IdType.AUTO)
    private Long refundId;
    private Long orderId;
    private Long userId;
    private BigDecimal refundAmount;
    private Integer refundStatus; // 0: 申请中, 1: 退款成功, 2: 退款失败
    private String refundReason; // 退款原因
    private String refundDescription; // 详细说明
    private String refundMethod; // 退款方式
    private LocalDateTime applyTime;
    private LocalDateTime refundTime;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}