package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.dto.FavoriteDTO;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.FavoriteService;
import bysj.pets.bec.utils.JwtUtils;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 收藏Controller
 */
@RestController
@RequestMapping("/favorites")

public class FavoriteController {

    @Autowired
    private FavoriteService favoriteService;

    // 添加JwtUtils注入
    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserMapper userMapper;

@PostMapping
// 替换Principal参数为Authorization请求头
public Result<Map<String, Object>> addFavorite(
        @RequestHeader(value = "Authorization", required = false) String tokenHeader,
        @RequestBody Map<String, Long> request) {

    Map<String, Object> resultData = new HashMap<>();
    // 验证JWT令牌（替换原SecurityContext检查）
    if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
        Result<Map<String, Object>> result = new Result<>();
        result.setCode(401);
        result.setMsg("用户未登录");
        return result;
    }
    String token = tokenHeader.substring(7); // 移除"Bearer "前缀
        // 验证token格式和有效性
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户未登录或令牌已过期");
            return result;
        }

    // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        // 根据用户名查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user == null) {
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户不存在");
            return result;
        }
        Long userId = user.getUserId();
        Long productId = request.get("productId");

    boolean success = favoriteService.addFavorite(userId, productId);

    resultData.put("success", success);
    resultData.put("message", success ? "收藏成功" : "该商品已收藏");
    return Result.success("操作成功", resultData);
}


@DeleteMapping("/{favoriteId}")
// 替换Principal参数为Authorization请求头
public Result<Map<String, Object>> removeFavorite(
        @RequestHeader(value = "Authorization", required = false) String tokenHeader,
        @PathVariable Long favoriteId) {

    Map<String, Object> resultData = new HashMap<>();
    // 验证JWT令牌
    if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
        Result<Map<String, Object>> result = new Result<>();
        result.setCode(401);
        result.setMsg("用户未登录");
        return result;
    }
    String token = tokenHeader.substring(7);
        // 验证token格式和有效性
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户未登录或令牌已过期");
            return result;
        }

    // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        // 根据用户名查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user == null) {
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户不存在");
            return result;
        }
        Long userId = user.getUserId();

    boolean success = favoriteService.removeFavorite(userId, favoriteId);

    resultData.put("success", success);
    resultData.put("message", success ? "取消收藏成功" : "操作失败");
    return Result.success("操作成功", resultData);
}


    @DeleteMapping
    public ResponseEntity<Map<String, Object>> removeFavoriteByProductId(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestParam Long productId) {

        Map<String, Object> result = new HashMap<>();
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            result.put("success", false);
            result.put("message", "用户未登录");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        String token = tokenHeader.substring(7);
        // 验证token格式和有效性
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            result.put("success", false);
            result.put("message", "用户未登录或令牌已过期");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        // 根据用户名查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user == null) {
            result.put("success", false);
            result.put("message", "用户不存在");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        Long userId = user.getUserId();

        // 调用服务层，根据productId取消收藏
        boolean success = favoriteService.removeFavoriteByProductId(userId, productId);

        result.put("success", success);
        result.put("message", success ? "取消收藏成功" : "操作失败");
        return ResponseEntity.ok(result);
    }


    @PostMapping("/batch-delete")
    // 替换Principal参数为Authorization请求头
    public ResponseEntity<Map<String, Object>> batchRemoveFavorites(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody Map<String, List<Long>> request) {

        Map<String, Object> result = new HashMap<>();
        // 验证JWT令牌（替换原SecurityContext检查）
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            result.put("success", false);
            result.put("message", "用户未登录");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        String token = tokenHeader.substring(7); // 移除"Bearer "前缀
        // 验证token格式和有效性
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            result.put("success", false);
            result.put("message", "用户未登录或令牌已过期");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        // 根据用户名查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user == null) {
            result.put("success", false);
            result.put("message", "用户不存在");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        Long userId = user.getUserId();
        List<Long> favoriteIds = request.get("favoriteIds");

        if (favoriteIds == null || favoriteIds.isEmpty()) {
            result.put("success", false);
            result.put("message", "请选择要取消收藏的商品");
            return ResponseEntity.ok(result);
        }

        boolean success = favoriteService.batchRemoveFavorites(userId, favoriteIds);

        result.put("success", success);
        result.put("message", success ? "批量取消收藏成功" : "操作失败");
        return ResponseEntity.ok(result);
    }


    @GetMapping("/check")
    // 替换Principal参数为Authorization请求头
    public ResponseEntity<Map<String, Object>> checkIsFavorite(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestParam Long productId) {

        Map<String, Object> result = new HashMap<>();
        // 验证JWT令牌（替换原SecurityContext检查）
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            result.put("success", false);
            result.put("message", "用户未登录");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        String token = tokenHeader.substring(7); // 移除"Bearer "前缀
        // 验证token格式和有效性
        if (token == null || token.isEmpty() || !jwtUtils.validateToken(token)) {
            result.put("success", false);
            result.put("message", "用户未登录或令牌已过期");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        // 根据用户名查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user == null) {
            result.put("success", false);
            result.put("message", "用户不存在");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        Long userId = user.getUserId();
        boolean isFavorite = favoriteService.checkIsFavorite(userId, productId);
        result.put("isFavorited", isFavorite);
        return ResponseEntity.ok(result);
    }


    @GetMapping
    // 保持现有JWT认证实现
    public Result<Map<String, Object>> getUserFavorites(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "12") int size) {

        Map<String, Object> resultData = new HashMap<>();
        // 验证JWT令牌
        System.out.println("=== 收藏列表请求开始 ===");
        System.out.println("Received tokenHeader: " + tokenHeader);
        
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            System.out.println("Token header is null or not Bearer type");
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户未登录");
            return result;
        }
        String token = tokenHeader.substring(7);
        System.out.println("Extracted token: " + token);
        
        // 添加详细的token验证日志
        boolean tokenValid = jwtUtils.validateToken(token);
        System.out.println("Token validation result: " + tokenValid);
        
        if (!tokenValid) {
            System.out.println("Token validation failed");
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户未登录或令牌已过期");
            return result;
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        System.out.println("Extracted username: " + username);
        
        if (username == null) {
            System.out.println("Failed to extract username from token");
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("令牌无效，无法提取用户名");
            return result;
        }
        
        // 根据用户名查询用户ID
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        System.out.println("User found: " + (user != null ? user.getUserId() : "null"));
        
        if (user == null) {
            System.out.println("User not found for username: " + username);
            Result<Map<String, Object>> result = new Result<>();
            result.setCode(401);
            result.setMsg("用户不存在");
            return result;
        }
        Long userId = user.getUserId();
        System.out.println("User ID: " + userId);

        IPage<FavoriteDTO> favorites = favoriteService.getUserFavorites(userId, page, size);
        System.out.println("Favorites found: " + favorites.getTotal());
        System.out.println("=== 收藏列表请求结束 ===");

        resultData.put("list", favorites.getRecords());
        resultData.put("total", favorites.getTotal());
        resultData.put("pages", favorites.getPages());
        resultData.put("current", favorites.getCurrent());
        resultData.put("size", favorites.getSize());

        return Result.success("获取收藏列表成功", resultData);
    }

}
