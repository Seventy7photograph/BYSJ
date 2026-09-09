package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.ProductService;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 商家商品管理控制器
 */
@RestController
@RequestMapping("/merchant/product")
public class MerchantProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private UserMapper userMapper;

    /**
     * 获取商家商品列表
     */
    @GetMapping("/list")
    public Result<?> getMerchantProductList(
            @RequestParam(required = true) String type,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        
        Map<String, Object> params = new HashMap<>();
        params.put("type", type);
        params.put("status", status);
        params.put("keyword", keyword);
        params.put("pageNum", pageNum);
        params.put("pageSize", pageSize);
        
        // 根据商品类型映射到数据库中的product_type
        Integer productType = null;
        if ("new".equals(type)) {
            productType = 1;
        } else if ("used".equals(type)) {
            productType = 2;
        } else if ("rental".equals(type)) {
            productType = 3;
        }
        params.put("productType", productType);
        
        IPage<?> productPage = productService.getMerchantProductList(params);
        
        Map<String, Object> result = new HashMap<>();
        result.put("list", productPage.getRecords());
        result.put("total", productPage.getTotal());
        result.put("page", productPage.getCurrent());
        result.put("pageSize", productPage.getSize());
        
        return Result.success("获取商品列表成功", result);
    }
    
    /**
     * 添加商品
     */
    @PostMapping
    public Result<?> addProduct(@RequestBody Map<String, Object> productData) {
        boolean success = productService.addProduct(productData);
        if (success) {
            return Result.success("添加商品成功");
        } else {
            return Result.error("添加商品失败");
        }
    }
    
    /**
     * 编辑商品
     */
    @PutMapping("/{productId}")
    public Result<?> updateProduct(@PathVariable Long productId, @RequestBody Map<String, Object> productData) {
        boolean success = productService.updateProduct(productId, productData);
        if (success) {
            return Result.success("编辑商品成功");
        } else {
            return Result.error("编辑商品失败");
        }
    }
    
    /**
     * 上下架商品
     */
    @PutMapping("/{productId}/status")
    public Result<?> toggleProductStatus(@PathVariable Long productId, @RequestBody Map<String, Object> request) {
        Byte status = Byte.parseByte(request.get("status").toString());
        boolean success = productService.toggleProductStatus(productId, status);
        if (success) {
            return Result.success("商品状态更新成功");
        } else {
            return Result.error("商品状态更新失败");
        }
    }
    
    /**
     * 删除商品
     */
    @DeleteMapping("/{productId}")
    public Result<?> deleteProduct(@PathVariable Long productId) {
        boolean success = productService.deleteProduct(productId);
        if (success) {
            return Result.success("删除商品成功");
        } else {
            return Result.error("删除商品失败");
        }
    }
    
    /**
     * 获取商品详情
     */
    @GetMapping("/{productId}")
    public Result<?> getProductDetail(@PathVariable Long productId) {
        Map<String, Object> productDetail = productService.getMerchantProductDetail(productId);
        if (productDetail != null) {
            return Result.success("获取商品详情成功", productDetail);
        } else {
            return Result.error("商品不存在");
        }
    }

    /**
     * 获取商品图片
     */
    @GetMapping("/{productId}/images")
    public Result<?> getProductImages(@PathVariable Long productId) {
        List<Map<String, Object>> images = productService.getProductImages(productId);
        return Result.success("获取商品图片成功", images);
    }
    
    /**
     * 获取SKU列表
     */
    @GetMapping("/{productId}/skus")
    public Result<?> getSkuList(@PathVariable Long productId) {
        List<Map<String, Object>> skuList = productService.getSkuList(productId);
        return Result.success("获取SKU列表成功", skuList);
    }
    
    /**
     * 获取分类列表
     */
    @GetMapping("/categories")
    public Result<?> getCategoryList() {
        Map<String, Object> categoryList = productService.getCategoryList();
        return Result.success("获取分类列表成功", categoryList);
    }
    
    /**
     * 根据父分类ID获取子分类列表
     */
    @GetMapping("/sub-categories")
    public Result<?> getSubCategoriesByParentId(@RequestParam Integer parentId) {
        List<Map<String, Object>> subCategories = productService.getSubCategoriesByParentId(parentId);
        return Result.success("获取子分类列表成功", subCategories);
    }
    
    /**
     * 根据分类获取品牌列表
     */
    @GetMapping("/brands")
    public Result<?> getBrandsByParentId(@RequestParam Integer parentId) {
        List<Map<String, Object>> brands = productService.getBrandsByParentId(parentId);
        return Result.success("获取品牌列表成功", brands);
    }
    
    /**
     * 获取品牌树形结构
     */
    @GetMapping("/brand-tree")
    public Result<?> getBrandTree() {
        Map<String, Object> brandTree = productService.getBrandTree();
        return Result.success("获取品牌树形结构成功", brandTree);
    }
    
    /**
     * 添加SKU
     */
    @PostMapping("/{productId}/skus")
    public Result<?> addSku(@PathVariable Long productId, @RequestBody Map<String, Object> skuData) {
        boolean success = productService.addSku(productId, skuData);
        if (success) {
            return Result.success("添加SKU成功");
        } else {
            return Result.error("添加SKU失败");
        }
    }
    
    /**
     * 编辑SKU
     */
    @PutMapping("/{productId}/skus/{skuId}")
    public Result<?> updateSku(@PathVariable Long productId, @PathVariable Long skuId, @RequestBody Map<String, Object> skuData) {
        boolean success = productService.updateSku(productId, skuId, skuData);
        if (success) {
            return Result.success("编辑SKU成功");
        } else {
            return Result.error("编辑SKU失败");
        }
    }
    
    /**
     * 删除SKU
     */
    @DeleteMapping("/{productId}/skus/{skuId}")
    public Result<?> deleteSku(@PathVariable Long productId, @PathVariable Long skuId) {
        boolean success = productService.deleteSku(productId, skuId);
        if (success) {
            return Result.success("删除SKU成功");
        } else {
            return Result.error("删除SKU失败");
        }
    }
}