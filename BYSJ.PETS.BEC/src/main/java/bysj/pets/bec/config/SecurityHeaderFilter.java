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
        // 收紧后的 CSP：
        //   · 去掉 script-src 的 'unsafe-eval' —— 生产构建里 Vue/Element Plus 都不需要它，
        //     留着等于把 eval 这条路重新打开；
        //   · 去掉 script-src 的 'unsafe-inline' —— 本接口只返回 JSON 与静态图片，
        //     没有任何页面依赖内联脚本；
        //   · style-src 仍保留 'unsafe-inline' —— Element Plus 运行时注入 <style>，
        //     去掉会直接让组件样式失效；
        //   · object-src 'none' / base-uri 'self' / frame-ancestors 'none'
        //     分别挡掉插件、<base> 劫持与点击劫持（与 X-Frame-Options 互为补充）。
        httpResponse.setHeader("Content-Security-Policy",
                "default-src 'self'; "
                        + "script-src 'self'; "
                        + "style-src 'self' 'unsafe-inline'; "
                        + "img-src 'self' data: blob:; "
                        + "font-src 'self'; "
                        + "connect-src 'self'; "
                        + "object-src 'none'; "
                        + "base-uri 'self'; "
                        + "frame-ancestors 'none'");

        // 设置X-Content-Type-Options头信息，防止MIME类型嗅探
        httpResponse.setHeader("X-Content-Type-Options", "nosniff");

        // 设置X-Frame-Options头信息，防止点击劫持
        httpResponse.setHeader("X-Frame-Options", "DENY");

        // 设置X-XSS-Protection头信息，启用浏览器的XSS过滤器
        // 旧浏览器的 XSS 审计器已被证明会引入新的安全问题（可被用来构造信息泄露），
        // 现代规范建议显式关闭它，改由 CSP 承担。
        httpResponse.setHeader("X-XSS-Protection", "0");
        httpResponse.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
        httpResponse.setHeader("Permissions-Policy", "geolocation=(), microphone=(), camera=()");

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
