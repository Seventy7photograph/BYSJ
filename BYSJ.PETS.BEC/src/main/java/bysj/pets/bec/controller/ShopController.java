package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.vo.GoodsDetailVO;
import bysj.pets.bec.entity.vo.GoodsVO;
import bysj.pets.bec.service.ProductService;
import com.baomidou.mybatisplus.core.metadata.IPage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;


import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/shop")
public class ShopController {

    @Autowired
    private ProductService productService;

    /**
     * 获取商品列表（分页）。
     *
     * 前端 api/user/shop.ts 一直在调 /shop/products，但后端只有
     * /shop/random-products，商城列表页因此永远拿不到数据。
     * 这里补上语义正确的入口，并把「随机」降级为一个显式的排序选项。
     */
    @GetMapping("/products")
    public Map<String, Object> getProducts(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "20") Integer pageSize,
            @RequestParam(required = false) String quality,
            @RequestParam(required = false) String condition,
            @RequestParam(required = false) Integer productType,
            @RequestParam(required = false) String priceRange) {

        IPage<GoodsVO> goodsPage = productService.getGoodsList(
                buildQuery(category, brand, type, keyword, sort, pageNum, pageSize,
                        quality, condition, productType, priceRange));
        return toPageResult(goodsPage);
    }

    /**
     * 获取随机商品列表
     */
    @GetMapping("/random-products")
    public Map<String, Object> getRandomProducts(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "20") Integer pageSize,
            @RequestParam(required = false) String quality,
            @RequestParam(required = false) String condition,
            @RequestParam(required = false) Integer productType,
            @RequestParam(required = false) String priceRange) {

        // 未显式指定排序时保持原有的「随机」语义，其余情况与 /products 一致
        String effectiveSort = (sort == null || sort.isBlank()) ? "random" : sort;
        IPage<GoodsVO> goodsPage = productService.getGoodsList(
                buildQuery(category, brand, type, keyword, effectiveSort, pageNum, pageSize,
                        quality, condition, productType, priceRange));
        return toPageResult(goodsPage);
    }

    /** 组装商品列表查询条件，/products 与 /random-products 共用。 */
    private Map<String, Object> buildQuery(String category, String brand, String type, String keyword,
                                           String sort, Integer pageNum, Integer pageSize,
                                           String quality, String condition, Integer productType,
                                           String priceRange) {
        Map<String, Object> params = new HashMap<>();
        params.put("category", category);
        params.put("brand", brand);
        params.put("type", type);
        params.put("keyword", keyword);
        params.put("sort", sort);
        params.put("pageNum", pageNum);
        params.put("pageSize", pageSize);
        params.put("quality", quality);
        params.put("condition", condition);
        params.put("productType", productType);
        params.put("priceRange", priceRange);
        return params;
    }

    private Map<String, Object> toPageResult(IPage<GoodsVO> goodsPage) {
        Map<String, Object> result = new HashMap<>();
        result.put("list", goodsPage.getRecords());
        result.put("total", goodsPage.getTotal());
        result.put("pageNum", goodsPage.getCurrent());
        result.put("pageSize", goodsPage.getSize());
        result.put("pages", goodsPage.getPages());

        return result;
    }

    /**
     * 获取分类列表
     */
    @GetMapping("/categories")
    public Map<String, Object> getCategories() {
        return productService.getCategoryList();
    }

    /**
     * 根据分类获取品牌列表
     */
    @GetMapping("/brands")
    public Map<String, Object> getBrands(@RequestParam  Integer parentId) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> brands = productService.getBrandsByParentId(parentId);
        result.put("brands", brands);
        result.put("success", true);
        return result;
    }

    /**
     * 根据父类ID获取子类分类（用于器材类型下拉框）
     * @param parentId 父类分类ID（如相机的category_id）
     * @return 子类分类列表（包含label和value）
     */
    @GetMapping("/sub-categories")
    public Map<String, Object> getSubCategories(@RequestParam Integer parentId) {
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> subCategories = productService.getSubCategoriesByParentId(parentId);
        result.put("subCategories", subCategories);
        result.put("success", true);
        return result;
    }

    /**
     * 获取商品详情
     */
    @GetMapping("/products/{productId}")
    public Result<?> getProductDetail(@PathVariable Long productId) {
        try {
            GoodsDetailVO goodsDetail = productService.getGoodsDetail(productId);
            if (goodsDetail == null) {
                return Result.error("商品不存在或已下架");
            }
            return Result.success("获取商品详情成功", goodsDetail);
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("获取商品详情失败：" + e.getMessage());
        }
    }

    /**
     * 获取相关商品推荐
     */
    @GetMapping("/related")
    public Map<String, Object> getRelatedProducts(
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(defaultValue = "4") Integer limit,
            @RequestParam(required = false) Long productId) {
        Map<String, Object> result = new HashMap<>();
        List<GoodsVO> relatedProducts = productService.getRelatedProducts(categoryId, limit, productId);
        result.put("data", relatedProducts);
        result.put("success", true);
        return result;
    }
}
