package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.dto.CartItemDTO;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.CartService;
import bysj.pets.bec.utils.JwtUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 购物车控制器
 */
@RestController
@RequestMapping("/cart")
public class CartController {

    @Autowired
    private CartService cartService;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserMapper userMapper;

    /**
     * 获取购物车列表
     */
    @GetMapping("/items")
    public Result<List<CartItemDTO>> getCartItems(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader) {
        
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            Result<List<CartItemDTO>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户未登录");
            return result;
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            Result<List<CartItemDTO>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户未登录或令牌已过期");
            return result;
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        Long userId = getUserIdFromUsername(username); 
        if (userId == null) {
            Result<List<CartItemDTO>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户不存在");
            return result;
        }

        List<CartItemDTO> cartItems = cartService.getUserCartItems(userId);
        return Result.success("获取购物车成功", cartItems);
    }

    /**
     * 添加商品到购物车
     */
    @PostMapping("/add")
    public Result<Object> addToCart(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody Map<String, Object> request) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error(401, "用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            return Result.error(401, "用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        Long userId = getUserIdFromUsername(username); 
        if (userId == null) {
            return Result.error(401, "用户不存在");
        }

        Long productId = Long.valueOf(request.get("productId").toString());
        Integer quantity = Integer.valueOf(request.get("quantity").toString());

        boolean success = cartService.addToCart(userId, productId, quantity);
        if (success) {
            return Result.success("添加到购物车成功");
        } else {
            return Result.error("添加到购物车失败");
        }
    }

    /**
     * 更新购物车商品数量
     */
    @PutMapping("/items/{cartItemId}")
    public Result<Object> updateCartItemQuantity(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long cartItemId,
            @RequestBody Map<String, Integer> request) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error(401, "用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            return Result.error(401, "用户未登录或令牌已过期");
        }

        Integer quantity = request.get("quantity");
        boolean success = cartService.updateCartItemQuantity(cartItemId, quantity);
        if (success) {
            return Result.success("更新成功");
        } else {
            return Result.error("更新失败");
        }
    }

    /**
     * 删除购物车商品
     */
    @DeleteMapping("/items/{cartItemId}")
    public Result<Object> removeCartItem(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long cartItemId) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error(401, "用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            return Result.error(401, "用户未登录或令牌已过期");
        }

        boolean success = cartService.removeCartItem(cartItemId);
        if (success) {
            return Result.success("删除成功");
        } else {
            return Result.error("删除失败");
        }
    }

    /**
     * 批量删除购物车商品
     */
    @PostMapping("/batch-delete")
    public Result<Object> batchRemoveCartItems(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody Map<String, List<Long>> request) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error(401, "用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            return Result.error(401, "用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        Long userId = getUserIdFromUsername(username); 
        if (userId == null) {
            return Result.error(401, "用户不存在");
        }

        List<Long> productIds = request.get("productIds");
        boolean success = cartService.batchRemoveCartItems(userId, productIds);
        if (success) {
            return Result.success("批量删除成功");
        } else {
            return Result.error("批量删除失败");
        }
    }

    /**
     * 清空购物车
     */
    @DeleteMapping("/clear")
    public Result<Object> clearCart(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error(401, "用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            return Result.error(401, "用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        Long userId = getUserIdFromUsername(username); 
        if (userId == null) {
            return Result.error(401, "用户不存在");
        }

        boolean success = cartService.clearCart(userId);
        if (success) {
            return Result.success("清空购物车成功");
        } else {
            return Result.error("清空购物车失败");
        }
    }

    /**
     * 批量添加商品到购物车
     */
    @PostMapping("/batch-add")
    public Result<Object> batchAddToCart(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody Map<String, List<Long>> request) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error(401, "用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            return Result.error(401, "用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        Long userId = getUserIdFromUsername(username); 
        if (userId == null) {
            return Result.error(401, "用户不存在");
        }

        List<Long> productIds = request.get("productIds");
        if (productIds == null || productIds.isEmpty()) {
            return Result.error("请选择要添加的商品");
        }

        boolean success = cartService.batchAddToCart(userId, productIds);
        if (success) {
            return Result.success("批量添加到购物车成功");
        } else {
            return Result.error("批量添加到购物车失败");
        }
    }

    /**
     * 根据用户名获取用户ID
     * 这里需要实现根据用户名获取用户ID的逻辑
     */
    private Long getUserIdFromUsername(String username) {
        // 从数据库中查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user != null) {
            return user.getUserId();
        }
        return null;
    }
}
