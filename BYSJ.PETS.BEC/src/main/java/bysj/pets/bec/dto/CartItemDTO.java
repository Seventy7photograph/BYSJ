package bysj.pets.bec.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 购物车商品DTO，用于前端展示
 */
@Data
public class CartItemDTO {
    /**
     * 购物车记录ID
     */
    private Long id;

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
    private BigDecimal price;

    /**
     * 商品数量
     */
    private Integer quantity;

    /**
     * 商品库存
     */
    private Integer stock;

    /**
     * 是否选中
     */
    private boolean selected;

    /**
     * 商品规格
     */
    private String specifications;
    
    /**
     * 品牌名称
     */
    private String brandName;
    
    /**
     * 商品类型（1-全新，2-二手，3-租赁）
     */
    private Integer product_type;
    
    /**
     * 商品类型名称
     */
    private String productType;
    
    /**
     * 成色
     */
    private Integer condition;
    
    /**
     * 卖家名称
     */
    private String sellerName;
    
    /**
     * 成色标签
     */
    private String quality;
}
