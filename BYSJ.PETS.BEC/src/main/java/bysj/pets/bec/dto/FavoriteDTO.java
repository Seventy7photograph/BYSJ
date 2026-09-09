package bysj.pets.bec.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 收藏DTO类，用于前端展示
 */
@Data
public class FavoriteDTO {
    private Long id; // 收藏记录ID

    private Long productId; // 商品ID

    private String productName; // 商品名称

    private String brandName; // 品牌名称

    private String productImage; // 商品图片

    private BigDecimal price; // 商品价格

    private Integer stock; // 商品库存

    private String specifications; // 商品规格

    private LocalDateTime createdAt; // 收藏时间

    private boolean selected = false; // 用于批量操作的选择状态
    
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
     * 成色标签
     */
    private String quality;
    
    /**
     * 卖家名称
     */
    private String sellerName;
}
