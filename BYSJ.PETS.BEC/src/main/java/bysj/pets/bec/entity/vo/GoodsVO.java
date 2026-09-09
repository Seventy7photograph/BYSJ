package bysj.pets.bec.entity.vo;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class GoodsVO {
    private Long productId;
    private String name; // 品牌 + 型号
    private BigDecimal price;
    private String imageUrl;
    private String stockTip; // 库存提示
    private String brandName; // 品牌名称
    private String brandId;   // 品牌ID
    private String categoryName;
    private Integer condition; // 成色（1-99新，2-95新，3-9新，4-8新）
    private Long sellerId; // 卖家ID
    private String sellerName; // 卖家昵称
    private BigDecimal deposit; // 押金
    private Integer minRentalDays; // 起租天数
}