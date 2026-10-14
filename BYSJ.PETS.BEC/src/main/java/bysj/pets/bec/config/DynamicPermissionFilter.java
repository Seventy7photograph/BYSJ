package bysj.pets.bec.config;

import bysj.pets.bec.entity.Permission;
import bysj.pets.bec.entity.Role;
import bysj.pets.bec.entity.RolePermission;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.PermissionMapper;
import bysj.pets.bec.mapper.RolePermissionMapper;
import bysj.pets.bec.mapper.RoleMapper;
import bysj.pets.bec.mapper.UserMapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import jakarta.annotation.Resource;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 动态权限过滤器。
 *
 * 重构前这个类只按 user.user_type 做粗粒度白名单判断，permission 与
 * role_permission 两张表从头到尾没被读过一次，matchUrl/matchMethod 是死代码
 * —— 也就是说「动态权限分配」页面上勾了什么，对接口鉴权完全没有影响。
 *
 * 现在：user_type → role → role_permission → permission(url, method)，
 * 请求必须命中该角色被授予的接口模式之一。没有配置任何权限的角色回退到
 * user_type 白名单，避免刚部署就把既有角色全部锁死。
 */
@Slf4j
@Component
public class DynamicPermissionFilter extends OncePerRequestFilter {

    @Resource
    private PermissionMapper permissionMapper;

    @Resource
    private RolePermissionMapper rolePermissionMapper;

    @Resource
    private RoleMapper roleMapper;

    /** 角色权限模式的短时缓存，避免每个请求都连打三张表。 */
    private static final long PERMISSION_CACHE_TTL_MS = 60_000L;
    private final Map<Byte, CachedPatterns> permissionCache = new ConcurrentHashMap<>();

    private record CachedPatterns(List<Pattern> patterns, List<String> methods, long expiresAt) {}

    /**
     * 权限或角色配置发生变化时调用，立即丢弃缓存。
     * 否则管理员刚在「动态权限分配」里改完授权，接口侧最多还要按旧规则放行 60 秒。
     */
    public void evictCache() {
        permissionCache.clear();
        log.info("角色权限缓存已清空");
    }

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
            requestUri.startsWith("/uploads/") ||
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

        // 上传与图库接口对所有已登录角色开放，具体归属由业务侧校验
        if (requestUri.startsWith("/files")) {
            return;
        }
        
        // 超级管理员可以访问所有接口
        if (user.getUserType() == bysj.pets.bec.entity.enumtype.UserType.SUPER_ADMIN.getCode()) {
            return;
        }
        
        // 优先按角色被授予的权限项判断（即「动态权限分配」页面配置的内容）
        CachedPatterns granted = loadGrantedPatterns(user.getUserType());
        if (granted == null) {
            // 权限数据读不出来（数据库/Redis 异常），宁可拒绝也不要默认放行
            throw new AccessDeniedException("权限校验暂不可用，请稍后重试");
        }

        // 角色没有配置任何权限项：直接拒绝。
        //
        // 这里以前会回退到"按 user_type 判前缀"的粗粒度白名单，而那个白名单分不清
        // 同一个前缀下的不同角色动作 —— 例如 /orders/{id}/ship 是商家发货，
        // 却因为前缀是 /orders 而对买家放行，买家可以把自己的订单标记成已发货。
        // 现在所有内置角色都在 permission/role_permission 里有明确授权，
        // 因此这里必须是 fail-closed：没有授权就是没有权限。
        if (granted.patterns().isEmpty()) {
            log.warn("角色 user_type={} 未配置任何权限项，拒绝访问 {}", user.getUserType(), requestUri);
            throw new AccessDeniedException("权限不足");
        }

        for (int i = 0; i < granted.patterns().size(); i++) {
            if (granted.patterns().get(i).matcher(requestUri).matches()
                    && matchMethod(requestMethod, granted.methods().get(i))) {
                return;
            }
        }
        throw new AccessDeniedException("权限不足");
    }

    /**
     * 读取某 user_type 对应角色被授予的所有接口模式。
     * 返回 null 表示该角色没有任何权限配置（调用方应回退）。
     */
    private CachedPatterns loadGrantedPatterns(Byte userType) {
        CachedPatterns cached = permissionCache.get(userType);
        if (cached != null && cached.expiresAt() > System.currentTimeMillis()) {
            return cached;
        }

        List<Pattern> patterns = new ArrayList<>();
        List<String> methods = new ArrayList<>();
        try {
            List<Role> roles = roleMapper.selectList(new QueryWrapper<Role>().eq("user_type", userType));
            for (Role role : roles) {
                List<RolePermission> bindings = rolePermissionMapper.selectList(
                        new QueryWrapper<RolePermission>().eq("role_id", role.getRoleId()));
                for (RolePermission binding : bindings) {
                    Permission permission = permissionMapper.selectById(binding.getPermissionId());
                    if (permission == null || permission.getUrl() == null || permission.getUrl().isBlank()) {
                        continue;
                    }
                    patterns.add(compileUrlPattern(permission.getUrl()));
                    methods.add(permission.getMethod() == null ? "*" : permission.getMethod());
                }
            }
        } catch (Exception e) {
            log.error("加载角色权限失败，回退到 user_type 兜底规则: {}", e.getMessage());
            return null;
        }

        CachedPatterns result = new CachedPatterns(patterns, methods,
                System.currentTimeMillis() + PERMISSION_CACHE_TTL_MS);
        permissionCache.put(userType, result);
        return result;
    }

    /**
     * 把一个接口模式编译成正则。
     *   {@code /admin/brands/**}     → 该前缀本身以及它下面的任意路径
     *   {@code /admin/users/{id}}    → 路径变量匹配一段非斜杠字符
     *
     * 注意结尾的 {@code /**} 必须同时匹配前缀本身：注册在类上的
     * {@code @RequestMapping("/admin/brands")} 收到的是 {@code /admin/brands}，
     * 如果编译成 {@code ^/admin/brands/.*$} 就会把自己列表接口拒掉。
     */
    private Pattern compileUrlPattern(String urlPattern) {
        StringBuilder regex = new StringBuilder("^");
        int i = 0;
        while (i < urlPattern.length()) {
            char c = urlPattern.charAt(i);
            if (c == '/' && i + 2 < urlPattern.length()
                    && urlPattern.charAt(i + 1) == '*' && urlPattern.charAt(i + 2) == '*') {
                regex.append("(/.*)?");
                i += 3;
                continue;
            }
            if (c == '*') {
                if (i + 1 < urlPattern.length() && urlPattern.charAt(i + 1) == '*') {
                    regex.append(".*");
                    i += 2;
                } else {
                    regex.append("[^/]*");
                    i += 1;
                }
            } else if (c == '{') {
                int close = urlPattern.indexOf('}', i);
                if (close > i) {
                    regex.append("[^/]+");
                    i = close + 1;
                } else {
                    regex.append("\\{");
                    i += 1;
                }
            } else {
                if ("\\.[]()+?^$|".indexOf(c) >= 0) {
                    regex.append('\\');
                }
                regex.append(c);
                i += 1;
            }
        }
        regex.append('$');
        return Pattern.compile(regex.toString());
    }

    /**
     * 方法匹配，支持*匹配所有方法
     */
    private boolean matchMethod(String requestMethod, String permissionMethod) {
        return "*".equals(permissionMethod) || requestMethod.equalsIgnoreCase(permissionMethod);
    }
}
