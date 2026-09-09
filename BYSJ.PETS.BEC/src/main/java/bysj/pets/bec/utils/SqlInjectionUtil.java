package bysj.pets.bec.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/**
 * SQL注入防护工具类
 * 实现对用户输入的SQL注入检测和防护
 */
@Component
public class SqlInjectionUtil {

    private static final Logger logger = LoggerFactory.getLogger(SqlInjectionUtil.class);

    // SQL注入检测正则表达式
    private static final Pattern SQL_INJECTION_PATTERN = Pattern.compile(
            "(?i)(union|select|insert|drop|delete|update|alter|create|drop|truncate|exec|execute|xp_cmdshell|sp_executesql|sp_password|net\s+user|or\s+1=1|and\s+1=1)",
            Pattern.CASE_INSENSITIVE
    );

    /**
     * 检测输入是否包含SQL注入风险
     * @param input 用户输入
     * @return 是否包含SQL注入风险
     */
    public boolean containsSqlInjection(String input) {
        if (input == null || input.isEmpty()) {
            return false;
        }
        boolean match = SQL_INJECTION_PATTERN.matcher(input).find();
        if (match) {
            logger.warn("检测到SQL注入风险输入: {}", input);
        }
        return match;
    }

    /**
     * 过滤SQL注入风险字符
     * @param input 用户输入
     * @return 过滤后的输入
     */
    public String filterSqlInjection(String input) {
        if (input == null || input.isEmpty()) {
            return input;
        }
        // 替换危险字符
        String filtered = input
                .replaceAll("(?i)union", "")
                .replaceAll("(?i)select", "")
                .replaceAll("(?i)insert", "")
                .replaceAll("(?i)drop", "")
                .replaceAll("(?i)delete", "")
                .replaceAll("(?i)update", "")
                .replaceAll("(?i)alter", "")
                .replaceAll("(?i)create", "")
                .replaceAll("(?i)truncate", "")
                .replaceAll("(?i)exec", "")
                .replaceAll("(?i)execute", "")
                .replaceAll("(?i)xp_cmdshell", "")
                .replaceAll("(?i)sp_executesql", "")
                .replaceAll("(?i)sp_password", "")
                .replaceAll("(?i)net\\s+user", "")
                .replaceAll("(?i)or\\s+1=1", "")
                .replaceAll("(?i)and\\s+1=1", "");
        
        if (!input.equals(filtered)) {
            logger.info("过滤SQL注入风险输入: {} -> {}", input, filtered);
        }
        return filtered;
    }

    /**
     * 验证输入是否安全
     * @param input 用户输入
     * @param maxLength 最大长度
     * @return 是否安全
     */
    public boolean isValidInput(String input, int maxLength) {
        if (input == null) {
            return true;
        }
        if (input.length() > maxLength) {
            logger.warn("输入长度超过限制: {} (最大长度: {})", input.length(), maxLength);
            return false;
        }
        if (containsSqlInjection(input)) {
            return false;
        }
        return true;
    }

    /**
     * 清理和验证输入
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
        // 过滤SQL注入风险
        return filterSqlInjection(input);
    }
}
