package bysj.pets.bec.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/**
 * XSS攻击防护工具类
 * 实现对用户输入的XSS攻击检测和防护
 */
@Component
public class XssProtectionUtil {

    private static final Logger logger = LoggerFactory.getLogger(XssProtectionUtil.class);

    // XSS检测正则表达式
    private static final Pattern XSS_PATTERN = Pattern.compile(
            "<script[\\s\\S]*?<\\/script>|<iframe[\\s\\S]*?<\\/iframe>|<object[\\s\\S]*?<\\/object>|<embed[\\s\\S]*?<\\/embed>|<link[\\s\\S]*?<\\/link>|<style[\\s\\S]*?<\\/style>|<meta[\\s\\S]*?>|javascript:|vbscript:|onload=|onerror=|onclick=|onmouseover=|onmouseout=|onkeydown=|onkeyup=|onchange=|onfocus=|onblur=",
            Pattern.CASE_INSENSITIVE
    );

    /**
     * 检测输入是否包含XSS风险
     * @param input 用户输入
     * @return 是否包含XSS风险
     */
    public boolean containsXss(String input) {
        if (input == null || input.isEmpty()) {
            return false;
        }
        boolean match = XSS_PATTERN.matcher(input).find();
        if (match) {
            logger.warn("检测到XSS攻击风险输入: {}", input);
        }
        return match;
    }

    /**
     * 过滤XSS风险字符
     * @param input 用户输入
     * @return 过滤后的输入
     */
    public String filterXss(String input) {
        if (input == null || input.isEmpty()) {
            return input;
        }
        // 替换危险字符
        String filtered = input
                .replaceAll("<script[\\s\\S]*?<\\/script>", "")
                .replaceAll("<iframe[\\s\\S]*?<\\/iframe>", "")
                .replaceAll("<object[\\s\\S]*?<\\/object>", "")
                .replaceAll("<embed[\\s\\S]*?<\\/embed>", "")
                .replaceAll("<link[\\s\\S]*?<\\/link>", "")
                .replaceAll("<style[\\s\\S]*?<\\/style>", "")
                .replaceAll("<meta[\\s\\S]*?>", "")
                .replaceAll("(?i)javascript:", "")
                .replaceAll("(?i)vbscript:", "")
                .replaceAll("(?i)onload=", "")
                .replaceAll("(?i)onerror=", "")
                .replaceAll("(?i)onclick=", "")
                .replaceAll("(?i)onmouseover=", "")
                .replaceAll("(?i)onmouseout=", "")
                .replaceAll("(?i)onkeydown=", "")
                .replaceAll("(?i)onkeyup=", "")
                .replaceAll("(?i)onchange=", "")
                .replaceAll("(?i)onfocus=", "")
                .replaceAll("(?i)onblur=", "");
        
        if (!input.equals(filtered)) {
            logger.info("过滤XSS攻击风险输入: {} -> {}", input, filtered);
        }
        return filtered;
    }

    /**
     * HTML转义，防止XSS攻击
     * @param input 用户输入
     * @return 转义后的输入
     */
    public String escapeHtml(String input) {
        if (input == null || input.isEmpty()) {
            return input;
        }
        return input
                .replaceAll("&", "&amp;")
                .replaceAll("<", "&lt;")
                .replaceAll(">", "&gt;")
                .replaceAll("'", "&#39;")
                .replaceAll("\"", "&quot;");
    }

    /**
     * 清理和验证输入，防止XSS攻击
     * @param input 用户输入
     * @param maxLength 最大长度
     * @return 清理后的输入
     */
    public String sanitizeInput(String input, int maxLength) {
        if (input == null) {
            return null;
        }
        // 截断过长的输入
        if (input.length() > maxLength) {
            input = input.substring(0, maxLength);
            logger.info("截断过长输入，长度: {} -> {}", input.length(), maxLength);
        }
        // 过滤XSS风险
        input = filterXss(input);
        // HTML转义
        return escapeHtml(input);
    }
}
