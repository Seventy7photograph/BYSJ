package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.*;
import bysj.pets.bec.entity.vo.GoodsDetailVO;
import bysj.pets.bec.entity.vo.GoodsVO;
import bysj.pets.bec.mapper.*;
import bysj.pets.bec.service.ProductService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.Blob;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ProductServiceImpl extends ServiceImpl<ProductMapper, Product> implements ProductService {

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private ProductImageMapper productImageMapper;

    @Autowired
    private SysImageMapper sysImageMapper;

    @Autowired
    private ProductCategoryMapper productCategoryMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private OrderMapper orderMapper;

    @Autowired
    private OrderItemMapper orderItemMapper;

    @Autowired
    private ProductDetailMapper productDetailMapper;

    @Autowired
    private SkuMapper skuMapper;
    
    // ObjectMapper用于JSON序列化和反序列化
    private ObjectMapper objectMapper;
    
    // 构造方法，初始化ObjectMapper
    public ProductServiceImpl() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    }

    @Override
    public IPage<GoodsVO> getGoodsList(Map<String, Object> params) {
        Integer pageNum = (Integer) params.get("pageNum");
        Integer pageSize = (Integer) params.get("pageSize");
        String category = (String) params.get("category");  // 前端传入的分类编码（如"camera"）
        String brand = (String) params.get("brand");
        String type = (String) params.get("type");
        String keyword = (String) params.get("keyword");
        String sort = (String) params.get("sort");
        String quality = (String) params.get("quality");
        String condition = (String) params.get("condition");  // 成色筛选
        Integer productType = (Integer) params.get("productType");  // 商品类型（1-全新, 2-二手, 3-租赁）
        String priceRange = (String) params.get("priceRange");  // 租金范围筛选
        System.out.println("DEBUG: priceRange = " + priceRange); // 添加调试日志

        // 1. 处理分类参数：查询所有子孙分类编码（含自身）
        List<String> categoryCodes = new ArrayList<>();
        // 只有当type参数不存在或为空时，才处理category参数
        if ((type == null || type.isEmpty()) && category != null && !category.isEmpty() && !"all".equals(category)) {
            // 1.1 根据分类编码查询对应的分类ID（ancestorId）
            ProductCategory parentCategory = productCategoryMapper.selectOne(
                    new LambdaQueryWrapper<ProductCategory>()
                            .eq(ProductCategory::getCategoryCode, category)
            );
            if (parentCategory != null) {
                // 1.2 递归查询所有子孙分类的category_code
                categoryCodes = productCategoryMapper.selectAllChildCategoryCodes(parentCategory.getCategoryId());
                if (categoryCodes == null) {
                    categoryCodes = new ArrayList<>();
                }
                // 1.3 如果没有子分类，直接使用当前分类编码
                if (categoryCodes.isEmpty()) {
                    categoryCodes.add(category);
                }
            } else {
                // 1.4 如果找不到分类，直接使用传入的分类编码
                categoryCodes.add(category);
            }
        }

        // 2. 创建分页对象
        Page<GoodsVO> page = new Page<>(pageNum, pageSize);

        // 3. 执行分页查询（传入多分类编码列表）
        // 确保condition是字符串类型，与前端保持一致
        String conditionStr = condition;
        
        // 构建查询条件
        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<GoodsVO> queryWrapper = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        
        // 4. 查询总数
        long total = productMapper.selectGoodsTotal(
                categoryCodes, brand, type, keyword, quality, conditionStr, productType, priceRange
        );
        page.setTotal(total);
        
        // 5. 计算分页范围
        int start = (pageNum - 1) * pageSize;
        int end = start + pageSize;
        
        // 6. 执行查询并进行手动分页
        List<GoodsVO> allGoodsList = productMapper.selectGoodsList(
                categoryCodes, brand, type, keyword, sort, quality, conditionStr, productType, priceRange
        );
        
        // 7. 截取分页数据
        List<GoodsVO> pagedGoodsList = new ArrayList<>();
        for (int i = start; i < end && i < allGoodsList.size(); i++) {
            pagedGoodsList.add(allGoodsList.get(i));
        }
        
        page.setRecords(pagedGoodsList);

        // 8. 处理图片和库存提示（保持不变）
        for (GoodsVO goods : pagedGoodsList) {
            goods.setImageUrl(getProductImageUrl(goods.getProductId()));
            goods.setStockTip("库存充足");
        }

        return page;
    }

    // 在ProductServiceImpl中检查getProductImageUrl方法
    @Override
    public String getProductImageUrl(Long productId) {
        // 查询商品主图
        ProductImage productImage = productImageMapper.selectMainImageByProductId(productId);
        if (productImage != null) {
            SysImage sysImage = sysImageMapper.selectById(productImage.getImageId());
            if (sysImage != null) {
                // 确保返回的URL是完整可用的
                String storagePath = sysImage.getStoragePath();
                // 如果存储的是相对路径，添加前缀
                if (!storagePath.startsWith("http") && !storagePath.startsWith("/")) {
                    return "/" + storagePath;
                }
                return storagePath;
            }
        }
        // 返回默认图片
        return "/images/default-product.png";
    }

    // 构建树形分类结构
    private List<Map<String, Object>> buildCategoryTree(List<ProductCategory> allCategories) {
        List<Map<String, Object>> tree = new ArrayList<>();
        
        // 1. 构建分类映射，方便查找父分类
        Map<Integer, Map<String, Object>> categoryMap = new HashMap<>();
        for (ProductCategory category : allCategories) {
            Map<String, Object> categoryNode = new HashMap<>();
            categoryNode.put("id", category.getCategoryId());
            categoryNode.put("value", category.getCategoryCode());
            categoryNode.put("name", category.getCategoryName());
            categoryNode.put("icon", "el-icon-camera"); // 可以根据实际情况设置不同图标
            categoryNode.put("children", new ArrayList<Map<String, Object>>());
            categoryMap.put(category.getCategoryId(), categoryNode);
        }
        
        // 2. 构建树形结构
        for (ProductCategory category : allCategories) {
            Integer parentId = category.getParentId();
            Map<String, Object> categoryNode = categoryMap.get(category.getCategoryId());
            
            if (parentId == null) {
                // 顶级分类，直接添加到树中
                tree.add(categoryNode);
            } else {
                // 子分类，添加到父分类的children中
                Map<String, Object> parentNode = categoryMap.get(parentId);
                if (parentNode != null) {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> children = (List<Map<String, Object>>) parentNode.get("children");
                    children.add(categoryNode);
                }
            }
        }
        
        return tree;
    }

    @Override
    public Map<String, Object> getCategoryList() {
        Map<String, Object> result = new HashMap<>();
        
        // 查询所有分类
        List<ProductCategory> allCategories = productCategoryMapper.selectAllCategories();
        System.out.println("getCategoryList: 查询到的所有分类 = " + allCategories);
        
        // 构建树形分类结构
        List<Map<String, Object>> categoryTree = buildCategoryTree(allCategories);
        System.out.println("getCategoryList: 构建的树形分类结构 = " + categoryTree);
        
        // 查询主分类（顶级分类）
        List<ProductCategory> mainCategories = productCategoryMapper.selectMainCategories();
        System.out.println("getCategoryList: 查询到的主分类 = " + mainCategories);
        
        List<Map<String, Object>> categoryList = new ArrayList<>();
        for (ProductCategory category : mainCategories) {
            Map<String, Object> categoryMap = new HashMap<>();
            categoryMap.put("id", category.getCategoryId());
            categoryMap.put("value", category.getCategoryCode());
            categoryMap.put("name", category.getCategoryName());
            categoryMap.put("icon", "el-icon-camera"); // 可以根据实际情况设置不同图标
            categoryList.add(categoryMap);
        }
        
        // 返回主分类列表和完整的树形分类结构
        result.put("categoryList", categoryList);
        result.put("categoryTree", categoryTree);
        
        return result;
    }

    // 构建品牌树形结构
    private List<Map<String, Object>> buildBrandTree(List<Brand> allBrands) {
        List<Map<String, Object>> tree = new ArrayList<>();
        
        // 1. 构建品牌映射，方便查找父品牌
        Map<Integer, Map<String, Object>> brandMap = new HashMap<>();
        for (Brand brand : allBrands) {
            Map<String, Object> brandNode = new HashMap<>();
            brandNode.put("id", brand.getBrandId());
            brandNode.put("value", brand.getBrandId());
            brandNode.put("name", brand.getBrandName());
            brandNode.put("children", new ArrayList<Map<String, Object>>());
            brandMap.put(brand.getBrandId(), brandNode);
        }
        
        // 2. 构建树形结构
        for (Brand brand : allBrands) {
            Integer parentId = brand.getParentId();
            Map<String, Object> brandNode = brandMap.get(brand.getBrandId());
            
            if (parentId == null) {
                // 顶级品牌，直接添加到树中
                tree.add(brandNode);
            } else {
                // 子品牌，添加到父品牌的children中
                Map<String, Object> parentNode = brandMap.get(parentId);
                if (parentNode != null) {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> children = (List<Map<String, Object>>) parentNode.get("children");
                    children.add(brandNode);
                }
            }
        }
        
        return tree;
    }

    @Override
    public List<Map<String, Object>> getBrandsByParentId(Integer parentId) {
        List<Map<String, Object>> brands = new ArrayList<>();
        if (parentId == null) {
            return brands; // 父类ID为空时返回空列表
        }

        // 通过parent_id查询所有子孙品牌（包含递归查询）
        List<Brand> brandList = productCategoryMapper.selectChildBrandsByParentId(parentId);

        for (Brand brand : brandList) {
            Map<String, Object> brandMap = new HashMap<>();
            brandMap.put("label", brand.getBrandName());  // 品牌名称
            brandMap.put("value", brand.getBrandId());    // 品牌ID
            brands.add(brandMap);
        }
        return brands;
    }
    
    /**
     * 获取品牌树形结构
     */
    public Map<String, Object> getBrandTree() {
        Map<String, Object> result = new HashMap<>();
        
        // 查询所有品牌
        List<Brand> allBrands = productCategoryMapper.selectAllBrands();
        System.out.println("getBrandTree: 查询到的所有品牌 = " + allBrands);
        
        // 构建树形品牌结构
        List<Map<String, Object>> brandTree = buildBrandTree(allBrands);
        System.out.println("getBrandTree: 构建的树形品牌结构 = " + brandTree);
        
        result.put("brandTree", brandTree);
        
        return result;
    }


    @Override
    public List<Map<String, Object>> getSubCategoriesByParentId(Integer parentId) {
        List<Map<String, Object>> subCategoryList = new ArrayList<>();
        if (parentId == null) {
            System.out.println("getSubCategoriesByParentId: parentId is null");
            return subCategoryList; // 父类ID为空时返回空列表
        }

        System.out.println("getSubCategoriesByParentId: parentId = " + parentId);
        // 调用Mapper查询子类分类
        List<ProductCategory> categories = productCategoryMapper.selectChildCategoriesByParentId(parentId);
        System.out.println("getSubCategoriesByParentId: 查询到的子分类数量 = " + categories.size());
        System.out.println("getSubCategoriesByParentId: 查询到的子分类 = " + categories);

        // 转换为前端下拉框需要的格式（label显示名称，value存储分类编码）
        for (ProductCategory category : categories) {
            Map<String, Object> categoryMap = new HashMap<>();
            categoryMap.put("label", category.getCategoryName()); // 下拉框显示的文本
            categoryMap.put("value", category.getCategoryCode()); // 下拉框选中的值（分类编码）
            subCategoryList.add(categoryMap);
        }
        System.out.println("getSubCategoriesByParentId: 返回的子分类列表 = " + subCategoryList);
        return subCategoryList;
    }
    @Override
    public GoodsDetailVO getGoodsDetail(Long productId) {
        try {
            System.out.println("获取商品详情，商品ID：" + productId);
            GoodsDetailVO goodsDetail = productMapper.selectGoodsDetail(productId);
            System.out.println("查询商品详情结果：" + goodsDetail);
            if (goodsDetail == null) {
                System.out.println("商品详情为空，商品ID：" + productId);
                return null;
            }

            // 查询商品原始数据，获取商品类型和价格
            Product product = productMapper.selectById(productId);
            System.out.println("查询商品原始数据结果：" + product);
            if (product != null) {
                // 如果是租赁商品，从product_rental_detail表获取租赁相关信息
                Byte productType = product.getProductType();
                System.out.println("商品类型：" + productType);
                if (productType != null && productType == 3) {
                    // 从product_rental_detail表查询租赁详情
                    ProductRentalDetail rentalDetail = productMapper.selectRentalDetailByProductId(productId);
                    System.out.println("查询租赁详情结果：" + rentalDetail);
                    if (rentalDetail != null) {
                        // 设置押金
                        if (rentalDetail.getDeposit() != null) {
                            goodsDetail.setDeposit(rentalDetail.getDeposit());
                        } else {
                            goodsDetail.setDeposit(BigDecimal.ZERO);
                        }
                        // 设置最大租赁天数
                        if (rentalDetail.getMaxRentalDays() != null) {
                            goodsDetail.setMaxRentalDays(rentalDetail.getMaxRentalDays());
                        } else {
                            goodsDetail.setMaxRentalDays(90);
                        }
                        // 设置最小租赁天数
                        if (rentalDetail.getMinRentalDays() != null) {
                            goodsDetail.setMinRentalDays(rentalDetail.getMinRentalDays());
                        } else {
                            goodsDetail.setMinRentalDays(1);
                        }
                        // 设置保险费用
                        if (rentalDetail.getInsuranceFee() != null) {
                            goodsDetail.setInsuranceFee(rentalDetail.getInsuranceFee());
                        } else {
                            goodsDetail.setInsuranceFee(BigDecimal.ZERO);
                        }
                        // 设置逾期违约金率
                        if (rentalDetail.getLateFeeRate() != null) {
                            goodsDetail.setLateFeeRate(rentalDetail.getLateFeeRate());
                        } else {
                            goodsDetail.setLateFeeRate(BigDecimal.valueOf(0.05));
                        }
                        // 设置损坏赔偿规则
                        if (rentalDetail.getDamageFeeRule() != null) {
                            goodsDetail.setDamageFeeRule(rentalDetail.getDamageFeeRule());
                        } else {
                            goodsDetail.setDamageFeeRule("请联系客服了解详细赔偿规则");
                        }
                        // 设置取货方式
                        if (rentalDetail.getPickupMethods() != null) {
                            goodsDetail.setPickupMethods(rentalDetail.getPickupMethods());
                        } else {
                            goodsDetail.setPickupMethods("delivery");
                        }
                        // 设置配送费用
                        if (rentalDetail.getDeliveryFee() != null) {
                            goodsDetail.setDeliveryFee(rentalDetail.getDeliveryFee());
                        } else {
                            goodsDetail.setDeliveryFee(BigDecimal.ZERO);
                        }
                    } else {
                        // 如果没有租赁详情，使用默认值
                        // 计算押金：商品原价 * 10%
                        BigDecimal originalPrice = product.getOriginalPrice() != null ? product.getOriginalPrice() : BigDecimal.ZERO;
                        goodsDetail.setDeposit(originalPrice.multiply(BigDecimal.valueOf(0.1)));
                        // 默认最大租赁天数
                        goodsDetail.setMaxRentalDays(90);
                        // 默认最小租赁天数
                        goodsDetail.setMinRentalDays(1);
                        // 默认保险费用
                        goodsDetail.setInsuranceFee(BigDecimal.ZERO);
                        // 默认逾期违约金率
                        goodsDetail.setLateFeeRate(BigDecimal.valueOf(0.05));
                        // 默认损坏赔偿规则
                        goodsDetail.setDamageFeeRule("请联系客服了解详细赔偿规则");
                        // 默认取货方式
                        goodsDetail.setPickupMethods("delivery");
                        // 默认配送费用
                        goodsDetail.setDeliveryFee(BigDecimal.ZERO);
                    }
                } else {
                    // 非租赁商品，押金为0
                    goodsDetail.setDeposit(BigDecimal.ZERO);
                }
            }

            System.out.println("获取商品详情成功，商品ID：" + productId);
            return goodsDetail;
        } catch (Exception e) {
            System.out.println("获取商品详情失败，商品ID：" + productId);
            e.printStackTrace();
            return null;
        }
    }

    @Override
    public List<GoodsVO> getRelatedProducts(Integer categoryId, Integer limit, Long productId) {
        if (categoryId == null || limit == null || limit <= 0 || productId == null) {
            return Collections.emptyList();
        }
        // 获取当前商品的类型
        Product product = productMapper.selectById(productId);
        if (product == null) {
            return Collections.emptyList();
        }
        return productMapper.selectRelatedProducts(categoryId, limit, productId, product.getProductType());
    }

    @Override
    public IPage<?> getMerchantProductList(Map<String, Object> params) {
        System.out.println("进入getMerchantProductList方法");
        Integer pageNum = (Integer) params.get("pageNum");
        Integer pageSize = (Integer) params.get("pageSize");
        Integer productType = (Integer) params.get("productType");
        String status = (String) params.get("status");
        String keyword = (String) params.get("keyword");

        System.out.println("参数: pageNum=" + pageNum + ", pageSize=" + pageSize + ", productType=" + productType + ", status=" + status + ", keyword=" + keyword);

        // 获取当前登录用户信息
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        System.out.println("当前登录用户: " + principal);
        
        Long sellerId = 8L; // 默认商家用户ID，根据实际数据调整
        
        // 如果不是匿名用户，尝试获取真实用户信息
        if (principal != null && !"anonymousUser".equals(principal)) {
            String username;
            if (principal instanceof UserDetails) {
                username = ((UserDetails) principal).getUsername();
            } else {
                username = principal.toString();
            }
            System.out.println("用户名: " + username);
            
            // 根据用户名查询用户信息，获取sellerId
            User user = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
            System.out.println("查询到的用户: " + user);
            if (user != null) {
                sellerId = user.getUserId();
            }
        }
        
        System.out.println("使用的sellerId: " + sellerId);

        // 创建分页对象
        Page<Product> page = new Page<>(pageNum, pageSize);

        // 构建查询条件
        LambdaQueryWrapper<Product> queryWrapper = new LambdaQueryWrapper<>();
        // 添加seller_id过滤，只查询当前商家的商品
        queryWrapper.eq(Product::getSellerId, sellerId);
        if (productType != null) {
            queryWrapper.eq(Product::getProductType, productType);
        }
        if (status != null && !status.isEmpty()) {
            // 将String类型的status转换为Byte类型
            try {
                Byte isOnShelf = Byte.parseByte(status);
                queryWrapper.eq(Product::getIsOnShelf, isOnShelf);
            } catch (NumberFormatException e) {
                // 转换失败，忽略status条件
                System.out.println("status参数格式错误，忽略该条件: " + status);
            }
        }
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like(Product::getModel, keyword);
        }

        // 查询商品列表
        IPage<Product> productPage = this.page(page, queryWrapper);

        // 转换为前端需要的格式
        Page<Map<String, Object>> resultPage = new Page<>(pageNum, pageSize);
        resultPage.setTotal(productPage.getTotal());

        List<Map<String, Object>> productList = new ArrayList<>();
        for (Product product : productPage.getRecords()) {
            Map<String, Object> productMap = new HashMap<>();
            productMap.put("productId", product.getProductId());
            productMap.put("name", product.getModel());
            productMap.put("price", product.getPrice());
            productMap.put("stock", product.getStock());
            productMap.put("sales", 0); // 销量暂时用0代替
            productMap.put("isOnShelf", product.getIsOnShelf());
            productMap.put("auditStatus", product.getAuditStatus());
            productMap.put("rejectReason", product.getRejectReason());
            productMap.put("createTime", product.getCreateTime());

            // 根据商品类型设置不同的字段
            if (product.getProductType() == 2) {
                // 二手商品 - 添加成色字段
                productMap.put("condition", product.getCondition());
            } else if (product.getProductType() == 3) {
                // 租赁商品
                ProductRentalDetail rentalDetail = productMapper.selectRentalDetailByProductId(product.getProductId());
                if (rentalDetail != null) {
                    productMap.put("deposit", rentalDetail.getDeposit());
                    productMap.put("minRentalDays", rentalDetail.getMinRentalDays());
                } else {
                    productMap.put("deposit", product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)));
                    productMap.put("minRentalDays", 1);
                }
            }

            productList.add(productMap);
        }

        resultPage.setRecords(productList);
        return resultPage;
    }

    @Override
    public boolean addProduct(Map<String, Object> productData) {
        try {
            // 1. 解析商品数据
            
            // 2. 创建Product对象
            Product product = new Product();
            
            // 3. 设置基本信息
            product.setModel((String) productData.get("model"));
            
            Object brandValue = productData.get("brand");
            if (brandValue != null) {
                product.setBrand(Integer.parseInt(brandValue.toString()));
            }
            
            Object categoryIdValue = productData.get("categoryId");
            if (categoryIdValue != null) {
                product.setCategoryId(Integer.parseInt(categoryIdValue.toString()));
            }
            
            Object priceValue = productData.get("price");
            if (priceValue != null) {
                product.setPrice(BigDecimal.valueOf(Double.parseDouble(priceValue.toString())));
            }
            
            Object originalPriceValue = productData.get("originalPrice");
            if (originalPriceValue != null) {
                product.setOriginalPrice(BigDecimal.valueOf(Double.parseDouble(originalPriceValue.toString())));
            }
            
            Object stockValue = productData.get("stock");
            if (stockValue != null) {
                product.setStock(Integer.parseInt(stockValue.toString()));
            }
            
            Object productTypeValue = productData.get("productType");
            if (productTypeValue != null) {
                product.setProductType(Byte.parseByte(productTypeValue.toString()));
            }
            
            // 设置商品初始状态：待审核，未上架
            product.setAuditStatus((byte) 0); // 0-待审核
            product.setIsOnShelf((byte) 0); // 0-未上架
            
            Object conditionValue = productData.get("condition");
            if (conditionValue != null) {
                product.setCondition(Byte.parseByte(conditionValue.toString()));
            }
            product.setCreateTime(java.time.LocalDateTime.now());
            product.setUpdateTime(java.time.LocalDateTime.now());
            
            // 4. 获取当前登录用户ID作为卖家ID
            Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            Long sellerId = 8L; // 默认商家用户ID
            if (principal != null && !"anonymousUser".equals(principal)) {
                String username;
                if (principal instanceof UserDetails) {
                    username = ((UserDetails) principal).getUsername();
                } else {
                    username = principal.toString();
                }
                User user = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
                if (user != null) {
                    sellerId = user.getUserId();
                }
            }
            product.setSellerId(sellerId);
            
            // 5. 保存商品
            this.save(product);
            
            // 6. 保存商品详情到product_detail表
            ProductDetail productDetail = new ProductDetail();
            productDetail.setProductId(product.getProductId());
            
            Object descriptionObj = productData.get("description");
            if (descriptionObj != null) {
                productDetail.setDescription((String) descriptionObj);
            }
            
            // 设置必填字段的默认值
            productDetail.setParameters("{}");
            productDetail.setImgUrls("[]");
            
            // 处理二手商品的额外字段
            Object usageDurationObj = productData.get("usageDuration");
            if (usageDurationObj != null) {
                productDetail.setUsageDuration((String) usageDurationObj);
            }
            
            Object repairHistoryObj = productData.get("repairHistory");
            if (repairHistoryObj != null) {
                if (repairHistoryObj instanceof Integer) {
                    productDetail.setRepairHistory(((Integer) repairHistoryObj).byteValue());
                } else if (repairHistoryObj instanceof String) {
                    productDetail.setRepairHistory(Byte.parseByte((String) repairHistoryObj));
                }
            }
            
            Object accessoriesObj = productData.get("accessories");
            if (accessoriesObj != null) {
                productDetail.setAccessories((String) accessoriesObj);
            }
            
            productDetail.setCreateTime(java.time.LocalDateTime.now());
            productDetail.setUpdateTime(java.time.LocalDateTime.now());
            productDetailMapper.insert(productDetail);
            
            // 7. 处理商品图片关联
            List<?> imageIdsRaw = productData.get("imageIds") instanceof List ?
                    (List<?>) productData.get("imageIds") :
                    new ArrayList<>();

            System.out.println("收到的imageIds: " + imageIdsRaw);

            // 收集图片路径，用于更新product_detail表中的img_urls字段
            List<String> imagePaths = new ArrayList<>();

            if (!imageIdsRaw.isEmpty()) {
                for (int i = 0; i < imageIdsRaw.size(); i++) {
                    Object imageIdObj = imageIdsRaw.get(i);
                    System.out.println("处理第 " + i + " 张图片，imageId对象: " + imageIdObj + ", 类型: " + (imageIdObj != null ? imageIdObj.getClass().getName() : "null"));

                    Long imageId = null;
                    if (imageIdObj instanceof Integer) {
                        imageId = ((Integer) imageIdObj).longValue();
                    } else if (imageIdObj instanceof Long) {
                        imageId = (Long) imageIdObj;
                    }

                    if (imageId == null) {
                        System.out.println("imageId 为 null，跳过此图片");
                        continue;
                    }

                    // 查询图片路径
                    SysImage sysImage = sysImageMapper.selectById(imageId);
                    if (sysImage != null) {
                        imagePaths.add(sysImage.getStoragePath());
                    }

                    ProductImage productImage = new ProductImage();
                    productImage.setProductId(product.getProductId());
                    productImage.setImageId(imageId);
                    productImage.setImageType("main");
                    productImage.setSort(i);
                    productImage.setCreateTime(java.time.LocalDateTime.now());
                    productImage.setIsDeleted(0);
                    productImageMapper.insert(productImage);
                }
            }

            // 8. 更新product_detail表中的img_urls字段
        if (!imagePaths.isEmpty()) {
            String imgUrlsJson = objectMapper.writeValueAsString(imagePaths);
            productDetail.setImgUrls(imgUrlsJson);
            // 执行更新操作，保存img_urls字段
            productDetailMapper.updateById(productDetail);
        }
            
            // 9. 处理租赁商品的起租天数
            if (product.getProductType() == 3) {
                Object minRentalDaysObj = productData.get("minRentalDays");
                Integer minRentalDays = 1; // 默认值
                if (minRentalDaysObj != null) {
                    if (minRentalDaysObj instanceof Integer) {
                        minRentalDays = (Integer) minRentalDaysObj;
                    } else if (minRentalDaysObj instanceof String) {
                        minRentalDays = Integer.parseInt((String) minRentalDaysObj);
                    }
                }
                
                // 处理押金
                Object depositObj = productData.get("deposit");
                BigDecimal deposit = product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)); // 默认押金为原价的10%
                if (depositObj != null) {
                    if (depositObj instanceof Number) {
                        deposit = new BigDecimal(depositObj.toString());
                    } else if (depositObj instanceof String) {
                        deposit = new BigDecimal((String) depositObj);
                    }
                }
                
                // 创建或更新ProductRentalDetail记录
                ProductRentalDetail rentalDetail = productMapper.selectRentalDetailByProductId(product.getProductId());
                if (rentalDetail == null) {
                    rentalDetail = new ProductRentalDetail();
                    rentalDetail.setProductId(product.getProductId());
                    rentalDetail.setDeposit(deposit);
                    rentalDetail.setMinRentalDays(minRentalDays);
                    rentalDetail.setMaxRentalDays(90); // 默认最大租赁天数
                    rentalDetail.setInsuranceFee(BigDecimal.ZERO); // 默认保险费用
                    rentalDetail.setLateFeeRate(BigDecimal.valueOf(0.05)); // 默认逾期违约金率
                    rentalDetail.setDamageFeeRule("请联系客服了解详细赔偿规则"); // 默认损坏赔偿规则
                    rentalDetail.setPickupMethods("delivery"); // 默认取货方式
                    rentalDetail.setDeliveryFee(BigDecimal.ZERO); // 默认配送费用
                    productMapper.insertRentalDetail(rentalDetail);
                } else {
                    rentalDetail.setDeposit(deposit);
                    rentalDetail.setMinRentalDays(minRentalDays);
                    productMapper.updateRentalDetail(rentalDetail);
                }
            }
            
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean updateProduct(Long productId, Map<String, Object> productData) {
        try {
            System.out.println("开始更新商品，productId: " + productId);
            System.out.println("商品数据: " + productData);

            Product product = this.getById(productId);
            if (product == null) {
                System.out.println("商品不存在，productId: " + productId);
                return false;
            }

            Object categoryIdObj = productData.get("categoryId");
            if (categoryIdObj != null) {
                if (categoryIdObj instanceof Integer) {
                    product.setCategoryId((Integer) categoryIdObj);
                } else if (categoryIdObj instanceof String) {
                    product.setCategoryId(Integer.parseInt((String) categoryIdObj));
                }
            }

            Object brandObj = productData.get("brand");
            if (brandObj != null) {
                if (brandObj instanceof Integer) {
                    product.setBrand((Integer) brandObj);
                } else if (brandObj instanceof Long) {
                    product.setBrand(((Long) brandObj).intValue());
                } else if (brandObj instanceof String) {
                    product.setBrand(Integer.parseInt((String) brandObj));
                }
            }

            Object modelObj = productData.get("model");
            if (modelObj != null) {
                product.setModel((String) modelObj);
            }

            Object originalPriceObj = productData.get("originalPrice");
            if (originalPriceObj != null) {
                if (originalPriceObj instanceof Number) {
                    product.setOriginalPrice(new java.math.BigDecimal(originalPriceObj.toString()));
                } else if (originalPriceObj instanceof String) {
                    product.setOriginalPrice(new java.math.BigDecimal((String) originalPriceObj));
                }
            }

            Object priceObj = productData.get("price");
            if (priceObj != null) {
                if (priceObj instanceof Number) {
                    product.setPrice(new java.math.BigDecimal(priceObj.toString()));
                } else if (priceObj instanceof String) {
                    product.setPrice(new java.math.BigDecimal((String) priceObj));
                }
            }

            Object stockObj = productData.get("stock");
            if (stockObj != null) {
                if (stockObj instanceof Integer) {
                    product.setStock((Integer) stockObj);
                } else if (stockObj instanceof Long) {
                    product.setStock(((Long) stockObj).intValue());
                } else if (stockObj instanceof String) {
                    product.setStock(Integer.parseInt((String) stockObj));
                }
            }

            Object minStockObj = productData.get("minStock");
            if (minStockObj != null) {
                if (minStockObj instanceof Integer) {
                    product.setMinStock((Integer) minStockObj);
                } else if (minStockObj instanceof Long) {
                    product.setMinStock(((Long) minStockObj).intValue());
                } else if (minStockObj instanceof String) {
                    product.setMinStock(Integer.parseInt((String) minStockObj));
                }
            }

            Object productTypeObj = productData.get("productType");
            if (productTypeObj != null) {
                if (productTypeObj instanceof Integer) {
                    product.setProductType(((Integer) productTypeObj).byteValue());
                } else if (productTypeObj instanceof String) {
                    product.setProductType(Byte.parseByte((String) productTypeObj));
                }
            }

            if (product.getProductType() == 1) {
                Object colorObj = productData.get("color");
                if (colorObj != null) {
                    product.setColor((String) colorObj);
                }
                product.setCondition(null);
            } else if (product.getProductType() == 2) {
                Object conditionObj = productData.get("condition");
                if (conditionObj != null) {
                    if (conditionObj instanceof Integer) {
                        product.setCondition(((Integer) conditionObj).byteValue());
                    } else if (conditionObj instanceof Long) {
                        product.setCondition(((Long) conditionObj).byteValue());
                    } else if (conditionObj instanceof String) {
                        product.setCondition(Byte.parseByte((String) conditionObj));
                    }
                }
                product.setColor(null);
            } else if (product.getProductType() == 3) {
            Object minRentalDaysObj = productData.get("minRentalDays");
            Integer minRentalDays = 1; // 默认值
            if (minRentalDaysObj != null) {
                if (minRentalDaysObj instanceof Integer) {
                    minRentalDays = (Integer) minRentalDaysObj;
                    product.setMinRentalDays(minRentalDays);
                } else if (minRentalDaysObj instanceof Long) {
                    minRentalDays = ((Long) minRentalDaysObj).intValue();
                    product.setMinRentalDays(minRentalDays);
                } else if (minRentalDaysObj instanceof String) {
                    minRentalDays = Integer.parseInt((String) minRentalDaysObj);
                    product.setMinRentalDays(minRentalDays);
                }
            }
            
            // 处理押金
            Object depositObj = productData.get("deposit");
            BigDecimal deposit = product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)); // 默认押金为原价的10%
            if (depositObj != null) {
                if (depositObj instanceof Number) {
                    deposit = new BigDecimal(depositObj.toString());
                } else if (depositObj instanceof String) {
                    deposit = new BigDecimal((String) depositObj);
                }
            }
            
            // 创建或更新ProductRentalDetail记录
            ProductRentalDetail rentalDetail = productMapper.selectRentalDetailByProductId(product.getProductId());
            if (rentalDetail == null) {
                rentalDetail = new ProductRentalDetail();
                rentalDetail.setProductId(product.getProductId());
                rentalDetail.setDeposit(deposit);
                rentalDetail.setMinRentalDays(minRentalDays);
                rentalDetail.setMaxRentalDays(90); // 默认最大租赁天数
                rentalDetail.setInsuranceFee(BigDecimal.ZERO); // 默认保险费用
                rentalDetail.setLateFeeRate(BigDecimal.valueOf(0.05)); // 默认逾期违约金率
                rentalDetail.setDamageFeeRule("请联系客服了解详细赔偿规则"); // 默认损坏赔偿规则
                rentalDetail.setPickupMethods("delivery"); // 默认取货方式
                rentalDetail.setDeliveryFee(BigDecimal.ZERO); // 默认配送费用
                productMapper.insertRentalDetail(rentalDetail);
            } else {
                rentalDetail.setDeposit(deposit);
                rentalDetail.setMinRentalDays(minRentalDays);
                productMapper.updateRentalDetail(rentalDetail);
            }
            
            product.setColor(null);
            product.setCondition(null);
        }

            product.setUpdateTime(java.time.LocalDateTime.now());

            boolean result = this.updateById(product);
            System.out.println("更新结果: " + result);

            // 先获取product_detail对象
            ProductDetail productDetail = productDetailMapper.selectOne(
                new LambdaQueryWrapper<ProductDetail>().eq(ProductDetail::getProductId, productId)
            );
            
            if (productDetail == null) {
                productDetail = new ProductDetail();
                productDetail.setProductId(productId);
                productDetail.setCreateTime(java.time.LocalDateTime.now());
                // 设置必填字段的默认值
                productDetail.setParameters("{}");
                productDetail.setImgUrls("[]");
            }

            List<?> imageIdsObj = (List<?>) productData.get("imageIds");
            if (imageIdsObj != null && !imageIdsObj.isEmpty()) {
                List<Long> imageIds = new ArrayList<>();
                for (Object imageIdObj : imageIdsObj) {
                    if (imageIdObj instanceof Integer) {
                        imageIds.add(((Integer) imageIdObj).longValue());
                    } else if (imageIdObj instanceof Long) {
                        imageIds.add((Long) imageIdObj);
                    }
                }
                System.out.println("更新商品图片，imageIds: " + imageIds);

                // 收集图片路径，用于更新product_detail表中的img_urls字段
                List<String> imagePaths = new ArrayList<>();

                LambdaQueryWrapper<ProductImage> deleteWrapper = new LambdaQueryWrapper<>();
                deleteWrapper.eq(ProductImage::getProductId, productId);
                productImageMapper.delete(deleteWrapper);

                for (int i = 0; i < imageIds.size(); i++) {
                    Long imageId = imageIds.get(i);
                    
                    // 查询图片路径
                    SysImage sysImage = sysImageMapper.selectById(imageId);
                    if (sysImage != null) {
                        imagePaths.add(sysImage.getStoragePath());
                    }

                    ProductImage productImage = new ProductImage();
                    productImage.setProductId(productId);
                    productImage.setImageId(imageId);
                    productImage.setImageType("main");
                    productImage.setSort(i);
                    productImage.setCreateTime(java.time.LocalDateTime.now());
                    productImageMapper.insert(productImage);
                }

                // 更新product_detail表中的img_urls字段
                if (!imagePaths.isEmpty()) {
                    ObjectMapper objectMapper = new ObjectMapper();
                    String imgUrlsJson = objectMapper.writeValueAsString(imagePaths);
                    productDetail.setImgUrls(imgUrlsJson);
                }
            }
            
            Object descriptionObj = productData.get("description");
            if (descriptionObj != null) {
                productDetail.setDescription((String) descriptionObj);
            }
            
            Object usageDurationObj = productData.get("usageDuration");
            if (usageDurationObj != null) {
                productDetail.setUsageDuration((String) usageDurationObj);
            }
            
            Object repairHistoryObj = productData.get("repairHistory");
            if (repairHistoryObj != null) {
                if (repairHistoryObj instanceof Integer) {
                    productDetail.setRepairHistory(((Integer) repairHistoryObj).byteValue());
                } else if (repairHistoryObj instanceof String) {
                    productDetail.setRepairHistory(Byte.parseByte((String) repairHistoryObj));
                }
            }
            
            Object accessoriesObj = productData.get("accessories");
            if (accessoriesObj != null) {
                productDetail.setAccessories((String) accessoriesObj);
            }
            
            productDetail.setUpdateTime(java.time.LocalDateTime.now());
            
            if (productDetail.getDetailId() == null) {
                productDetailMapper.insert(productDetail);
            } else {
                productDetailMapper.updateById(productDetail);
            }

            return result;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean toggleProductStatus(Long productId, Byte status) {
        // 上下架商品，使用自定义查询，不包含is_on_shelf和audit_status条件
        Product product = productMapper.selectOne(new LambdaQueryWrapper<Product>().eq(Product::getProductId, productId));
        if (product == null) {
            return false;
        }
        product.setIsOnShelf(status);
        return this.updateById(product);
    }

    @Override
    public boolean deleteProduct(Long productId) {
        System.out.println("开始删除商品，productId: " + productId);

        Product product = this.getById(productId);
        if (product == null) {
            System.out.println("商品不存在，productId: " + productId);
            return false;
        }

        System.out.println("查询到商品: " + product);
        System.out.println("商品sellerId: " + product.getSellerId());

        // 检查商品是否有关联的订单项
        LambdaQueryWrapper<OrderItem> orderItemWrapper = new LambdaQueryWrapper<>();
        orderItemWrapper.eq(OrderItem::getProductId, productId);
        Long orderItemCount = orderItemMapper.selectCount(orderItemWrapper);

        System.out.println("关联的订单项数量: " + orderItemCount);

        if (orderItemCount != null && orderItemCount > 0) {
            System.out.println("商品有关联的订单项，不允许删除");
            return false;
        }

        // 1. 删除商品图片关联
        LambdaQueryWrapper<ProductImage> productImageWrapper = new LambdaQueryWrapper<>();
        productImageWrapper.eq(ProductImage::getProductId, productId);
        List<ProductImage> productImages = productImageMapper.selectList(productImageWrapper);
        productImageMapper.delete(productImageWrapper);

        // 2. 记录需要删除的图片ID
        List<Long> imageIdsToDelete = productImages.stream()
                .map(ProductImage::getImageId)
                .collect(Collectors.toList());

        // 3. 删除商品详情
        LambdaQueryWrapper<ProductDetail> productDetailWrapper = new LambdaQueryWrapper<>();
        productDetailWrapper.eq(ProductDetail::getProductId, productId);
        productDetailMapper.delete(productDetailWrapper);

        // 4. 删除商品
        System.out.println("开始删除商品");
        boolean result = this.removeById(productId);
        System.out.println("删除结果: " + result);

        // 5. 删除物理图片（可选，根据业务需求决定是否删除）
        // 注意：实际项目中，图片删除需要谨慎，可能需要考虑其他地方是否还在使用该图片
        // 这里仅作为示例，实际项目中需要根据业务需求决定是否删除
        /*
        if (result && !imageIdsToDelete.isEmpty()) {
            for (Long imageId : imageIdsToDelete) {
                SysImage sysImage = sysImageMapper.selectById(imageId);
                if (sysImage != null) {
                    // 删除物理文件
                    try {
                        File file = new File(sysImage.getStoragePath());
                        if (file.exists()) {
                            file.delete();
                        }
                        // 删除数据库中的图片记录
                        sysImageMapper.deleteById(imageId);
                    } catch (Exception e) {
                        e.printStackTrace();
                        System.out.println("删除图片失败，imageId: " + imageId);
                    }
                }
            }
        }
        */

        return result;
    }

    @Override
    public Map<String, Object> getMerchantProductDetail(Long productId) {
        Product product = this.getById(productId);
        if (product == null) {
            return null;
        }

        Map<String, Object> productDetail = new HashMap<>();
        productDetail.put("productId", product.getProductId());
        productDetail.put("categoryId", product.getCategoryId());
        productDetail.put("brand", product.getBrand());
        productDetail.put("model", product.getModel());
        productDetail.put("price", product.getPrice());
        productDetail.put("originalPrice", product.getOriginalPrice());
        productDetail.put("stock", product.getStock());
        productDetail.put("minStock", product.getMinStock());
        productDetail.put("productType", product.getProductType());
        productDetail.put("isOnShelf", product.getIsOnShelf());
        productDetail.put("auditStatus", product.getAuditStatus());
        productDetail.put("rejectReason", product.getRejectReason());
        productDetail.put("color", product.getColor());
        productDetail.put("condition", product.getCondition());
        productDetail.put("minRentalDays", product.getMinRentalDays());

        ProductDetail productDetailEntity = productDetailMapper.selectOne(
            new LambdaQueryWrapper<ProductDetail>().eq(ProductDetail::getProductId, productId)
        );
        if (productDetailEntity != null) {
            productDetail.put("description", productDetailEntity.getDescription());
            productDetail.put("usageDuration", productDetailEntity.getUsageDuration());
            productDetail.put("repairHistory", productDetailEntity.getRepairHistory());
            productDetail.put("accessories", productDetailEntity.getAccessories());
        } else {
            productDetail.put("description", "");
            productDetail.put("usageDuration", "");
            productDetail.put("repairHistory", "0");
            productDetail.put("accessories", "");
        }

        return productDetail;
    }

    @Override
    public List<Map<String, Object>> getProductImages(Long productId) {
        List<Map<String, Object>> images = new ArrayList<>();
        // 使用QueryWrapper而不是LambdaQueryWrapper，避免MyBatis-Plus自动添加逻辑删除条件
        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<ProductImage> wrapper = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        wrapper.eq("product_id", productId);
        wrapper.orderByAsc("sort");
        // 手动添加条件，包括is_deleted为0或NULL的情况
        wrapper.and(w -> w.eq("is_deleted", 0).or().isNull("is_deleted"));
        List<ProductImage> productImages = productImageMapper.selectList(wrapper);
        
        // 处理从product_image表获取的图片
        for (ProductImage productImage : productImages) {
            SysImage sysImage = sysImageMapper.selectById(productImage.getImageId());
            if (sysImage == null) {
                continue;
            }
            
            Map<String, Object> imageMap = new HashMap<>();
            imageMap.put("id", productImage.getImageId());
            imageMap.put("imageId", productImage.getImageId());
            imageMap.put("storagePath", sysImage.getStoragePath());
            imageMap.put("imagePath", sysImage.getStoragePath());
            images.add(imageMap);
        }
        
        // 如果没有找到图片，尝试从product_detail表的img_urls字段中获取
        if (images.isEmpty()) {
            ProductDetail productDetail = productDetailMapper.selectOne(new LambdaQueryWrapper<ProductDetail>().eq(ProductDetail::getProductId, productId));
            if (productDetail != null) {
                String imgUrlsJson = productDetail.getImgUrls();
                if (imgUrlsJson != null && !imgUrlsJson.equals("[]")) {
                    try {
                        List<String> imgUrls = objectMapper.readValue(imgUrlsJson, new TypeReference<List<String>>() {});
                        for (int i = 0; i < imgUrls.size(); i++) {
                            String imgUrl = imgUrls.get(i);
                            Map<String, Object> imageMap = new HashMap<>();
                            imageMap.put("id", null);
                            imageMap.put("imageId", null);
                            imageMap.put("storagePath", imgUrl);
                            imageMap.put("imagePath", imgUrl);
                            images.add(imageMap);
                        }
                    } catch (JsonProcessingException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
        
        return images;
    }

    @Override
    public List<Map<String, Object>> getSkuList(Long productId) {
        // 根据商品ID获取SKU列表
        return skuMapper.selectSkuListByProductId(productId);
    }

    @Override
    public boolean addSku(Long productId, Map<String, Object> skuData) {
        try {
            // 创建SKU对象
            Sku sku = new Sku();
            sku.setProductId(productId);
            sku.setSkuAttribute((String) skuData.get("skuAttribute"));
            sku.setSkuValue((String) skuData.get("skuValue"));
            sku.setPrice(new java.math.BigDecimal(skuData.get("price").toString()));
            sku.setStock(Integer.parseInt(skuData.get("stock").toString()));
            sku.setMinStock(skuData.get("minStock") != null ? Integer.parseInt(skuData.get("minStock").toString()) : 10);
            sku.setSales(0);
            sku.setCreateTime(new java.util.Date());
            sku.setUpdateTime(new java.util.Date());

            // 保存SKU
            return skuMapper.insertSku(sku) > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean updateSku(Long productId, Long skuId, Map<String, Object> skuData) {
        try {
            // 获取SKU对象
            Sku sku = skuMapper.selectById(skuId);
            if (sku == null || !sku.getProductId().equals(productId)) {
                return false;
            }

            // 更新SKU信息
            sku.setSkuAttribute((String) skuData.get("skuAttribute"));
            sku.setSkuValue((String) skuData.get("skuValue"));
            sku.setPrice(new java.math.BigDecimal(skuData.get("price").toString()));
            sku.setStock(Integer.parseInt(skuData.get("stock").toString()));
            sku.setMinStock(skuData.get("minStock") != null ? Integer.parseInt(skuData.get("minStock").toString()) : 10);
            sku.setUpdateTime(new java.util.Date());

            // 保存更新
            return skuMapper.updateSku(sku) > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean deleteSku(Long productId, Long skuId) {
        try {
            // 获取SKU对象
            Sku sku = skuMapper.selectById(skuId);
            if (sku == null || !sku.getProductId().equals(productId)) {
                return false;
            }

            // 删除SKU
            return skuMapper.deleteSku(skuId) > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public IPage<Map<String, Object>> getProductListWithBrandName(IPage<Map<String, Object>> page, Map<String, Object> params) {
        // 构建查询条件
        String productName = (String) params.get("productName");
        String brand = (String) params.get("brand");
        String model = (String) params.get("model");
        Integer productType = (Integer) params.get("productType");
        Integer auditStatusInt = (Integer) params.get("auditStatus");
        Byte auditStatus = auditStatusInt != null ? auditStatusInt.byteValue() : 0;
        
        System.out.println("Calling mapper with auditStatus: " + auditStatus);
        // 执行分页查询
        return productMapper.selectProductListWithBrandName(page, productName, brand, model, productType, auditStatus);
    }

}
