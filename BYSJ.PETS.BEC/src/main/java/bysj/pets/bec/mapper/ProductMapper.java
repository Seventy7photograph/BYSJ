package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Product;
import bysj.pets.bec.entity.ProductRentalDetail;
import bysj.pets.bec.entity.vo.GoodsDetailVO;
import bysj.pets.bec.entity.vo.GoodsVO;
import bysj.pets.bec.entity.vo.InventoryHistoryVO;
import bysj.pets.bec.entity.vo.InventoryItemVO;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;


import java.util.List;

public interface ProductMapper extends BaseMapper<Product> {

    /**
     * 分页查询商品列表
     * 注意：不要在XML中手动写LIMIT，分页插件会自动处理
     */
    List<GoodsVO> selectGoodsList(
            @Param("categoryCodes") List<String> categoryCodes,
//            @Param("category") String category,
            @Param("brand") String brand,
            @Param("type") String type,
            @Param("keyword") String keyword,
            @Param("sort") String sort,
            @Param("quality") String quality,
            @Param("condition") String condition,
            @Param("productType") Integer productType,
            @Param("priceRange") String priceRange
    );

    /**
     * 获取符合条件的商品总数
     */
    long selectGoodsTotal(
            @Param("categoryCodes") List<String> categoryCodes,
//            @Param("category") String category,
            @Param("brand") String brand,
            @Param("type") String type,
            @Param("keyword") String keyword,
            @Param("quality") String quality,
            @Param("condition") String condition,
            @Param("productType") Integer productType,
            @Param("priceRange") String priceRange
    );

    /**
     * 查询商品详情（关联product_detail表）
     */
    GoodsDetailVO selectGoodsDetail(@Param("productId") Long productId);
    
    /**
     * 获取相关商品推荐
     */
    List<GoodsVO> selectRelatedProducts(@Param("categoryId") Integer categoryId, @Param("limit") Integer limit, @Param("productId") Long productId, @Param("productType") Byte productType);
    
    /**
     * 查询商品主图
     */
    String selectMainImageByProductId(@Param("productId") Long productId);
    
    /**
     * 查询商品规格
     */
    String selectSpecificationsByProductId(@Param("productId") Long productId);
    
    /**
     * 查询品牌名称
     */
    String selectBrandNameByProductId(@Param("productId") Long productId);

    /**
     * 查询租赁商品详情
     */
    ProductRentalDetail selectRentalDetailByProductId(@Param("productId") Long productId);

    /**
     * 按商品统计真实销量（已支付及之后状态的订单项数量之和）。
     * 原实现把销量硬编码成 0，商家后台的销量列因此永远显示 0。
     */
    List<java.util.Map<String, Object>> selectSalesByProductIds(@Param("productIds") List<Long> productIds);

    /** 各一级分类下的在架商品数量，用于管理端分类分布。 */
    List<java.util.Map<String, Object>> countOnShelfGroupByCategory();

    /** 各交易线（全新/二手/租赁）的真实成交量，按订单项数量求和。 */
    List<java.util.Map<String, Object>> salesGroupByProductType();

    /** 真实的热销器材（按已成交件数排序）。 */
    List<java.util.Map<String, Object>> selectTopSellingProducts(@Param("limit") int limit);

    /**
     * 原子扣减库存：只有剩余量足够时才会更新，返回受影响行数。
     *
     * 原来的写法是"查出来 → 在 Java 里减 → updateById"，两个并发订单会同时读到
     * 同一个余量各自计算，最后一单必然超卖，库存还可能被减成负数。
     * 条件写在 WHERE 里之后，扣减由数据库保证原子性，返回 0 即为库存不足。
     */
    int decreaseStockIfEnough(@Param("productId") Long productId, @Param("quantity") Integer quantity);

    /** 原子回补库存（取消订单 / 退款 / 归还）。 */
    int increaseStock(@Param("productId") Long productId, @Param("quantity") Integer quantity);

    /** 把 product.stock 同步到对应的 inventory 行（若存在），保持商家端库存视图一致。 */
    int syncInventoryFromProduct(@Param("productId") Long productId);

    // 库存管理相关方法
    /**
     * 获取库存列表
     */
    List<InventoryItemVO> selectInventoryList(
            @Param("productType") String productType,
            @Param("stockStatus") String stockStatus,
            @Param("keyword") String keyword
    );
    
    /**
     * 获取库存总数
     */
    long selectInventoryTotal(
            @Param("productType") String productType,
            @Param("stockStatus") String stockStatus,
            @Param("keyword") String keyword
    );
    
    /**
     * 获取库存详情
     */
    InventoryItemVO selectInventoryDetail(@Param("productId") Long productId);
    
    /**
     * 获取库存变更历史
     */
    List<InventoryHistoryVO> selectInventoryHistory(
            @Param("productId") Long productId
    );
    
    /**
     * 获取库存变更历史总数
     */
    long selectInventoryHistoryTotal(@Param("productId") Long productId);
    
    /**
     * 调整库存
     */
    boolean updateProductStock(@Param("productId") Long productId, @Param("newStock") Integer newStock);
    
    /**
     * 设置安全库存
     */
    boolean updateMinStock(@Param("productId") Long productId, @Param("minStock") Integer minStock);

    /**
     * 插入租赁商品详情
     */
    int insertRentalDetail(ProductRentalDetail rentalDetail);

    /**
     * 更新租赁商品详情
     */
    int updateRentalDetail(ProductRentalDetail rentalDetail);

    /**
     * 查询带品牌名称的商品列表（用于商品审核）
     */
    com.baomidou.mybatisplus.core.metadata.IPage<java.util.Map<String, Object>> selectProductListWithBrandName(
            com.baomidou.mybatisplus.core.metadata.IPage<java.util.Map<String, Object>> page,
            @Param("productName") String productName,
            @Param("brand") String brand,
            @Param("model") String model,
            @Param("productType") Integer productType,
            @Param("auditStatus") Byte auditStatus
    );

}
