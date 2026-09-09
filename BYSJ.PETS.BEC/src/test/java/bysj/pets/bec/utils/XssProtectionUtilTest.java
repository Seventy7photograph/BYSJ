package bysj.pets.bec.utils;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * XSS攻击防护工具类测试
 */
class XssProtectionUtilTest {

    private XssProtectionUtil xssProtectionUtil;

    @BeforeEach
    void setUp() {
        xssProtectionUtil = new XssProtectionUtil();
    }

    @Test
    void testContainsXss_Positive() {
        // 测试包含XSS风险的输入
        String[] riskyInputs = {
            "<script>alert('XSS')</script>",
            "<iframe src='http://evil.com'></iframe>",
            "<object data='http://evil.com'></object>",
            "<embed src='http://evil.com'></embed>",
            "<link rel='stylesheet' href='http://evil.com'></link>",
            "<style>body { background: url('http://evil.com') }</style>",
            "<meta http-equiv='refresh' content='0;url=http://evil.com'>",
            "javascript:alert('XSS')",
            "vbscript:alert('XSS')",
            "<div onload='alert(\"XSS\")'>",
            "<img src='x' onerror='alert(\"XSS\")'>",
            "<button onclick='alert(\"XSS\")'>Click</button>",
            "<div onmouseover='alert(\"XSS\")'>Hover</div>",
            "<input onkeydown='alert(\"XSS\")'>",
            "<input onkeyup='alert(\"XSS\")'>",
            "<input onchange='alert(\"XSS\")'>",
            "<input onfocus='alert(\"XSS\")'>",
            "<input onblur='alert(\"XSS\")'>"
        };

        for (String input : riskyInputs) {
            assertTrue(xssProtectionUtil.containsXss(input));
        }
    }

    @Test
    void testContainsXss_Negative() {
        // 测试不包含XSS风险的输入
        String[] safeInputs = {
            "123",
            "test",
            "user@example.com",
            "Hello World",
            "123-456-7890",
            "<p>Hello</p>",
            "<div>Test</div>",
            "<span>Text</span>"
        };

        for (String input : safeInputs) {
            assertFalse(xssProtectionUtil.containsXss(input));
        }
    }

    @Test
    void testContainsXss_Null() {
        assertFalse(xssProtectionUtil.containsXss(null));
    }

    @Test
    void testContainsXss_Empty() {
        assertFalse(xssProtectionUtil.containsXss(""));
    }

    @Test
    void testFilterXss() {
        // 测试过滤XSS风险字符
        String riskyInput = "<script>alert('XSS')</script> <img src='x' onerror='alert(\"XSS\")'>";
        String filteredInput = xssProtectionUtil.filterXss(riskyInput);
        assertFalse(filteredInput.contains("<script>"));
        assertFalse(filteredInput.contains("</script>"));
        assertFalse(filteredInput.contains("onerror="));
    }

    @Test
    void testEscapeHtml() {
        // 测试HTML转义
        String input = "<script>alert('XSS')</script>";
        String escapedInput = xssProtectionUtil.escapeHtml(input);
        assertEquals("&lt;script&gt;alert('XSS')&lt;/script&gt;", escapedInput);
    }

    @Test
    void testSanitizeInput() {
        // 测试清理和验证输入
        String input = "<script>alert('XSS')</script>";
        String sanitizedInput = xssProtectionUtil.sanitizeInput(input, 100);
        assertFalse(sanitizedInput.contains("<script>"));
        assertFalse(sanitizedInput.contains("</script>"));
        assertTrue(sanitizedInput.contains("alert('XSS')")); // 转义后应该保留内容
    }

    @Test
    void testSanitizeInput_Null() {
        // 测试空输入
        assertNull(xssProtectionUtil.sanitizeInput(null, 100));
    }

    @Test
    void testSanitizeInput_Empty() {
        // 测试空字符串输入
        assertEquals("", xssProtectionUtil.sanitizeInput("", 100));
    }
}
