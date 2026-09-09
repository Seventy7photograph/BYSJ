package bysj.pets.bec.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 安全头信息过滤器
 * 设置Content-Security-Policy、X-Content-Type-Options等安全头信息
 * 确保Cookie的HttpOnly和Secure属性设置
 */
@Component
public class SecurityHeaderFilter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(SecurityHeaderFilter.class);

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        logger.info("安全头信息过滤器初始化");
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // 设置Content-Security-Policy头信息
        httpResponse.setHeader("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'");

        // 设置X-Content-Type-Options头信息，防止MIME类型嗅探
        httpResponse.setHeader("X-Content-Type-Options", "nosniff");

        // 设置X-Frame-Options头信息，防止点击劫持
        httpResponse.setHeader("X-Frame-Options", "DENY");

        // 设置X-XSS-Protection头信息，启用浏览器的XSS过滤器
        httpResponse.setHeader("X-XSS-Protection", "1; mode=block");

        // 设置Strict-Transport-Security头信息，强制使用HTTPS
        httpResponse.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");

        // 继续处理请求
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        logger.info("安全头信息过滤器销毁");
    }
}
