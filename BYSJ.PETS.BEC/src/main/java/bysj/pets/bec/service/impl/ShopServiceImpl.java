package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.User;
import bysj.pets.bec.entity.Orders;
import bysj.pets.bec.entity.OrderItem;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.entity.vo.AuthInfoVO;
import bysj.pets.bec.entity.vo.SecurityInfoVO;
import bysj.pets.bec.entity.vo.ShopInfoVO;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.mapper.OrderMapper;
import bysj.pets.bec.mapper.OrderItemMapper;
import bysj.pets.bec.mapper.ProductMapper;
import bysj.pets.bec.service.ShopService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.io.File;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.Year;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

/**
 * 店铺管理服务实现类
 */
@Service
public class ShopServiceImpl implements ShopService {
    
    @Autowired
    private UserMapper userMapper;
    
    @Autowired
    private OrderMapper orderMapper;
    
    @Autowired
    private ProductMapper productMapper;
    
    @Autowired
    private OrderItemMapper orderItemMapper;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        // 检查是否为匿名用户
        if (authentication == null || authentication.getPrincipal() == null || "anonymousUser".equals(authentication.getPrincipal())) {
            // 对于测试环境，返回已知的商家用户ID
            return 8L; // 商家用户ID，根据实际数据调整
        }
        
        // 从authentication中获取用户名
        String username = authentication.getName();
        
