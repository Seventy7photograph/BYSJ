package bysj.pets.bec.service;

import bysj.pets.bec.entity.Product;
import bysj.pets.bec.entity.vo.GoodsDetailVO;
import bysj.pets.bec.entity.vo.GoodsVO;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;


import java.util.List;
import java.util.Map;

public interface ProductService extends IService<Product> {
    /**
     * 分页查询商品列表
     */
    IPage<GoodsVO> getGoodsList(Map<String, Object> params);

    /**
     * 获取商品图片URL
     */
    String getProductImageUrl(Long productId);

    /**
     * 获取分类列表
     */
    Map<String, Object> getCategoryList();

    // 根据父类ID获取子类分类（用于下拉框）
    List<Map<String, Object>> getSubCategoriesByParentId(Integer parentId);

    /**
     * 根据分类获取品牌列表
     */
    List<Map<String, Object>> getBrandsByParentId(Integer parentId);

    /**
     * 获取品牌树形结构
     */
    Map<String, Object> getBrandTree();

    // 添加商品详情查询方法
    GoodsDetailVO getGoodsDetail(Long productId);
    
    // 获取相关商品推荐
    List<GoodsVO> getRelatedProducts(Integer categoryId, Integer limit, Long productId);
    
    /**
     * 获取商家商品列表
     */
    IPage<?> getMerchantProductList(Map<String, Object> params);
    
    /**
     * 添加商品
     */
    boolean addProduct(Map<String, Object> productData);
    
    /**
     * 编辑商品
     */
    boolean updateProduct(Long productId, Map<String, Object> productData);
    
    /**
     * 上下架商品
     */
    boolean toggleProductStatus(Long productId, Byte status);
    
    /**
     * 删除商品
     */
    boolean deleteProduct(Long productId);
    
    /**
     * 获取商家商品详情
     */
    Map<String, Object> getMerchantProductDetail(Long productId);

    /**
     * 获取商品图片
     */
    List<Map<String, Object>> getProductImages(Long productId);

    /**
     * 获取SKU列表
     */
    List<Map<String, Object>> getSkuList(Long productId);
    
    /**
     * 添加SKU
     */
    boolean addSku(Long productId, Map<String, Object> skuData);
    
    /**
     * 编辑SKU
     */
    boolean updateSku(Long productId, Long skuId, Map<String, Object> skuData);
    
    /**
     * 删除SKU
     */
    boolean deleteSku(Long productId, Long skuId);
    
    /**
     * 获取带品牌名称的商品列表
     */
    IPage<Map<String, Object>> getProductListWithBrandName(IPage<Map<String, Object>> page, Map<String, Object> params);
}
