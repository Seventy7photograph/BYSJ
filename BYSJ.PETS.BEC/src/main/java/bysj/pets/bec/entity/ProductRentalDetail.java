package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * <p>
 * 租赁商品详情表
 * </p>
 *
 * @author zsj
 * @since 2025-12-28
 */
@Data
@ToString
@Accessors(chain = true)
@TableName("product_rental_detail")
public class ProductRentalDetail implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 外键，关联product.product_id
     */
    @TableField("product_id")
    private Long productId;

    /**
     * 租赁押金（元）
     */
    @TableField("deposit")
    private BigDecimal deposit;

    /**
     * 最长租赁期限（天）
     */
    @TableField("max_rental_days")
    private Integer maxRentalDays;

    /**
     * 最短租赁期限（天）
     */
    @TableField("min_rental_days")
    private Integer minRentalDays;

    /**
     * 保险费用（元/天）
     */
    @TableField("insurance_fee")
    private BigDecimal insuranceFee;

    /**
     * 逾期违约金率（每天按租金的百分比计算）
     */
    @TableField("late_fee_rate")
    private BigDecimal lateFeeRate;

    /**
     * 损坏赔偿规则
     */
    @TableField("damage_fee_rule")
    private String damageFeeRule;

    /**
     * 取货方式：delivery-配送上门, store_pickup-门店自取
     */
    @TableField("pickup_methods")
    private String pickupMethods;

    /**
     * 配送费用（元）
     */
    @TableField("delivery_fee")
    private BigDecimal deliveryFee;

    /**
     * 创建时间
     */
    @TableField("created_time")
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    @TableField("updated_time")
    private LocalDateTime updatedTime;

}