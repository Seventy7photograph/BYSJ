package bysj.pets.bec.config;

import bysj.pets.bec.entity.Permission;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.PermissionMapper;
import bysj.pets.bec.mapper.RoleMapper;
import bysj.pets.bec.mapper.UserMapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import jakarta.annotation.Resource;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 动态权限过滤器，根据数据库中的权限规则进行权限控制
 */
@Component
public class DynamicPermissionFilter extends OncePerRequestFilter {

    @Resource
    private PermissionMapper permissionMapper;

    @Resource
    private RoleMapper roleMapper;

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    @Resource
    private UserMapper userMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        // 跳过公开接口
        String requestUri = request.getRequestURI();
        if (requestUri.startsWith("/auth/") || requestUri.startsWith("/public/") || requestUri.startsWith("/image/") || 
            requestUri.equals("/captcha") || requestUri.equals("/login") || requestUri.equals("/register") ||
            requestUri.startsWith("/shop/") || requestUri.startsWith("/api/auth/") || requestUri.startsWith("/api/public/") ||
            requestUri.startsWith("/evaluations/product/") || requestUri.startsWith("/api/evaluations/product/")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 获取当前认证用户
        UsernamePasswordAuthenticationToken authentication = 
            (UsernamePasswordAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            // 检查用户是否有访问该接口的权限
            checkPermission(request, authentication);
            filterChain.doFilter(request, response);
        } catch (AccessDeniedException e) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json");
            response.getWriter().write("{\"code\":403,\"msg\":\"权限不足\"}");
        }
    }

    /**
     * 检查用户是否有访问权限
     */
    private void checkPermission(HttpServletRequest request, UsernamePasswordAuthenticationToken authentication) {
        String requestMethod = request.getMethod();
        String requestUri = request.getRequestURI();
        
        // 移除/api前缀（如果存在）
        if (requestUri.startsWith("/api")) {
            requestUri = requestUri.substring(4);
        }
        
        // 获取当前登录用户信息
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        
        if (user == null) {
            throw new AccessDeniedException("用户不存在");
        }
        
        // 允许所有登录用户访问用户信息相关接口
        if (requestUri.startsWith("/user/profile") || requestUri.startsWith("/user/info")) {
            return;
        }
        
        // 超级管理员可以访问所有接口
        if (user.getUserType() == bysj.pets.bec.entity.enumtype.UserType.SUPER_ADMIN.getCode()) {
            return;
        }
        
        // 普通管理员可以访问 /admin/** 接口
        if (user.getUserType() == bysj.pets.bec.entity.enumtype.UserType.ADMIN.getCode()) {
            if (requestUri.startsWith("/admin")) {
                return;
            }
            throw new AccessDeniedException("权限不足");
        }
        
        // 商家用户可以访问 /merchant/**、/orders/**、/message/** 和 /refunds/** 接口
        if (user.getUserType() == bysj.pets.bec.entity.enumtype.UserType.MERCHANT.getCode()) {
            if (requestUri.startsWith("/merchant") || requestUri.startsWith("/orders") || 
                requestUri.startsWith("/message") || requestUri.startsWith("/refunds")) {
                return;
            }
            throw new AccessDeniedException("权限不足");
        }
        
        // 普通用户可以访问 /user/**、/favorites/**、/cart/**、/orders/**、/message/**、/evaluations/** 和 /refunds/** 接口
        if (user.getUserType() == bysj.pets.bec.entity.enumtype.UserType.NORMAL.getCode()) {
            if (requestUri.startsWith("/user") || requestUri.startsWith("/favorites") || 
                requestUri.startsWith("/cart") || requestUri.startsWith("/orders") || 
                requestUri.startsWith("/message") || requestUri.startsWith("/evaluations") || 
                requestUri.startsWith("/refunds")) {
                return;
            }
            throw new AccessDeniedException("权限不足");
        }
        
        // 其他情况，默认拒绝访问
        throw new AccessDeniedException("权限不足");
    }

    /**
     * URL匹配，支持通配符
     */
    private boolean matchUrl(String requestUri, String permissionUrl) {
        // 简单的通配符匹配，将**替换为.*进行正则匹配
        String pattern = permissionUrl.replace("**", ".*");
        Pattern regexPattern = Pattern.compile("^" + pattern + "$");
        Matcher matcher = regexPattern.matcher(requestUri);
        return matcher.matches();
    }

    /**
     * 方法匹配，支持*匹配所有方法
     */
    private boolean matchMethod(String requestMethod, String permissionMethod) {
        return "*".equals(permissionMethod) || requestMethod.equalsIgnoreCase(permissionMethod);
    }
}