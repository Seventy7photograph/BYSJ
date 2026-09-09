package bysj.pets.bec.service;

import bysj.pets.bec.entity.vo.AuthInfoVO;
import bysj.pets.bec.entity.vo.SecurityInfoVO;
import bysj.pets.bec.entity.vo.ShopInfoVO;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * 店铺管理服务接口
 */
public interface ShopService {
    
    /**
     * 获取店铺信息
     */
    ShopInfoVO getShopInfo();
    
    /**
     * 更新店铺信息
     */
    boolean updateShopInfo(Map<String, Object> shopInfo);
    
    /**
     * 上传店铺Logo
     */
    Map<String, Object> uploadShopLogo(MultipartFile file);
    
    /**
     * 上传认证材料
     */
    Map<String, Object> uploadAuthMaterial(MultipartFile file);
    
    /**
     * 获取认证信息
     */
    AuthInfoVO getAuthInfo();
    
    /**
     * 提交认证信息
     */
    boolean submitAuthInfo(Map<String, Object> authInfo);
    
    /**
     * 获取安全设置
     */
    SecurityInfoVO getSecurityInfo();
    
    /**
     * 修改登录密码
     */
    boolean changePassword(String oldPassword, String newPassword, String confirmPassword);
    
    /**
     * 设置支付密码
     */
    boolean setPayPassword(String payPassword, String confirmPassword);
    
    /**
     * 修改支付密码
     */
    boolean changePayPassword(String oldPayPassword, String newPayPassword, String confirmPassword);
    
    /**
     * 获取店铺dashboard数据
     */
    Map<String, Object> getDashboardData();
    
    /**
     * 获取最近订单
     */
    Map<String, Object> getRecentOrders();
    
    /**
     * 获取图表数据
     */
    Map<String, Object> getChartData();
    
    /**
     * 获取日历销售数据
     */
    Map<String, Object> getCalendarSalesData();
    
    /**
     * 获取器材销售分布数据
     */
    Map<String, Object> getProductDistributionData();
}