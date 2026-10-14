package bysj.pets.bec.entity;


import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import org.apache.ibatis.type.TypeHandler;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * <p>
 * 用途：存储摄影器材的核心基础信息，区分全新 / 二手 / 租赁三种商品类型，是商品管理与交易的核心表。	备注：全新器材需关联品牌授权证明（存储于product_detail），否则audit_status驳回；库存低于 5 件时，系统自动提醒seller_id对应的商家补货。
 * </p>
 *
 * @author zsj
 * @since 2025-12-22
 */
@Data
@ToString
@Accessors(chain = true)
public class Product implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableField(exist = false) // 该字段不存在于数据库表中，需要JSON序列化
    private List<String> specifications;

    @TableField(exist = false) // 该字段不存在于数据库表中，需要JSON序列化
    private List<String> images;


    /**
     * 商品唯一标识
     */
    @TableId(value = "product_id", type = IdType.AUTO)
    private Long productId;

    /**
     * 外键，商品分类 ID（关联product_category.category_id，如 1 - 相机、2 - 镜头）
     */
    private Integer categoryId;

    /**
     * 器材品牌（如佳能、索尼、尼康）
     */
    private Integer brand;

    /**
     * 器材型号（如佳能 R5、索尼 24-70F2.8）
     */
    private String model;

    /**
     * 商品类型：1 - 全新器材，2 - 二手器材，3 - 租赁专用器材
     */
    private Byte productType;

    /**
     * 成色（仅二手 / 租赁用）：1-99 新，2-95 新，3-9 新，4-8 新
     */
    @TableField(value = "`condition`")
    private Byte condition;

    /*原价*/
    private BigDecimal originalPrice;
    /**
     * 售价（全新 / 二手）或租赁单价（元 / 天，租赁专用）
     */
    private BigDecimal price;

    /**
     * 库存数量（租赁专用器材为 “可租数量”）
     */
    private Integer stock;

    /**
     * 最短租赁期限（天）
     */
    private Integer minRentalDays;

    /**
     * 安全库存数量（库存低于此值时系统自动提醒补货）
     */
    private Integer minStock;

    /**
     * 外键,商家 ID（关联user.user_id，仅企业用户可作为卖家）
     */
    private Long sellerId;

    /**
     * 审核状态：0 - 待审核，1 - 审核通过，2 - 审核驳回（管理员审核）
     */
    private Byte auditStatus;

    /**
     * 审核驳回原因（如 “缺少保修证明”）
     */
    private String rejectReason;

    /**
     * 是否上架：0 - 下架，1 - 上架（审核通过后可手动上架）
     */
    private Byte isOnShelf;

    /**
     * 商品创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /**
     * 商品信息更新时间
     */
    private LocalDateTime updateTime;

    /**
     * 商品颜色（仅全新商品使用）
     */
    private String color;
}
