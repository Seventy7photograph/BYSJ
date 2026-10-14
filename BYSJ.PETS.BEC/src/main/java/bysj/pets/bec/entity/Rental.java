package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * <p>
 * 租赁记录表
 * </p>
 *
 * @author zsj
 * @since 2025-12-29
 */
@Data
@TableName("rental")
public class Rental implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 租赁记录唯一标识
     */
    @TableId(value = "rental_id", type = IdType.AUTO)
    private Long rentalId;

    /**
     * 关联order.order_id，订单删除时同步删除租赁记录
     */
    @TableField("order_id")
    private Long orderId;

    /**
     * 起租时间（用户选择或商家确认）
     */
    @TableField("start_date")
    private LocalDateTime startDate;

    /**
     * 到期时间（start_date + lease_term天，用于到期提醒）
     */
    @TableField("end_date")
    private LocalDateTime endDate;

    /**
     * 租期（单位：天，1-90 天）
     */
    @TableField("lease_term")
    private Integer leaseTerm;

    /**
     * 总租金（unit_price × lease_term，会员享折扣）
     */
    @TableField("rent")
    private BigDecimal rent;

    /**
     * 取货方式：1 - 上门取件，2 - 快递配送
     */
    @TableField("pickup_type")
    private Integer pickupType;

    /**
     * 归还方式：1 - 上门还件，2 - 自行寄送
     */
    @TableField("return_type")
    private Integer returnType;

    /**
     * 归还状态：0 - 未归还，1 - 待验收，2 - 验收通过（押金退还），3 - 验收异常（扣押金）
     */
    @TableField("return_status")
    private Integer returnStatus;

    /**
     * 续租状态：0 - 无续租，1 - 续租申请中，2 - 续租通过，3 - 续租驳回
     */
    @TableField("renew_status")
    private Integer renewStatus;

    /**
     * 逾期天数（end_date后未归还的天数，按日租金 1.5 倍收滞纳金）
     */
    @TableField("overdue_days")
    private Integer overdueDays;

    /**
     * 出租时器材初始状态图（JSON 数组，用于归还验收对比）
     */
    @TableField("initial_img")
    private String initialImg;

    /**
     * 租赁记录创建时间
     */
    @TableField("create_time")
    private LocalDateTime createTime;

    /**
     * 租赁状态更新时间
     */
    @TableField("update_time")
    private LocalDateTime updateTime;
}
