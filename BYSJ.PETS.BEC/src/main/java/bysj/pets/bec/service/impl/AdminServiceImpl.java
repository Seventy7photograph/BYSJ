package bysj.pets.bec.service.impl;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.entity.Orders;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.entity.SysLog;
import bysj.pets.bec.service.AdminService;
import bysj.pets.bec.mapper.ProductMapper;
import bysj.pets.bec.mapper.OrderMapper;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.mapper.ProductCategoryMapper;
import bysj.pets.bec.mapper.SysLogMapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class AdminServiceImpl implements AdminService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private OrderMapper orderMapper;

    @Autowired
    private ProductCategoryMapper productCategoryMapper;

    @Autowired
    private SysLogMapper sysLogMapper;

    @Override
    public Result<Map<String, Object>> getAdminDashboardData() {
        Map<String, Object> dashboardData = new HashMap<>();

        // 普通用户数
        long userCount = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUserType, (byte) 1));
        dashboardData.put("userCount", userCount);

        // 商家用户数
        long merchantCount = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUserType, (byte) 2));
        dashboardData.put("merchantCount", merchantCount);

        // 全新器材数
        long newProductCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 1));
        dashboardData.put("newProductCount", newProductCount);

        // 二手器材数
        long usedProductCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 2));
        dashboardData.put("usedProductCount", usedProductCount);

        // 租赁器材数
        long rentalProductCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 3));
        dashboardData.put("rentalProductCount", rentalProductCount);

        // 待审核器材数
        long pendingProductsCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getAuditStatus, (byte) 0));
        dashboardData.put("pendingProductsCount", pendingProductsCount);

        // 商品分类数
        long categoryCount = productCategoryMapper.selectCount(null);
        dashboardData.put("categoryCount", categoryCount);

        // 最近操作记录
        List<Map<String, Object>> recentOperations = getRecentOperations(5);
        dashboardData.put("recentOperations", recentOperations);

        // 图表数据
        dashboardData.put("userGrowthTrend", getUserGrowthTrend(7));
        dashboardData.put("orderTrend", getOrderTrend(7));
        dashboardData.put("categoryDistribution", getCategoryDistribution());
        dashboardData.put("productTypeDistribution", getProductTypeDistribution());
        dashboardData.put("pendingProductStatus", getPendingProductStatus());
        dashboardData.put("hotProducts", getHotProducts(5));

        return Result.success(dashboardData);
    }

    @Override
    public Result<Map<String, Object>> getSuperAdminDashboardData() {
        Map<String, Object> dashboardData = new HashMap<>();

        // 普通用户数
        long userCount = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUserType, (byte) 1));
        dashboardData.put("userCount", userCount);

        // 商家用户数
        long merchantCount = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUserType, (byte) 2));
        dashboardData.put("merchantCount", merchantCount);

        // 管理员用户数
        long adminCount = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUserType, (byte) 3));
        dashboardData.put("adminCount", adminCount);

        // 全新器材数
        long newProductCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 1));
        dashboardData.put("newProductCount", newProductCount);

        // 二手器材数
        long usedProductCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 2));
        dashboardData.put("usedProductCount", usedProductCount);

        // 租赁器材数
        long rentalProductCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 3));
        dashboardData.put("rentalProductCount", rentalProductCount);

        // 总订单数
        long totalOrders = orderMapper.selectCount(null);
        dashboardData.put("totalOrders", totalOrders);

        // 总成交额
        BigDecimal totalRevenue = orderMapper.selectList(null).stream()
                .map(Orders::getTotalAmount)
                .filter(amount -> amount != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        dashboardData.put("totalRevenue", totalRevenue);

        // 最近操作记录
        List<Map<String, Object>> recentOperations = getRecentOperations(5);
        dashboardData.put("recentOperations", recentOperations);

        // 图表数据
        dashboardData.put("userGrowthTrend", getUserGrowthTrend(7));
        dashboardData.put("orderTrend", getOrderTrend(7));
        dashboardData.put("categoryDistribution", getCategoryDistribution());
        dashboardData.put("productTypeDistribution", getProductTypeDistribution());
        dashboardData.put("orderTypeDistribution", getOrderTypeDistribution());
        dashboardData.put("hotProducts", getHotProducts(5));

        return Result.success(dashboardData);
    }

    @Override
    public List<Map<String, Object>> getRecentOperations(int limit) {
        List<Map<String, Object>> operations = new ArrayList<>();
        
        // 查询最近的操作日志
        List<SysLog> sysLogs = sysLogMapper.selectList(new LambdaQueryWrapper<SysLog>()
                .eq(SysLog::getLogType, 1) // 1-操作日志
                .orderByDesc(SysLog::getCreateTime)
                .last("LIMIT " + limit));
        
        for (SysLog log : sysLogs) {
            Map<String, Object> operation = new HashMap<>();
            // 查询操作人信息
            User user = userMapper.selectById(log.getUserId());
            operation.put("operator", user != null ? user.getUsername() : "系统");
            operation.put("operation", log.getOperation());
            operation.put("target", log.getModule());
            operation.put("result", "成功"); // 简化处理，实际应根据操作结果设置
            operation.put("operationTime", log.getCreateTime());
            operations.add(operation);
        }
        
        return operations;
    }

    @Override
    public Map<String, Object> getUserGrowthTrend(int days) {
        Map<String, Object> trendData = new HashMap<>();
        List<String> dates = new ArrayList<>();
        List<Long> userCounts = new ArrayList<>();

        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1);

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");

        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            dates.add(date.format(formatter));
            LocalDateTime startOfDay = date.atStartOfDay();
            LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();

            long count = userMapper.selectCount(new LambdaQueryWrapper<User>()
                    .lt(User::getCreateTime, endOfDay)
                    .ge(User::getCreateTime, startOfDay));
            userCounts.add(count);
        }

        trendData.put("dates", dates);
        trendData.put("users", userCounts);
        return trendData;
    }

    @Override
    public Map<String, Object> getOrderTrend(int days) {
        Map<String, Object> trendData = new HashMap<>();
        List<String> dates = new ArrayList<>();
        List<Long> orderCounts = new ArrayList<>();

        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1);

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");

        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            dates.add(date.format(formatter));
            LocalDateTime startOfDay = date.atStartOfDay();
            LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();

            long count = orderMapper.selectCount(new LambdaQueryWrapper<Orders>()
                    .lt(Orders::getCreateTime, endOfDay)
                    .ge(Orders::getCreateTime, startOfDay));
            orderCounts.add(count);
        }

        trendData.put("dates", dates);
        trendData.put("orders", orderCounts);
        return trendData;
    }

    @Override
    public List<Map<String, Object>> getCategoryDistribution() {
        // 真实统计：各一级分类下已上架的商品数。
        // 原实现返回一组写死的数字（相机 1048、镜头 735……），与库里的 37 件商品
        // 毫无关系，任何页面拿它展示都是在编数据。
        return productMapper.countOnShelfGroupByCategory();
    }

    @Override
    public List<Map<String, Object>> getProductTypeDistribution() {
        List<Map<String, Object>> distribution = new ArrayList<>();

        long newCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 1));
        long usedCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 2));
        long rentalCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getProductType, (byte) 3));

        distribution.add(Map.of("name", "全新器材", "value", newCount));
        distribution.add(Map.of("name", "二手器材", "value", usedCount));
        distribution.add(Map.of("name", "租赁器材", "value", rentalCount));

        return distribution;
    }

    @Override
    public List<Map<String, Object>> getPendingProductStatus() {
        List<Map<String, Object>> statusList = new ArrayList<>();

        long pendingCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getAuditStatus, (byte) 0));
        long approvedCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getAuditStatus, (byte) 1));
        long rejectedCount = productMapper.selectCount(new LambdaQueryWrapper<Product>()
                .eq(Product::getAuditStatus, (byte) 2));

        statusList.add(Map.of("name", "待审核", "value", pendingCount));
        // 原实现把「审核中」也统计成 audit_status = 0，和「待审核」永远是同一个数；
        // 系统里没有独立的"审核中"状态，这里改成真实存在的「已通过」。
        statusList.add(Map.of("name", "已通过", "value", approvedCount));
        statusList.add(Map.of("name", "已驳回", "value", rejectedCount));

        return statusList;
    }

    @Override
    public List<Map<String, Object>> getOrderTypeDistribution() {
        // 真实成交：按商品类型统计已支付及之后状态的订单项数量
        List<Map<String, Object>> distribution = new ArrayList<>();
        Map<Long, String> labels = Map.of(1L, "全新器材", 2L, "二手器材", 3L, "租赁器材");
        for (Map<String, Object> row : productMapper.salesGroupByProductType()) {
            Object type = row.get("productType");
            Object value = row.get("value");
            if (type == null || value == null) {
                continue;
            }
            long typeCode = Long.parseLong(type.toString());
            distribution.add(Map.of("name", labels.getOrDefault(typeCode, "其他"), "value", value));
        }
        return distribution;
    }

    @Override
    public List<Map<String, Object>> getHotProducts(int limit) {
        // 真实的按成交量排序的热销器材（原来是一组编造的型号与件数）
        return productMapper.selectTopSellingProducts(limit);
    }
}
