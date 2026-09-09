package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.entity.vo.InventoryHistoryVO;
import bysj.pets.bec.entity.vo.InventoryItemVO;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.InventoryService;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 库存管理控制器
 */
@RestController
@RequestMapping("/merchant/inventory")
public class InventoryController {
    
    @Autowired
    private InventoryService inventoryService;
    
    @Autowired
    private UserMapper userMapper;
    
    /**
     * 获取库存列表
     */
    @GetMapping
    public Result<Map<String, Object>> getInventoryList(
            @RequestParam(required = false) String productType,
            @RequestParam(required = false) String stockStatus,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        
        // 获取当前登录用户信息
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user;
        
        // 处理匿名用户情况
        if (principal == null || "anonymousUser".equals(principal)) {
            // 对于测试环境，使用已知的商家用户
            user = new User();
            user.setUserId(8L); // 商家用户ID，根据实际数据调整
        } else {
            // 正常登录用户
            UserDetails userDetails = (UserDetails) principal;
            String username = userDetails.getUsername();
            user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
            
            // 如果用户不存在，使用默认商家用户
            if (user == null) {
                user = new User();
                user.setUserId(8L);
            }
        }
        
        Map<String, Object> params = new HashMap<>();
        params.put("productType", productType);
        params.put("stockStatus", stockStatus);
        params.put("keyword", keyword);
        params.put("pageNum", page);
        params.put("pageSize", pageSize);
        params.put("sellerId", user.getUserId()); // 添加卖家ID
        
        IPage<InventoryItemVO> inventoryPage = inventoryService.getInventoryList(params);
        
        Map<String, Object> result = new HashMap<>();
        result.put("list", inventoryPage.getRecords());
        result.put("total", inventoryPage.getTotal());
        result.put("page", inventoryPage.getCurrent());
        result.put("pageSize", inventoryPage.getSize());
        
        return Result.success("获取库存列表成功", result);
    }
    
    /**
     * 获取库存详情
     */
    @GetMapping("/{inventoryId}")
    public Result<InventoryItemVO> getInventoryDetail(@PathVariable Long inventoryId) {
        InventoryItemVO inventoryDetail = inventoryService.getInventoryDetail(inventoryId);
        if (inventoryDetail == null) {
            return Result.error("库存不存在");
        }
        return Result.success("获取库存详情成功", inventoryDetail);
    }
    
    /**
     * 调整库存
     */
    @PostMapping("/adjust")
    public Result<Object> adjustInventory(@RequestBody Map<String, Object> request) {
        try {
            Long inventoryId = Long.parseLong(request.get("inventoryId").toString());
            String adjustType = (String) request.get("adjustType");
            Integer adjustQuantity = Integer.parseInt(request.get("adjustQuantity").toString());
            String reason = (String) request.get("reason");
            Integer minStock = null;
            if (request.get("minStock") != null) {
                // 处理数字类型，可能是Number或String
                Object minStockObj = request.get("minStock");
                if (minStockObj instanceof Number) {
                    minStock = ((Number) minStockObj).intValue();
                } else {
                    minStock = Integer.parseInt(minStockObj.toString());
                }
            }
            
            boolean success = inventoryService.adjustInventory(inventoryId, adjustType, adjustQuantity, reason, minStock);
            if (success) {
                return Result.success("库存调整成功");
            } else {
                return Result.error("库存调整失败");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("库存调整失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取库存变更历史
     */
    @GetMapping("/history")
    public Result<Map<String, Object>> getInventoryHistory(
            @RequestParam Long inventoryId,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        
        IPage<InventoryHistoryVO> historyPage = inventoryService.getInventoryHistory(inventoryId, page, pageSize);
        
        Map<String, Object> result = new HashMap<>();
        result.put("list", historyPage.getRecords());
        result.put("total", historyPage.getTotal());
        result.put("page", historyPage.getCurrent());
        result.put("pageSize", historyPage.getSize());
        
        return Result.success("获取库存变更历史成功", result);
    }
    
    /**
     * 设置安全库存
     */
    @PutMapping("/{inventoryId}/min-stock")
    public Result<Object> setMinStock(
            @PathVariable Long inventoryId,
            @RequestBody Map<String, Object> request) {
        Integer minStock = Integer.parseInt(request.get("minStock").toString());
        
        boolean success = inventoryService.setMinStock(inventoryId, minStock);
        if (success) {
            return Result.success("设置安全库存成功");
        } else {
            return Result.error("设置安全库存失败");
        }
    }
    
    /**
     * 批量导入库存（暂时不实现）
     */
    @PostMapping("/import")
    public Result<Object> batchImportInventory() {
        return Result.success("批量导入库存功能暂未实现");
    }
}