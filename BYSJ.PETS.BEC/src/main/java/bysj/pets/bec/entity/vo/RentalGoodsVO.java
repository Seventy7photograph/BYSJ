package bysj.pets.bec.entity.vo;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 租赁商品VO类，用于前端展示租赁商品的详细信息
 */
@Data
public class RentalGoodsVO {
    private Long productId;
    private String name;
    private String brandName;
    private Integer categoryId;
    private BigDecimal price; // 租赁单价（元/天）
    private Integer stock; // 可租数量
    private String imageUrl;
    private String description;
    private Map<String, String> specifications;
    private List<String> imageUrls;
    
    // 租赁特有字段
    private BigDecimal deposit; // 租赁押金
    private Integer maxRentalDays; // 最长租赁期限（天）
    private Integer minRentalDays; // 最短租赁期限（天）
    private BigDecimal insuranceFee; // 保险费用（元/天）
    private BigDecimal lateFeeRate; // 逾期违约金率
    private String damageFeeRule; // 损坏赔偿规则
    private String pickupMethods; // 取货方式
    private BigDecimal deliveryFee; // 配送费用
    
    // 商品基本信息
    private Integer condition; // 商品成色
    private String quality; // 成色描述（如99新）
    private Long sellerId;
    private String sellerName; // 卖家昵称
    private Byte sellerType; // 卖家类型
    
    // 计算属性：总租赁费用（根据租赁天数计算）
    public BigDecimal calculateTotalRentalFee(Integer rentalDays) {
        if (rentalDays == null || rentalDays <= 0) {
            rentalDays = minRentalDays;
        }
        return price.multiply(new BigDecimal(rentalDays));
    }
    
    // 计算属性：总费用（租金+押金+保险+配送）
    public BigDecimal calculateTotalAmount(Integer rentalDays, boolean includeInsurance) {
        BigDecimal totalRentalFee = calculateTotalRentalFee(rentalDays);
        BigDecimal totalInsurance = includeInsurance ? 
            insuranceFee.multiply(new BigDecimal(rentalDays)) : BigDecimal.ZERO;
        
        return totalRentalFee.add(deposit).add(totalInsurance).add(deliveryFee);
    }
}