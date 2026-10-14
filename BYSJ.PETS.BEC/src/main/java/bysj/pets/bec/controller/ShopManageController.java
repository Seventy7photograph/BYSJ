package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.service.ShopService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * 店铺管理控制器
 */
@RestController
@RequestMapping("/merchant/shop")
public class ShopManageController {
    
    @Autowired
    private ShopService shopService;
    
    /**
     * 获取店铺信息
     */
    @GetMapping("/info")
    public Result<?> getShopInfo() {
        return Result.success("获取店铺信息成功", shopService.getShopInfo());
    }
    
    /**
     * 更新店铺信息
     */
    @PutMapping("/info")
    public Result<?> updateShopInfo(@RequestBody Map<String, Object> shopInfo) {
        boolean success = shopService.updateShopInfo(shopInfo);
        if (success) {
            return Result.success("更新店铺信息成功");
        } else {
            return Result.error("更新店铺信息失败");
        }
    }
    
    /**
     * 上传店铺Logo
     */
    @PostMapping("/upload-logo")
    public Result<?> uploadShopLogo(@RequestParam("file") MultipartFile file) {
        Map<String, Object> result = shopService.uploadShopLogo(file);
        return Result.success("上传Logo成功", result);
    }
    
    /**
     * 上传认证材料
     */
    @PostMapping("/upload-auth-material")
    public Result<?> uploadAuthMaterial(@RequestParam("file") MultipartFile file) {
        Map<String, Object> result = shopService.uploadAuthMaterial(file);
        return Result.success("上传认证材料成功", result);
    }
    
    /**
     * 获取认证信息
     */
    @GetMapping("/auth-info")
    public Result<?> getAuthInfo() {
        return Result.success("获取认证信息成功", shopService.getAuthInfo());
    }
    
    /**
     * 提交认证信息
     */
    @PostMapping("/auth-info")
    public Result<?> submitAuthInfo(@RequestBody Map<String, Object> authInfo) {
        boolean success = shopService.submitAuthInfo(authInfo);
        if (success) {
            return Result.success("提交认证信息成功");
        } else {
            return Result.error("提交认证信息失败");
        }
    }
    
    /**
     * 获取安全设置
     */
    @GetMapping("/security-info")
    public Result<?> getSecurityInfo() {
        return Result.success("获取安全设置成功", shopService.getSecurityInfo());
    }
    
    /**
     * 修改登录密码
     */
    @PostMapping("/change-password")
    public Result<?> changePassword(@RequestBody Map<String, Object> request) {
        String oldPassword = (String) request.get("oldPassword");
        String newPassword = (String) request.get("newPassword");
        String confirmPassword = (String) request.get("confirmPassword");
        
        boolean success = shopService.changePassword(oldPassword, newPassword, confirmPassword);
        if (success) {
            return Result.success("修改密码成功");
        } else {
            return Result.error("修改密码失败");
        }
    }
    
    /**
     * 设置支付密码
     */
    @PostMapping("/set-pay-password")
    public Result<?> setPayPassword(@RequestBody Map<String, Object> request) {
        String payPassword = (String) request.get("payPassword");
        String confirmPassword = (String) request.get("confirmPassword");
        
        boolean success = shopService.setPayPassword(payPassword, confirmPassword);
        if (success) {
            return Result.success("设置支付密码成功");
        } else {
            return Result.error("设置支付密码失败");
        }
    }
    
    /**
     * 修改支付密码
     */
    @PostMapping("/change-pay-password")
    public Result<?> changePayPassword(@RequestBody Map<String, Object> request) {
        String oldPayPassword = (String) request.get("oldPayPassword");
        String newPayPassword = (String) request.get("newPayPassword");
        String confirmPassword = (String) request.get("confirmPassword");
        
        boolean success = shopService.changePayPassword(oldPayPassword, newPayPassword, confirmPassword);
        if (success) {
            return Result.success("修改支付密码成功");
        } else {
            return Result.error("修改支付密码失败");
        }
    }
    
    /**
     * 获取店铺dashboard数据
     */
    @GetMapping("/dashboard")
    public Result<?> getDashboardData() {
        return Result.success("获取dashboard数据成功", shopService.getDashboardData());
    }
    
    /**
     * 获取最近订单
     */
    @GetMapping("/recent-orders")
    public Result<?> getRecentOrders() {
        return Result.success("获取最近订单成功", shopService.getRecentOrders());
    }
    
    /**
     * 获取图表数据
     */
    @GetMapping("/chart-data")
    public Result<?> getChartData() {
        return Result.success("获取图表数据成功", shopService.getChartData());
    }
    
    /**
     * 获取日历销售数据
     */
    @GetMapping("/calendar-data")
    public Result<?> getCalendarSalesData() {
        return Result.success("获取日历销售数据成功", shopService.getCalendarSalesData());
    }
    
    /**
     * 获取器材销售分布数据
     */
    @GetMapping("/product-distribution")
    public Result<?> getProductDistributionData() {
        return Result.success("获取器材销售分布数据成功", shopService.getProductDistributionData());
    }
}