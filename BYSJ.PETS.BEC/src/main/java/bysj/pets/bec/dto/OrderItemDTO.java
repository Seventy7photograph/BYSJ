package bysj.pets.bec.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 订单项DTO，用于前端展示
 */
@Data
public class OrderItemDTO {
    /**
     * 订单项ID
     */
    private Long itemId;
    
    /**
     * 订单ID
     */
    private Long orderId;
    
    /**
     * 商品ID
     */
    private Long productId;
    
    /**
     * 商品名称
     */
    private String productName;
    
    /**
     * 商品图片
     */
    private String productImage;
    
    /**
     * 商品价格
     */
    private BigDecimal unitPrice;
    
    /**
     * 商品数量
     */
    private Integer quantity;
    
    /**
     * 商品规格
     */
    private String specifications;
    
    /**
     * 品牌名称
     */
    private String brandName;
    
    /**
     * 商品类型：1 - 全新器材，2 - 二手器材，3 - 租赁专用器材
     */
    private Byte productType;
    
    /**
     * 成色（仅二手 / 租赁用）：1-99 新，2-95 新，3-9 新，4-8 新
     */
    private Byte condition;
    
    /**
     * 押金
     */
    private BigDecimal deposit;
    
    /**
     * 运费
     */
    private BigDecimal freight;
    
    /**
     * 订单项状态
     */
    private Integer itemStatus;
    
    /**
     * 租赁天数
     */
    private Integer leaseTerm;
}
