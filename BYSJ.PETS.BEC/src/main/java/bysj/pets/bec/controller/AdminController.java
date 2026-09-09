package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.entity.ProductCategory;
import bysj.pets.bec.entity.ProductDetail;
import bysj.pets.bec.entity.SysNotice;
import bysj.pets.bec.entity.ProductImage;
import bysj.pets.bec.entity.SysImage;
import bysj.pets.bec.entity.SysLog;
import bysj.pets.bec.service.AdminService;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.mapper.ProductMapper;
import bysj.pets.bec.mapper.ProductCategoryMapper;
import bysj.pets.bec.mapper.ProductDetailMapper;
import bysj.pets.bec.mapper.SysNoticeMapper;
import bysj.pets.bec.mapper.ProductImageMapper;
import bysj.pets.bec.mapper.SysImageMapper;
import bysj.pets.bec.mapper.SysLogMapper;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.stream.Collectors;
import bysj.pets.bec.utils.LogUtils;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private ProductCategoryMapper productCategoryMapper;

    @Autowired
    private SysNoticeMapper sysNoticeMapper;

    @Autowired
    private ProductDetailMapper productDetailMapper;

    @Autowired
    private ProductImageMapper productImageMapper;

    @Autowired
    private SysImageMapper sysImageMapper;

    @Autowired
    private SysLogMapper sysLogMapper;

    @Autowired
    private LogUtils logUtils;

    /**
     * 从请求中获取当前用户ID
     * @param request HTTP请求对象
     * @return 用户ID
     */
    private Long getCurrentUserId(HttpServletRequest request) {
        // 实际项目中应该从JWT token中解析用户ID
        // 这里简化处理，返回固定值
        return 1L; // 假设当前用户ID为1
    }

    /**
     * 获取管理员仪表盘数据
     * @return 仪表盘数据
     */
    @GetMapping("/dashboard")
    public Result<Map<String, Object>> getAdminDashboardData() {
        return adminService.getAdminDashboardData();
    }

    /**
     * 获取超级管理员仪表盘数据
     * @return 仪表盘数据
     */
    @GetMapping("/super-admin/dashboard")
    public Result<Map<String, Object>> getSuperAdminDashboardData() {
        return adminService.getSuperAdminDashboardData();
    }

    /**
     * 获取用户列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @param status 状态
     * @return 用户列表
     */
    @GetMapping("/users")
    public Result getUserList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        QueryWrapper<User> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", 1); // 只查询普通用户
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like("username", keyword).or().like("nickname", keyword).or().like("phone", keyword);
        }
        
        if (status != null) {
            queryWrapper.eq("status", status);
        }
        
        Page<User> userPage = userMapper.selectPage(new Page<>(pageNum, pageSize), queryWrapper);
        return Result.success(userPage);
    }

    /**
     * 获取用户详情
     * @param userId 用户ID
     * @return 用户详情
     */
    @GetMapping("/users/{userId}")
    public Result getUserDetail(@PathVariable Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }
        return Result.success(user);
    }

    /**
     * 更新用户状态
     * @param userId 用户ID
     * @param requestBody 状态数据
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/users/{userId}/status")
    public Result updateUserStatus(@PathVariable Long userId, @RequestBody Map<String, Integer> requestBody, HttpServletRequest httpRequest) {
        Integer status = requestBody.get("status");
        if (status == null) {
            return Result.error("状态不能为空");
        }
        
        User user = userMapper.selectById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }
        
        user.setStatus(status.byteValue());
        userMapper.updateById(user);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "更新用户状态", "用户管理");
        
        return Result.success("状态更新成功");
    }

    /**
     * 删除用户
     * @param userId 用户ID
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @DeleteMapping("/users/{userId}")
    public Result deleteUser(@PathVariable Long userId, HttpServletRequest httpRequest) {
        int result = userMapper.deleteById(userId);
        if (result == 0) {
            return Result.error("用户不存在");
        }
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "删除用户", "用户管理");
        
        return Result.success("删除成功");
    }

    /**
     * 更新用户信息
     * @param userId 用户ID
     * @param user 用户信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/users/{userId}")
    public Result updateUser(@PathVariable Long userId, @RequestBody User user, HttpServletRequest httpRequest) {
        User existingUser = userMapper.selectById(userId);
        if (existingUser == null) {
            return Result.error("用户不存在");
        }
        
        // 更新用户信息
        existingUser.setUsername(user.getUsername());
        existingUser.setNickname(user.getNickname());
        existingUser.setPhone(user.getPhone());
        existingUser.setEmail(user.getEmail());
        existingUser.setStatus(user.getStatus());
        
        userMapper.updateById(existingUser);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "更新用户信息", "用户管理");
        
        return Result.success("更新成功");
    }

    // 商家管理
    /**
     * 获取商家列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @param status 状态
     * @return 商家列表
     */
    @GetMapping("/merchants")
    public Result getMerchantList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        QueryWrapper<User> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", 2); // 商家用户
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like("username", keyword).or().like("shop_name", keyword);
        }
        
        if (status != null) {
            queryWrapper.eq("shop_status", status);
        }
        
        Page<User> merchantPage = userMapper.selectPage(new Page<>(pageNum, pageSize), queryWrapper);
        return Result.success(merchantPage);
    }

    /**
     * 获取商家审核列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @return 商家审核列表
     */
    @GetMapping("/merchants/audit")
    public Result getMerchantAuditList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword) {
        QueryWrapper<User> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", 2) // 商家用户
                .eq("shop_status", 2); // 审核中
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like("username", keyword).or().like("shop_name", keyword);
        }
        
        Page<User> merchantPage = userMapper.selectPage(new Page<>(pageNum, pageSize), queryWrapper);
        return Result.success(merchantPage);
    }

    /**
     * 审核商家
     * @param merchantId 商家ID
     * @param request 审核信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/merchants/{merchantId}/audit")
    public Result auditMerchant(@PathVariable Long merchantId, @RequestBody Map<String, Object> request, HttpServletRequest httpRequest) {
        Integer auditStatus = (Integer) request.get("auditStatus");
        if (auditStatus == null) {
            return Result.error("审核状态不能为空");
        }
        
        User user = userMapper.selectById(merchantId);
        if (user == null) {
            return Result.error("商家不存在");
        }
        
        // 修正状态设置：通过为1，驳回为0
        int finalStatus = auditStatus == 1 ? 1 : 0;
        user.setShopStatus(finalStatus);
        userMapper.updateById(user);
        
        // 发送消息给商家
        String rejectReason = (String) request.get("rejectReason");
        SysNotice notice = new SysNotice();
        notice.setUserId(merchantId);
        notice.setCreateTime(java.time.LocalDateTime.now());
        notice.setIsRead((byte) 0); // 未读
        notice.setNoticeStatus((byte) 0); // 正常状态
        notice.setNoticeType((byte) 1); // 系统通知
        
        if (auditStatus == 1) {
            notice.setContent("您的店铺审核已通过，现在可以正常营业");
        } else {
            notice.setContent("您的店铺审核已驳回，原因：" + (rejectReason != null ? rejectReason : "审核未通过"));
        }
        
        sysNoticeMapper.insert(notice);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        String operation = auditStatus == 1 ? "商家审核通过" : "商家审核驳回";
        logUtils.recordOperationLog(currentUserId, operation, "商家管理");
        
        return Result.success("审核成功");
    }

    /**
     * 获取商家详情
     * @param merchantId 商家ID
     * @return 商家详情
     */
    @GetMapping("/merchants/{merchantId}")
    public Result getMerchantDetail(@PathVariable Long merchantId) {
        User user = userMapper.selectById(merchantId);
        if (user == null) {
            return Result.error("商家不存在");
        }
        return Result.success(user);
    }

    /**
     * 禁用商家
     * @param merchantId 商家ID
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/merchants/{merchantId}/disable")
    public Result disableMerchant(@PathVariable Long merchantId, HttpServletRequest httpRequest) {
        User user = userMapper.selectById(merchantId);
        if (user == null) {
            return Result.error("商家不存在");
        }
        
        user.setShopStatus(0); // 禁用
        userMapper.updateById(user);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "禁用商家", "商家管理");
        
        return Result.success("禁用成功");
    }
    
    /**
     * 更新商家状态
     * @param merchantId 商家ID
     * @param status 状态
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/merchants/{merchantId}/status")
    public Result updateMerchantStatus(@PathVariable Long merchantId, @RequestParam Integer status, HttpServletRequest httpRequest) {
        User user = userMapper.selectById(merchantId);
        if (user == null) {
            return Result.error("商家不存在");
        }
        
        user.setShopStatus(status);
        userMapper.updateById(user);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        String operation = status == 1 ? "启用商家" : "禁用商家";
        logUtils.recordOperationLog(currentUserId, operation, "商家管理");
        
        return Result.success("状态更新成功");
    }

    // 商品管理
    /**
     * 获取商品列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @param status 状态
     * @param productType 商品类型
     * @return 商品列表
     */
    @GetMapping("/products")
    public Result getProductList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer productType) {
        QueryWrapper<Product> queryWrapper = new QueryWrapper<>();
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like("model", keyword);
        }
        
        if (status != null) {
            queryWrapper.eq("audit_status", status);
        }
        
        if (productType != null) {
            queryWrapper.eq("product_type", productType);
        }
        
        Page<Product> productPage = productMapper.selectPage(new Page<>(pageNum, pageSize), queryWrapper);
        return Result.success(productPage);
    }

    /**
     * 获取商品审核列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @param auditStatus 审核状态
     * @param productType 商品类型
     * @param productName 商品名称
     * @param brand 品牌
     * @param model 型号
     * @return 商品审核列表
     */
    @GetMapping("/products/audit")
    public Result getProductAuditList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer auditStatus,
            @RequestParam(required = false) Integer productType,
            @RequestParam(required = false) String productName,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) String model) {
        // 使用ProductMapper中的selectProductListWithBrandName方法获取带品牌名称的商品列表
        Page<Map<String, Object>> page = new Page<>(pageNum, pageSize);
        IPage<Map<String, Object>> productPage = productMapper.selectProductListWithBrandName(
                page,
                productName,
                brand,
                model,
                productType,
                auditStatus != null ? auditStatus.byteValue() : 0
        );
        return Result.success(productPage);
    }

    /**
     * 审核商品
     * @param productId 商品ID
     * @param request 审核信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/products/{productId}/audit")
    public Result auditProduct(@PathVariable Long productId, @RequestBody Map<String, Object> request, HttpServletRequest httpRequest) {
        Integer auditStatus = (Integer) request.get("auditStatus");
        if (auditStatus == null) {
            return Result.error("审核状态不能为空");
        }
        
        Product product = productMapper.selectById(productId);
        if (product == null) {
            return Result.error("商品不存在");
        }
        
        product.setAuditStatus(auditStatus.byteValue());
        
        // 审核通过时自动上架
        if (auditStatus == 1) {
            product.setIsOnShelf((byte) 1);
        }
        
        productMapper.updateById(product);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        String operation = auditStatus == 1 ? "商品审核通过并上架" : "商品审核驳回";
        logUtils.recordOperationLog(currentUserId, operation, "商品管理");
        
        return Result.success("审核成功");
    }

    /**
     * 获取商品详情
     * @param productId 商品ID
     * @return 商品详情
     */
    @GetMapping("/products/{productId}")
    public Result getProductDetail(@PathVariable Long productId) {
        Product product = productMapper.selectById(productId);
        if (product == null) {
            return Result.error("商品不存在");
        }
        
        // 查询商品图片
        QueryWrapper<ProductImage> productImageQueryWrapper = new QueryWrapper<>();
        productImageQueryWrapper.eq("product_id", productId).eq("is_deleted", 0);
        List<ProductImage> productImages = productImageMapper.selectList(productImageQueryWrapper);
        
        List<String> images = new java.util.ArrayList<>();
        if (!productImages.isEmpty()) {
            // 提取图片ID列表
            List<Long> imageIds = productImages.stream()
                    .map(ProductImage::getImageId)
                    .collect(Collectors.toList());
            
            // 查询图片详情
            if (!imageIds.isEmpty()) {
                QueryWrapper<SysImage> sysImageQueryWrapper = new QueryWrapper<>();
                sysImageQueryWrapper.in("id", imageIds).eq("is_deleted", 0);
                List<SysImage> sysImages = sysImageMapper.selectList(sysImageQueryWrapper);
                
                // 提取存储路径
                images = sysImages.stream()
                        .map(SysImage::getStoragePath)
                        .collect(Collectors.toList());
            }
        }
        
        product.setImages(images);
        
        return Result.success(product);
    }

    /**
     * 删除商品
     * @param productId 商品ID
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @DeleteMapping("/products/{productId}")
    public Result deleteProduct(@PathVariable Long productId, HttpServletRequest httpRequest) {
        int result = productMapper.deleteById(productId);
        if (result == 0) {
            return Result.error("商品不存在");
        }
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "删除商品", "商品管理");
        
        return Result.success("删除成功");
    }
    
    /**
     * 商品上架/下架
     * @param productId 商品ID
     * @param request 状态数据
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/products/{productId}/shelf")
    public Result toggleProductShelf(@PathVariable Long productId, @RequestBody Map<String, Object> request, HttpServletRequest httpRequest) {
        Byte isOnShelf = Byte.parseByte(request.get("isOnShelf").toString());
        
        Product product = productMapper.selectById(productId);
        if (product == null) {
            return Result.error("商品不存在");
        }
        
        product.setIsOnShelf(isOnShelf);
        productMapper.updateById(product);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        String operation = isOnShelf == 1 ? "商品上架" : "商品下架";
        logUtils.recordOperationLog(currentUserId, operation, "商品管理");
        
        return Result.success("操作成功");
    }

    // 分类管理
    /**
     * 获取分类树
     * @return 分类树
     */
    @GetMapping("/categories/tree")
    public Result getCategoryTree() {
        List<ProductCategory> categories = productCategoryMapper.selectList(null);
        // 构建分类树结构
        List<ProductCategory> rootCategories = new java.util.ArrayList<>();
        for (ProductCategory category : categories) {
            if (category.getParentId() == null) {
                rootCategories.add(category);
            }
        }
        
        // 递归构建子分类
        for (ProductCategory root : rootCategories) {
            buildCategoryTree(root, categories);
        }
        
        return Result.success(rootCategories);
    }
    
    private void buildCategoryTree(ProductCategory parent, List<ProductCategory> allCategories) {
        List<ProductCategory> children = new java.util.ArrayList<>();
        for (ProductCategory category : allCategories) {
            if (category.getParentId() != null && category.getParentId().equals(parent.getCategoryId())) {
                children.add(category);
                buildCategoryTree(category, allCategories);
            }
        }
        parent.setChildren(children);
    }

    /**
     * 添加分类
     * @param category 分类信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PostMapping("/categories")
    public Result addCategory(@RequestBody ProductCategory category, HttpServletRequest httpRequest) {
        productCategoryMapper.insert(category);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "添加分类", "分类管理");
        
        return Result.success("添加成功");
    }

    /**
     * 更新分类
     * @param categoryId 分类ID
     * @param category 分类信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/categories/{categoryId}")
    public Result updateCategory(@PathVariable Integer categoryId, @RequestBody ProductCategory category, HttpServletRequest httpRequest) {
        category.setCategoryId(categoryId);
        productCategoryMapper.updateById(category);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "更新分类", "分类管理");
        
        return Result.success("更新成功");
    }

    /**
     * 删除分类
     * @param categoryId 分类ID
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @DeleteMapping("/categories/{categoryId}")
    public Result deleteCategory(@PathVariable Integer categoryId, HttpServletRequest httpRequest) {
        // 检查是否有子分类
        QueryWrapper<ProductCategory> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("parent_id", categoryId);
        long count = productCategoryMapper.selectCount(queryWrapper);
        if (count > 0) {
            return Result.error("该分类下有子分类，无法删除");
        }
        
        int result = productCategoryMapper.deleteById(categoryId);
        if (result == 0) {
            return Result.error("分类不存在");
        }
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "删除分类", "分类管理");
        
        return Result.success("删除成功");
    }

    // 公告管理
    /**
     * 获取公告列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @return 公告列表
     */
    @GetMapping("/notices")
    public Result getNoticeList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword) {
        QueryWrapper<SysNotice> queryWrapper = new QueryWrapper<>();
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like("content", keyword);
        }
        
        Page<SysNotice> noticePage = sysNoticeMapper.selectPage(new Page<>(pageNum, pageSize), queryWrapper);
        return Result.success(noticePage);
    }

    /**
     * 获取公告详情
     * @param noticeId 公告ID
     * @return 公告详情
     */
    @GetMapping("/notices/{noticeId}")
    public Result getNoticeDetail(@PathVariable Long noticeId) {
        SysNotice notice = sysNoticeMapper.selectById(noticeId);
        if (notice == null) {
            return Result.error("公告不存在");
        }
        return Result.success(notice);
    }

    /**
     * 添加公告
     * @param notice 公告信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PostMapping("/notices")
    public Result addNotice(@RequestBody SysNotice notice, HttpServletRequest httpRequest) {
        notice.setCreateTime(java.time.LocalDateTime.now());
        notice.setIsRead((byte) 0); // 未读
        notice.setNoticeStatus((byte) 0); // 未发布
        sysNoticeMapper.insert(notice);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "添加公告", "公告管理");
        
        return Result.success("添加成功");
    }

    /**
     * 更新公告
     * @param noticeId 公告ID
     * @param notice 公告信息
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/notices/{noticeId}")
    public Result updateNotice(@PathVariable Long noticeId, @RequestBody SysNotice notice, HttpServletRequest httpRequest) {
        notice.setNoticeId(noticeId);
        sysNoticeMapper.updateById(notice);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "更新公告", "公告管理");
        
        return Result.success("更新成功");
    }

    /**
     * 删除公告
     * @param noticeId 公告ID
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @DeleteMapping("/notices/{noticeId}")
    public Result deleteNotice(@PathVariable Long noticeId, HttpServletRequest httpRequest) {
        int result = sysNoticeMapper.deleteById(noticeId);
        if (result == 0) {
            return Result.error("公告不存在");
        }
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "删除公告", "公告管理");
        
        return Result.success("删除成功");
    }

    /**
     * 发布公告
     * @param noticeId 公告ID
     * @param httpRequest HTTP请求对象
     * @return 操作结果
     */
    @PutMapping("/notices/{noticeId}/publish")
    public Result publishNotice(@PathVariable Long noticeId, HttpServletRequest httpRequest) {
        SysNotice notice = sysNoticeMapper.selectById(noticeId);
        if (notice == null) {
            return Result.error("公告不存在");
        }
        
        notice.setNoticeStatus((byte) 1); // 已发布
        sysNoticeMapper.updateById(notice);
        
        // 记录操作日志
        Long currentUserId = getCurrentUserId(httpRequest);
        logUtils.recordOperationLog(currentUserId, "发布公告", "公告管理");
        
        return Result.success("发布成功");
    }

    /**
     * 获取操作记录列表
     * @param pageNum 页码
     * @param pageSize 每页数量
     * @param keyword 关键词
     * @return 操作记录列表
     */
    @GetMapping("/operations")
    public Result getOperationList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String keyword) {
        QueryWrapper<SysLog> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("log_type", 1); // 1-操作日志
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like("operation", keyword).or().like("module", keyword);
        }
        
        queryWrapper.orderByDesc("create_time");
        
        Page<SysLog> logPage = sysLogMapper.selectPage(new Page<>(pageNum, pageSize), queryWrapper);
        
        // 转换为前端需要的格式
        List<Map<String, Object>> operations = new ArrayList<>();
        for (SysLog log : logPage.getRecords()) {
            Map<String, Object> operation = new HashMap<>();
            User user = userMapper.selectById(log.getUserId());
            operation.put("operator", user != null ? user.getUsername() : "系统");
            operation.put("operation", log.getOperation());
            operation.put("target", log.getModule());
            operation.put("result", "成功");
            operation.put("operationTime", log.getCreateTime());
            operations.add(operation);
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("records", operations);
        result.put("total", logPage.getTotal());
        result.put("pageNum", pageNum);
        result.put("pageSize", pageSize);
        
        return Result.success(result);
    }
}
