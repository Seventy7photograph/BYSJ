package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 购物车实体类
 */
@Data
@TableName("cart")
public class Cart {
    /**
     * 购物车记录唯一标识
     */
    @TableId(value = "cart_id", type = IdType.AUTO)
    private Long cartId;

    /**
     * 外键,关联user.user_id，用户删除时同步清空购物车
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 外键,关联product.product_id，商品下架时标记 “已下架”
     */
    @TableField("product_id")
    private Long productId;

    /**
     * 商品数量（购买场景）或租赁数量（租赁场景，默认 1）
     */
    @TableField("quantity")
    private Integer quantity;

    /**
     * 租期（仅租赁场景用，单位：天，如 1-90 天）
     */
    @TableField("lease_term")
    private Integer leaseTerm;

    /**
     * 是否勾选结算：0 - 未勾选，1 - 已勾选
     */
    @TableField("select_status")
    private Byte selectStatus;

    /**
     * 租赁商品预占库存时间（加入购物车后 24 小时内有效，超时自动释放）
     */
    @TableField("preoccupy_time")
    private LocalDateTime preoccupyTime;

    /**
     * 加入购物车时间
     */
    @TableField(value = "create_time", fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /**
     * 购物车信息更新时间
     */
    @TableField(value = "update_time", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}
