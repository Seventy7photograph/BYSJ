package bysj.pets.bec.entity.enumtype;

/**
 * 用户类型枚举
 */
public enum UserType {
    /**
     * 普通用户
     */
    NORMAL(1, "普通用户"),
    
    /**
     * 商家用户
     */
    MERCHANT(2, "商家用户"),
    
    /**
     * 普通管理员
     */
    ADMIN(3, "普通管理员"),
    
    /**
     * 超级管理员
     */
    SUPER_ADMIN(4, "超级管理员");
    
    private final int code;
    private final String name;
    
    UserType(int code, String name) {
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
    public static UserType getByCode(int code) {
        for (UserType type : UserType.values()) {
            if (type.code == code) {
                return type;
            }
        }
        return null;
    }
}