package bysj.pets.bec.entity.vo;

import java.math.BigDecimal;
import java.util.Date;

/**
 * 库存项VO
 */
public class InventoryItemVO {
    private Long id;
    private Long productId;
    private String productName;
    private String productType;
    private Long skuId;
    private String skuAttribute;
    private String skuValue;
    private Integer currentStock;
    private Integer minStock;
    private Integer sales;
    private String createTime;
    private String lastUpdateTime;
    private String brandName;
    private BigDecimal price;
    private BigDecimal originalPrice;
    
    // getter和setter方法
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getProductId() {
        return productId;
    }
    
    public void setProductId(Long productId) {
        this.productId = productId;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String productName) {
        this.productName = productName;
    }
    
    public String getProductType() {
        return productType;
    }
    
    public void setProductType(String productType) {
        this.productType = productType;
    }
    
    public Long getSkuId() {
        return skuId;
    }
    
    public void setSkuId(Long skuId) {
        this.skuId = skuId;
    }
    
    public String getSkuAttribute() {
        return skuAttribute;
    }
    
    public void setSkuAttribute(String skuAttribute) {
        this.skuAttribute = skuAttribute;
    }
    
    public String getSkuValue() {
        return skuValue;
    }
    
    public void setSkuValue(String skuValue) {
        this.skuValue = skuValue;
    }
    
    public Integer getCurrentStock() {
        return currentStock;
    }
    
    public void setCurrentStock(Integer currentStock) {
        this.currentStock = currentStock;
    }
    
    public Integer getMinStock() {
        return minStock;
    }
    
    public void setMinStock(Integer minStock) {
        this.minStock = minStock;
    }
    
    public Integer getSales() {
        return sales;
    }
    
    public void setSales(Integer sales) {
        this.sales = sales;
    }
    
    public String getCreateTime() {
        return createTime;
    }
    
    public void setCreateTime(String createTime) {
        this.createTime = createTime;
    }
    
    public String getLastUpdateTime() {
        return lastUpdateTime;
    }
    
    public void setLastUpdateTime(String lastUpdateTime) {
        this.lastUpdateTime = lastUpdateTime;
    }
    
    public String getBrandName() {
        return brandName;
    }
    
    public void setBrandName(String brandName) {
        this.brandName = brandName;
    }
    
    public BigDecimal getPrice() {
        return price;
    }
    
    public void setPrice(BigDecimal price) {
        this.price = price;
    }
    
    public BigDecimal getOriginalPrice() {
        return originalPrice;
    }
    
    public void setOriginalPrice(BigDecimal originalPrice) {
        this.originalPrice = originalPrice;
    }
}