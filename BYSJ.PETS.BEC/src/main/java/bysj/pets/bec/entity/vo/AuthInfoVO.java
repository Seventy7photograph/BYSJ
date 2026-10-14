package bysj.pets.bec.entity.vo;

import lombok.Data;

/**
 * 认证信息VO
 */
@Data
public class AuthInfoVO {
    private String status;
    private String authType;
    private String authTime;
    private String rejectReason;
    private String businessLicense;
    private String idCardFront;
    private String idCardBack;
    
    // getter和setter方法
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getAuthType() {
        return authType;
    }
    
    public void setAuthType(String authType) {
        this.authType = authType;
    }
    
    public String getAuthTime() {
        return authTime;
    }
    
    public void setAuthTime(String authTime) {
        this.authTime = authTime;
    }
    
    public String getRejectReason() {
        return rejectReason;
    }
    
    public void setRejectReason(String rejectReason) {
        this.rejectReason = rejectReason;
    }
    
    public String getBusinessLicense() {
        return businessLicense;
    }
    
    public void setBusinessLicense(String businessLicense) {
        this.businessLicense = businessLicense;
    }
    
    public String getIdCardFront() {
        return idCardFront;
    }
    
    public void setIdCardFront(String idCardFront) {
        this.idCardFront = idCardFront;
    }
    
    public String getIdCardBack() {
        return idCardBack;
    }
    
    public void setIdCardBack(String idCardBack) {
        this.idCardBack = idCardBack;
    }
}