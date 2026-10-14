package bysj.pets.bec.entity.vo;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class GoodsVO {
    private Long productId;
    private String name; // 品牌 + 型号
    private BigDecimal price;
    private BigDecimal originalPrice; // 原价，用于展示划线价与折扣
    private String imageUrl;
    private String stockTip; // 库存提示
    private Integer stock;    // 实际库存，库存提示与售罄判断都依赖它
    private Integer minStock; // 安全库存阈值
    private Integer productType; // 1-全新 2-二手 3-租赁
    private String brandName; // 品牌名称
    private String brandId;   // 品牌ID
    private Integer categoryId; // 分类ID
    private String categoryName;
    private Integer condition; // 成色（1-99新，2-95新，3-9新，4-8新）
    private Long sellerId; // 卖家ID
    private String sellerName; // 卖家昵称
    private BigDecimal deposit; // 押金
    private Integer minRentalDays; // 起租天数
}
