package bysj.pets.bec.service;

import bysj.pets.bec.config.Result;

import java.util.List;
import java.util.Map;

public interface AdminService {

    /**
     * 获取管理员仪表盘数据
     * @return 仪表盘数据
     */
    Result<Map<String, Object>> getAdminDashboardData();

    /**
     * 获取超级管理员仪表盘数据
     * @return 仪表盘数据
     */
    Result<Map<String, Object>> getSuperAdminDashboardData();

    /**
     * 获取最近操作记录
     * @param limit 限制数量
     * @return 操作记录列表
     */
    List<Map<String, Object>> getRecentOperations(int limit);

    /**
     * 获取用户增长趋势数据
     * @param days 天数
     * @return 趋势数据
     */
    Map<String, Object> getUserGrowthTrend(int days);

    /**
     * 获取订单数量趋势数据
     * @param days 天数
     * @return 趋势数据
     */
    Map<String, Object> getOrderTrend(int days);

    /**
     * 获取摄影器材分类分布数据
     * @return 分布数据
     */
    List<Map<String, Object>> getCategoryDistribution();

    /**
     * 获取器材类型分布数据
     * @return 分布数据
     */
    List<Map<String, Object>> getProductTypeDistribution();

    /**
     * 获取待审核器材状态数据
     * @return 状态数据
     */
    List<Map<String, Object>> getPendingProductStatus();

    /**
     * 获取订单类型分布数据
     * @return 分布数据
     */
    List<Map<String, Object>> getOrderTypeDistribution();

    /**
     * 获取热门器材排行数据
     * @param limit 限制数量
     * @return 排行数据
     */
    List<Map<String, Object>> getHotProducts(int limit);
}
