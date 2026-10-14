package bysj.pets.bec.entity.vo;

/**
 * 库存变更历史VO
 */
public class InventoryHistoryVO {
    private Long id;
    private String changeTime;
    private String changeType;
    private Integer beforeStock;
    private Integer afterStock;
    private Integer changeQuantity;
    private String reason;
    private String operator;
    
    // getter和setter方法
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getChangeTime() {
        return changeTime;
    }
    
    public void setChangeTime(String changeTime) {
        this.changeTime = changeTime;
    }
    
    public String getChangeType() {
        return changeType;
    }
    
    public void setChangeType(String changeType) {
        this.changeType = changeType;
    }
    
    public Integer getBeforeStock() {
        return beforeStock;
    }
    
    public void setBeforeStock(Integer beforeStock) {
        this.beforeStock = beforeStock;
    }
    
    public Integer getAfterStock() {
        return afterStock;
    }
    
    public void setAfterStock(Integer afterStock) {
        this.afterStock = afterStock;
    }
    
    public Integer getChangeQuantity() {
        return changeQuantity;
    }
    
    public void setChangeQuantity(Integer changeQuantity) {
        this.changeQuantity = changeQuantity;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public String getOperator() {
        return operator;
    }
    
    public void setOperator(String operator) {
        this.operator = operator;
    }
}