        try {
            // 尝试通过用户名查询用户ID
            User user = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
            if (user != null) {
                return user.getUserId();
            }
            
            // 如果通过用户名查询不到，尝试将用户名直接作为用户ID
            return Long.parseLong(username);
        } catch (Exception e) {
            // 对于测试环境，返回已知的商家用户ID
            return 8L; // 商家用户ID，根据实际数据调整
        }
    }
    
    @Override
    public ShopInfoVO getShopInfo() {
        // 从数据库获取店铺信息
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            return new ShopInfoVO();
        }
        
        // 转换为VO
        ShopInfoVO shopInfoVO = new ShopInfoVO();
        shopInfoVO.setShopName(user.getShopName() != null ? user.getShopName() : "");
        shopInfoVO.setShopType(user.getBusinessType() != null ? user.getBusinessType() : "");
        shopInfoVO.setStatus(user.getShopStatus() == 1 ? "normal" : user.getShopStatus() == 2 ? "pending" : "closed");
        
        if (user.getOpenTime() != null) {
            shopInfoVO.setOpenTime(user.getOpenTime().toLocalDate().toString());
        } else {
            shopInfoVO.setOpenTime("");
        }
        
        shopInfoVO.setPhone(user.getPhone() != null ? user.getPhone() : "");
        shopInfoVO.setEmail(user.getEmail() != null ? user.getEmail() : "");
        shopInfoVO.setAddress(user.getShopAddress() != null ? user.getShopAddress() : "");
        shopInfoVO.setDescription(user.getShopDescription() != null ? user.getShopDescription() : "");
        shopInfoVO.setLogo(user.getAvatarUrl() != null ? user.getAvatarUrl() : "");
        
        return shopInfoVO;
    }
    
    @Override
    public boolean updateShopInfo(Map<String, Object> shopInfo) {
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            return false;
        }
        
        // 更新店铺信息
        if (shopInfo.containsKey("shopName")) {
            user.setShopName((String) shopInfo.get("shopName"));
        }
        if (shopInfo.containsKey("shopType")) {
            user.setBusinessType((String) shopInfo.get("shopType"));
        }
        if (shopInfo.containsKey("phone")) {
            user.setPhone((String) shopInfo.get("phone"));
        }
        if (shopInfo.containsKey("email")) {
            user.setEmail((String) shopInfo.get("email"));
        }
        if (shopInfo.containsKey("address")) {
            user.setShopAddress((String) shopInfo.get("address"));
        }
        if (shopInfo.containsKey("description")) {
            user.setShopDescription((String) shopInfo.get("description"));
        }
        
        return userMapper.updateById(user) > 0;
    }
    
    // Logo存储路径
    private static final String LOGO_PATH = "G:/study/AAA-BYSJ/BYSJ.PETS.FEC/public/head/";
    // 认证材料存储路径
    private static final String AUTH_MATERIAL_PATH = "G:/study/AAA-BYSJ/BYSJ.PETS.FEC/public/auth/";

    @Override
    public Map<String, Object> uploadShopLogo(MultipartFile file) {
        // 获取当前登录用户ID
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "用户不存在");
            return result;
        }
        
        // 验证文件
        if (file.isEmpty()) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "请选择要上传的文件");
            return result;
        }
        
        // 确保Logo目录存在
        File logoDir = new File(LOGO_PATH);
        if (!logoDir.exists()) {
            logoDir.mkdirs();
        }
        
        // 生成唯一文件名
        String originalFilename = file.getOriginalFilename();
        String fileExtension = originalFilename.substring(originalFilename.lastIndexOf("."));
        
        // 验证文件格式
        String[] allowedExtensions = {".jpg", ".jpeg", ".png", ".pdf"};
        boolean isAllowed = false;
        for (String ext : allowedExtensions) {
            if (fileExtension.toLowerCase().equals(ext)) {
                isAllowed = true;
                break;
            }
        }
        
        if (!isAllowed) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "只能上传 JPG/PNG/PDF 格式的文件");
            return result;
        }
        
        String fileName = "shop_" + UUID.randomUUID().toString() + fileExtension;
        String filePath = LOGO_PATH + fileName;
        
        try {
            // 保存文件
            file.transferTo(new File(filePath));
            
            // 更新用户头像路径
            String logoUrl = "/head/" + fileName;
            user.setAvatarUrl(logoUrl);
            user.setUpdateTime(LocalDateTime.now());
            userMapper.updateById(user);
            
            Map<String, Object> result = new HashMap<>();
            result.put("url", logoUrl);
            result.put("success", true);
            
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "上传失败");
            return result;
        }
    }
    
    @Override
    public Map<String, Object> uploadAuthMaterial(MultipartFile file) {
        // 获取当前登录用户ID
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "用户不存在");
            return result;
        }
        
        // 验证文件
        if (file.isEmpty()) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "请选择要上传的文件");
            return result;
        }
        
        // 确保认证材料目录存在
        File authDir = new File(AUTH_MATERIAL_PATH);
        if (!authDir.exists()) {
            authDir.mkdirs();
        }
        
        // 生成唯一文件名
        String originalFilename = file.getOriginalFilename();
        String fileExtension = originalFilename.substring(originalFilename.lastIndexOf("."));
        
        // 验证文件格式
        String[] allowedExtensions = {".jpg", ".jpeg", ".png", ".pdf"};
        boolean isAllowed = false;
        for (String ext : allowedExtensions) {
            if (fileExtension.toLowerCase().equals(ext)) {
                isAllowed = true;
                break;
            }
        }
        
        if (!isAllowed) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "只能上传 JPG/PNG/PDF 格式的文件");
            return result;
        }
        
        String fileName = "auth_" + userId + "_" + UUID.randomUUID().toString() + fileExtension;
        String filePath = AUTH_MATERIAL_PATH + fileName;
        
        try {
            // 保存文件
            file.transferTo(new File(filePath));
            
            // 返回文件URL
            String fileUrl = "/auth/" + fileName;
            Map<String, Object> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("success", true);
            
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "上传失败");
            return result;
        }
    }
    
    @Override
    public AuthInfoVO getAuthInfo() {
        // 从数据库获取认证信息
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        AuthInfoVO authInfoVO = new AuthInfoVO();
        
        if (user != null) {
            // 根据店铺状态和认证材料设置认证状态
            Integer shopStatus = user.getShopStatus();
            boolean hasBusinessLicense = user.getBusinessLicense() != null && !user.getBusinessLicense().isEmpty();
            
            if (shopStatus == 1 && hasBusinessLicense) {
                authInfoVO.setStatus("approved"); // 已认证
            } else if (shopStatus == 2) {
                authInfoVO.setStatus("pending"); // 审核中
            } else if (shopStatus == 0 && hasBusinessLicense) {
                authInfoVO.setStatus("rejected"); // 认证失败
            } else {
                authInfoVO.setStatus("closed"); // 未认证或已关闭
            }
            
            authInfoVO.setAuthType(user.getBusinessType() != null ? user.getBusinessType() : "企业认证");
            
            if (user.getOpenTime() != null) {
                authInfoVO.setAuthTime(user.getOpenTime().toLocalDate().toString());
            } else {
                authInfoVO.setAuthTime("");
            }
            
            authInfoVO.setBusinessLicense(user.getBusinessLicense() != null ? user.getBusinessLicense() : "");
            authInfoVO.setIdCardFront(user.getLegalIdFront() != null ? user.getLegalIdFront() : "");
            authInfoVO.setIdCardBack(user.getLegalIdBack() != null ? user.getLegalIdBack() : "");
        } else {
            authInfoVO.setStatus("closed");
            authInfoVO.setAuthType("企业认证");
            authInfoVO.setAuthTime("");
            authInfoVO.setBusinessLicense("");
            authInfoVO.setIdCardFront("");
            authInfoVO.setIdCardBack("");
        }
        
        return authInfoVO;
    }
    
    @Override
    public boolean submitAuthInfo(Map<String, Object> authInfo) {
        // 获取当前登录用户ID
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            return false;
        }
        
        // 更新认证信息
        if (authInfo.containsKey("businessLicense")) {
            user.setBusinessLicense((String) authInfo.get("businessLicense"));
        }
        if (authInfo.containsKey("legalIdFront")) {
            user.setLegalIdFront((String) authInfo.get("legalIdFront"));
        }
        if (authInfo.containsKey("legalIdBack")) {
            user.setLegalIdBack((String) authInfo.get("legalIdBack"));
        }
        // 兼容前端使用的字段名
        if (authInfo.containsKey("idCardFront")) {
            user.setLegalIdFront((String) authInfo.get("idCardFront"));
        }
        if (authInfo.containsKey("idCardBack")) {
            user.setLegalIdBack((String) authInfo.get("idCardBack"));
        }
        if (authInfo.containsKey("shopName")) {
            user.setShopName((String) authInfo.get("shopName"));
        }
        if (authInfo.containsKey("businessType")) {
            user.setBusinessType((String) authInfo.get("businessType"));
        }
        if (authInfo.containsKey("shopAddress")) {
            user.setShopAddress((String) authInfo.get("shopAddress"));
        }
        if (authInfo.containsKey("shopDescription")) {
            user.setShopDescription((String) authInfo.get("shopDescription"));
        }
        
        // 更新状态为审核中
        user.setShopStatus(2); // 店铺状态：2-审核中
        user.setStatus((byte) 2); // 账号状态：2-待审核
        user.setHasShop((byte) 1); // 有店铺
        
        // 更新时间
        user.setUpdateTime(LocalDateTime.now());
        
        // 保存到数据库
        return userMapper.updateById(user) > 0;
    }
    
    @Override
    public SecurityInfoVO getSecurityInfo() {
        // 从数据库获取安全设置信息
        SecurityInfoVO securityInfoVO = new SecurityInfoVO();
        // 这里暂时返回默认值，实际项目中应该从数据库获取
        securityInfoVO.setPayPasswordSet(false); // 暂时固定为未设置
        return securityInfoVO;
    }
    
    @Override
    public boolean changePassword(String oldPassword, String newPassword, String confirmPassword) {
        // 获取当前登录用户ID
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            return false;
        }
        
        // 验证密码一致性
        if (!newPassword.equals(confirmPassword)) {
            return false;
        }
        
        // 验证旧密码
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            return false;
        }
        
        // 更新密码
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdateTime(LocalDateTime.now());
        return userMapper.updateById(user) > 0;
    }
    
    @Override
    public boolean setPayPassword(String payPassword, String confirmPassword) {
        // 获取当前登录用户ID
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            return false;
        }
        
        // 验证密码一致性
        if (!payPassword.equals(confirmPassword)) {
            return false;
        }
        
        // 实际项目中应该保存支付密码到数据库
        // 这里暂时返回成功，实际需要在User表中添加pay_password字段
        return true;
    }
    
    @Override
    public boolean changePayPassword(String oldPayPassword, String newPayPassword, String confirmPassword) {
        // 获取当前登录用户ID
        Long userId = getCurrentUserId();
        User user = userMapper.selectById(userId);
        
        if (user == null) {
            return false;
        }
        
        // 验证密码一致性
        if (!newPayPassword.equals(confirmPassword)) {
            return false;
        }
        
        // 实际项目中应该验证旧支付密码并更新新支付密码
        // 这里暂时返回成功，实际需要在User表中添加pay_password字段
        return true;
    }
    
    @Override
    public Map<String, Object> getDashboardData() {
        Map<String, Object> dashboardData = new HashMap<>();
        Long userId = getCurrentUserId();
        
        // 从数据库查询总订单数和总成交额
        QueryWrapper<Orders> orderQuery = new QueryWrapper<>();
        orderQuery.select("COUNT(*) as totalOrders, SUM(total_amount) as totalRevenue")
                .eq("seller_id", userId);
        Map<String, Object> orderStats = orderMapper.selectMaps(orderQuery).get(0);
        long totalOrdersCount = orderStats.get("totalOrders") != null ? Long.parseLong(orderStats.get("totalOrders").toString()) : 0;
        double totalRevenueAmount = orderStats.get("totalRevenue") != null ? Double.parseDouble(orderStats.get("totalRevenue").toString()) : 0;
        
        // 从数据库查询上架商品数
        QueryWrapper<Product> productQuery = new QueryWrapper<>();
        productQuery.select("COUNT(*) as totalProducts")
                .eq("seller_id", userId)
                .eq("is_on_shelf", 1);
        Map<String, Object> productStats = productMapper.selectMaps(productQuery).get(0);
        long totalProductsCount = productStats.get("totalProducts") != null ? Long.parseLong(productStats.get("totalProducts").toString()) : 0;
        
        // 模拟访客数（实际项目中应该从访问日志表查询）
        int totalVisitorsCount = 1256;
        
        // 计算趋势数据（与上月对比）
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime lastMonthStart = now.minusMonths(1).withDayOfMonth(1);
        LocalDateTime lastMonthEnd = now.withDayOfMonth(1).minusDays(1);
        LocalDateTime currentMonthStart = now.withDayOfMonth(1);
        
        // 当月订单数和成交额
        QueryWrapper<Orders> currentMonthQuery = new QueryWrapper<>();
        currentMonthQuery.select("COUNT(*) as currentOrders, SUM(total_amount) as currentRevenue")
                .eq("seller_id", userId)
                .ge("create_time", currentMonthStart);
        Map<String, Object> currentMonthStats = orderMapper.selectMaps(currentMonthQuery).get(0);
        long currentOrders = currentMonthStats.get("currentOrders") != null ? Long.parseLong(currentMonthStats.get("currentOrders").toString()) : 0;
        double currentRevenue = currentMonthStats.get("currentRevenue") != null ? Double.parseDouble(currentMonthStats.get("currentRevenue").toString()) : 0;
        
        // 上月订单数和成交额
        QueryWrapper<Orders> lastMonthQuery = new QueryWrapper<>();
        lastMonthQuery.select("COUNT(*) as lastOrders, SUM(total_amount) as lastRevenue")
                .eq("seller_id", userId)
                .ge("create_time", lastMonthStart)
                .le("create_time", lastMonthEnd);
        Map<String, Object> lastMonthStats = orderMapper.selectMaps(lastMonthQuery).get(0);
        long lastOrders = lastMonthStats.get("lastOrders") != null ? Long.parseLong(lastMonthStats.get("lastOrders").toString()) : 0;
        double lastRevenue = lastMonthStats.get("lastRevenue") != null ? Double.parseDouble(lastMonthStats.get("lastRevenue").toString()) : 0;
        
        // 计算订单趋势
        double orderTrend = lastOrders > 0 ? ((currentOrders - lastOrders) * 100.0 / lastOrders) : 0;
        // 计算成交额趋势
        double revenueTrend = lastRevenue > 0 ? ((currentRevenue - lastRevenue) * 100.0 / lastRevenue) : 0;
        // 计算商品趋势（与上月对比）
        double productTrend = 5.2; // 暂时使用模拟数据
        // 访客趋势
        double visitorTrend = -3.1; // 暂时使用模拟数据
        
        dashboardData.put("totalOrders", totalOrdersCount);
        dashboardData.put("totalRevenue", totalRevenueAmount);
        dashboardData.put("totalProducts", totalProductsCount);
        dashboardData.put("totalVisitors", totalVisitorsCount);
        
        dashboardData.put("orderTrend", orderTrend);
        dashboardData.put("revenueTrend", revenueTrend);
        dashboardData.put("productTrend", productTrend);
        dashboardData.put("visitorTrend", visitorTrend);
        
        return dashboardData;
    }
    
    @Override
    public Map<String, Object> getRecentOrders() {
        Map<String, Object> recentOrdersData = new HashMap<>();
        List<Map<String, Object>> orders = new ArrayList<>();
        Long userId = getCurrentUserId();
        
        // 从数据库查询最近订单
        QueryWrapper<Orders> orderQuery = new QueryWrapper<>();
        orderQuery.select("order_no as orderNo, recipient as customerName, total_amount as orderAmount, order_status as orderStatus, create_time as createTime")
                .eq("seller_id", userId)
                .orderByDesc("create_time")
                .last("LIMIT 4");
        
        List<Map<String, Object>> orderList = orderMapper.selectMaps(orderQuery);
        
        // 直接返回数字状态码，由前端负责转换为中文
        for (Map<String, Object> order : orderList) {
            orders.add(order);
        }
        
        recentOrdersData.put("orders", orders);
        return recentOrdersData;
    }
    
    @Override
    public Map<String, Object> getChartData() {
        Map<String, Object> chartData = new HashMap<>();
        Long userId = getCurrentUserId();
        
        // 从数据库查询最近7天的订单数据
        List<String> dates = new ArrayList<>();
        List<Integer> orders = new ArrayList<>();
        List<Double> revenue = new ArrayList<>();
        
        // 生成最近7天的日期
        SimpleDateFormat sdf = new SimpleDateFormat("MM月dd日");
        SimpleDateFormat dbFormat = new SimpleDateFormat("yyyy-MM-dd");
        
        for (int i = 6; i >= 0; i--) {
            Date date = new Date();
            date.setTime(date.getTime() - i * 24 * 60 * 60 * 1000);
            dates.add(sdf.format(date));
        }
        
        // 查询每天的订单数和成交额
        for (int i = 6; i >= 0; i--) {
            Date date = new Date();
            date.setTime(date.getTime() - i * 24 * 60 * 60 * 1000);
            String dateStr = dbFormat.format(date);
            
            QueryWrapper<Orders> dailyQuery = new QueryWrapper<>();
            dailyQuery.select("COUNT(*) as orderCount, SUM(total_amount) as revenue")
                    .eq("seller_id", userId)
                    .like("create_time", dateStr);
            
            Map<String, Object> dailyStats = orderMapper.selectMaps(dailyQuery).get(0);
            int orderCount = dailyStats.get("orderCount") != null ? Integer.parseInt(dailyStats.get("orderCount").toString()) : 0;
            double dailyRevenue = dailyStats.get("revenue") != null ? Double.parseDouble(dailyStats.get("revenue").toString()) : 0;
            
            orders.add(orderCount);
            revenue.add(dailyRevenue);
        }
        
        chartData.put("dates", dates);
        chartData.put("orders", orders);
        chartData.put("revenue", revenue);
        
        return chartData;
    }
    
    @Override
    public Map<String, Object> getCalendarSalesData() {
        Map<String, Object> calendarData = new HashMap<>();
        Map<String, Map<String, Object>> salesData = new HashMap<>();
        // 获取当前登录用户的ID
        Long userId = getCurrentUserId();
        
        // 从数据库查询所有历史销售订单数据
        
        // 查询所有销售数据，包含所有订单状态
        QueryWrapper<Orders> monthlyQuery = new QueryWrapper<>();
        monthlyQuery.select("DATE(create_time) as saleDate, COUNT(*) as orderCount, SUM(total_amount) as revenue")
                .eq("seller_id", userId)
                .groupBy("DATE(create_time)");
        
        List<Map<String, Object>> monthlyStats = orderMapper.selectMaps(monthlyQuery);
        
        // 整理数据格式
        for (Map<String, Object> stat : monthlyStats) {
            Object saleDateObj = stat.get("saleDate");
            String saleDate = "";
            if (saleDateObj instanceof java.sql.Date) {
                saleDate = saleDateObj.toString();
            } else if (saleDateObj instanceof String) {
                saleDate = (String) saleDateObj;
            }
            int orderCount = stat.get("orderCount") != null ? Integer.parseInt(stat.get("orderCount").toString()) : 0;
            double revenue = stat.get("revenue") != null ? Double.parseDouble(stat.get("revenue").toString()) : 0;
            
            Map<String, Object> dayData = new HashMap<>();
            dayData.put("orders", orderCount);
            dayData.put("revenue", revenue);
            salesData.put(saleDate, dayData);
        }
        
        // 确保返回的数据结构正确
        calendarData.put("salesData", salesData);
        return calendarData;
    }
    
    @Override
    public Map<String, Object> getProductDistributionData() {
        Map<String, Object> distributionData = new HashMap<>();
        List<Map<String, Object>> productData = new ArrayList<>();
        // 获取当前登录用户的ID
        Long userId = getCurrentUserId();
        
        // 从数据库查询不同类型器材的销售分布
        // 1. 全新器材 - product_type = 1
        // 2. 二手器材 - product_type = 2
        // 3. 租赁器材 - product_type = 3
        
        // 初始化各类型的销售数量
        int newCount = 0;
        int usedCount = 0;
        int rentalCount = 0;
        
        try {
            // 查询当前用户的所有订单
            QueryWrapper<Orders> orderQuery = new QueryWrapper<>();
            orderQuery.select("order_id")
                    .eq("seller_id", userId);
            List<Orders> orders = orderMapper.selectList(orderQuery);
            
            if (!orders.isEmpty()) {
                // 提取订单ID列表
                List<Long> orderIds = new ArrayList<>();
                for (Orders order : orders) {
                    orderIds.add(order.getOrderId());
                }
                
                // 查询这些订单的所有订单项
                if (!orderIds.isEmpty()) {
                    QueryWrapper<OrderItem> orderItemQuery = new QueryWrapper<>();
                    orderItemQuery.select("product_id")
                            .in("order_id", orderIds);
                    List<OrderItem> orderItems = orderItemMapper.selectList(orderItemQuery);
                    
                    if (!orderItems.isEmpty()) {
                        // 提取商品ID列表
                        List<Long> productIds = new ArrayList<>();
                        for (OrderItem item : orderItems) {
                            productIds.add(item.getProductId());
                        }
                        
                        // 查询这些商品的类型
                        if (!productIds.isEmpty()) {
                            QueryWrapper<Product> productQuery = new QueryWrapper<>();
                            productQuery.select("product_id", "product_type")
                                    .in("product_id", productIds);
                            List<Product> products = productMapper.selectList(productQuery);
                            
                            // 统计各类型的商品数量
                            for (Product product : products) {
                                Byte productTypeByte = product.getProductType();
                                int productType = productTypeByte != null ? productTypeByte.intValue() : 0;
                                switch (productType) {
                                    case 1:
                                        newCount++;
                                        break;
                                    case 2:
                                        usedCount++;
                                        break;
                                    case 3:
                                        rentalCount++;
                                        break;
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            // 出错时使用默认值
            newCount = 50;
            usedCount = 30;
            rentalCount = 20;
        }
        
        // 计算总数量
        int totalCount = newCount + usedCount + rentalCount;
        
        // 计算各类型的占比（如果总数量为0，使用默认值）
        int newPercentage = totalCount > 0 ? (int) Math.round((double) newCount / totalCount * 100) : 50;
        int usedPercentage = totalCount > 0 ? (int) Math.round((double) usedCount / totalCount * 100) : 30;
        int rentalPercentage = totalCount > 0 ? (int) Math.round((double) rentalCount / totalCount * 100) : 20;
        
        // 确保百分比总和为100
        if (totalCount > 0) {
            // 调整最后一个百分比，确保总和为100
            int sum = newPercentage + usedPercentage;
            rentalPercentage = 100 - sum;
            if (rentalPercentage < 0) rentalPercentage = 0;
        }
        
        // 构建返回数据
        Map<String, Object> newData = new HashMap<>();
        newData.put("name", "全新器材");
        newData.put("value", newPercentage);
        
        Map<String, Object> usedData = new HashMap<>();
        usedData.put("name", "二手器材");
        usedData.put("value", usedPercentage);
        
        Map<String, Object> rentalData = new HashMap<>();
        rentalData.put("name", "租赁器材");
        rentalData.put("value", rentalPercentage);
        
        productData.add(newData);
        productData.add(usedData);
        productData.add(rentalData);
        
        distributionData.put("data", productData);
        return distributionData;
    }
}