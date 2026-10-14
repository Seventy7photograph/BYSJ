package bysj.pets.bec.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import bysj.pets.bec.config.JwtAuthenticationFilter;
import bysj.pets.bec.config.SecurityHeaderFilter;
import bysj.pets.bec.utils.JwtUtils;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.Arrays;
import java.util.Collections;

@Configuration
@EnableWebSecurity // 启用Web安全配置
public class SecurityConfig {

    // 注入自定义的UserDetailsService（你的用户查询逻辑）
    private final UserDetailsService userDetailsService;
    private final JwtUtils jwtUtils;
    private final DynamicPermissionFilter dynamicPermissionFilter;

    // 构造器注入UserDetailsService、JwtUtils和DynamicPermissionFilter
    public SecurityConfig(UserDetailsService userDetailsService, JwtUtils jwtUtils, DynamicPermissionFilter dynamicPermissionFilter) {
        this.userDetailsService = userDetailsService;
        this.jwtUtils = jwtUtils;
        this.dynamicPermissionFilter = dynamicPermissionFilter;
    }

    // 1. 配置密码编码器
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    // 2. 配置认证提供者（绑定UserDetailsService和密码编码器）
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService); // 绑定用户查询逻辑
        provider.setPasswordEncoder(passwordEncoder()); // 绑定密码编码器
        return provider;
    }
    
    // 6. 配置JWT过滤器Bean
    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter(jwtUtils, userDetailsService);
    }

    // 3. 核心：暴露AuthenticationManager为可注入的Bean
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        // 从认证配置中获取全局AuthenticationManager（自动关联上面的AuthenticationProvider）
        return authConfig.getAuthenticationManager();
    }

    // 4. 配置CORS，允许前端访问
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.addAllowedOriginPattern("*");
        configuration.addAllowedMethod("*");
        configuration.addAllowedHeader("*");
        configuration.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    // 5. 配置安全过滤链（放行接口、关闭CSRF等）
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable()) // 开发阶段关闭CSRF（前后端分离场景推荐）
                // 配置CORS，允许所有源访问
                .cors(cors -> cors.configurationSource(request -> {
                    CorsConfiguration config = new CorsConfiguration();
                    config.setAllowedOriginPatterns(Collections.singletonList("*"));
                    config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
                    config.setAllowedHeaders(Arrays.asList("*"));
                    config.setAllowCredentials(true);
                    return config;
                }))
                // 配置基于角色的权限控制
                .authorizeHttpRequests(auth -> auth
                        // 公开接口，不需要认证
                        .requestMatchers("/auth/**", "/public/**", "/image/**", "/captcha", "/shop/**", "/login", "/register", 
                                        "/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs", "/v3/api-docs/**", "/swagger-resources/**", "/webjars/**").permitAll()
                        // 上传后的静态文件对外公开（商品图/头像本身不是敏感数据，靠不可猜的文件名保护即可）
                        .requestMatchers("/uploads/**").permitAll()
                        // 评价相关接口，获取商品评价不需要认证
                        .requestMatchers("/evaluations/product/**").permitAll()
                        // 上传接口对所有已登录角色开放：买家传评价图、商家传商品图、管理员传公告图
                        .requestMatchers("/files/**").authenticated()
                        
                        // 管理员权限接口（普通管理员和超级管理员都可以访问）
                        .requestMatchers("/admin/**").hasAnyAuthority("ROLE_ADMIN", "ADMIN", "ROLE_SUPER_ADMIN", "SUPER_ADMIN")
                        
                        // 超级管理员专属接口
                        .requestMatchers("/super-admin/**").hasAnyAuthority("ROLE_SUPER_ADMIN", "SUPER_ADMIN")
                        
                        // 商家权限接口。超级管理员代表平台，需要能查看任意店铺的经营数据，
                        // 因此这里也放行 SUPER_ADMIN。
                        .requestMatchers("/merchant/**").hasAnyAuthority("ROLE_MERCHANT", "MERCHANT", "ROLE_SUPER_ADMIN", "SUPER_ADMIN")
                        
                        // 个人信息相关接口，所有认证用户都可访问
                        .requestMatchers("/user/**").authenticated()
                        // 订单相关接口，允许所有认证用户访问
                        .requestMatchers("/orders/**").authenticated()
                        // 评价相关接口，除了获取商品评价外，其他需要认证
                        .requestMatchers("/evaluations/**").authenticated()
                        // 收藏和购物车相关接口，普通用户和商家都可以访问
                        .requestMatchers("/favorites/**", "/cart/**").hasAnyAuthority("ROLE_USER", "USER", "ROLE_MERCHANT", "MERCHANT", "ROLE_SUPER_ADMIN", "SUPER_ADMIN")
                        
                        // 其他所有请求都需要认证
                        .anyRequest().authenticated()
                )
                // 未登录返回 401、已登录但无权限返回 403。
                // 默认实现两种情况都回 403，前端因此把"登录过期"显示成"没有权限"，
                // 也不会触发 401 分支去清理令牌并跳转登录页。
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) -> {
                            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                            response.setContentType("application/json;charset=UTF-8");
                            response.getWriter().write("{\"code\":401,\"msg\":\"用户未登录或登录已过期\"}");
                        })
                        .accessDeniedHandler((request, response, accessDeniedException) -> {
                            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                            response.setContentType("application/json;charset=UTF-8");
                            response.getWriter().write("{\"code\":403,\"msg\":\"权限不足\"}");
                        })
                )
                // 添加安全头信息过滤器
                .addFilterBefore(new SecurityHeaderFilter(), UsernamePasswordAuthenticationFilter.class)
                // 添加JWT过滤器
                .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class)
                // 添加动态权限过滤器，放在JWT过滤器之后
                .addFilterAfter(dynamicPermissionFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
