package bysj.pets.bec.entity.enumtype;

/**
 * 订单状态枚举
 */
public enum OrderStatus {
    /**
     * 待支付
     */
    PENDING_PAYMENT(0, "待支付"),
    
    /**
     * 已支付
     */
    PAID(1, "已支付"),
    
    /**
     * 已发货
     */
    SHIPPED(2, "已发货"),
    
    /**
     * 已完成
     */
    COMPLETED(3, "已完成"),
    
    /**
     * 已取消
     */
    CANCELLED(4, "已取消"),
    
    /**
     * 退款处理中
     */
    REFUNDING(5, "退款处理中"),
    
    /**
     * 退款成功
     */
    REFUND_SUCCESS(6, "退款成功"),
    
    /**
     * 退款失败
     */
    REFUND_FAILED(7, "退款失败"),
    
    /**
     * 租赁中
     */
    RENTING(8, "租赁中"),
    
    /**
     * 归还中
     */
    RETURNING(9, "归还中");

    
    private final int code;
    private final String name;
    
    OrderStatus(int code, String name) {
        this.code = code;
        this.name = name;
    }
    
    public int getCode() {
        return code;
    }
    
    public String getName() {
        return name;
    }
    
    /**
     * 根据编码获取枚举
     */
    public static OrderStatus getByCode(int code) {
        for (OrderStatus status : OrderStatus.values()) {
            if (status.code == code) {
                return status;
            }
        }
        return null;
    }
}