package bysj.pets.bec.utils;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * SQL注入防护工具类测试
 */
class SqlInjectionUtilTest {

    private SqlInjectionUtil sqlInjectionUtil;

    @BeforeEach
    void setUp() {
        sqlInjectionUtil = new SqlInjectionUtil();
    }

    @Test
    void testContainsSqlInjection_Positive() {
        // 测试包含SQL注入风险的输入
        String[] riskyInputs = {
            "1' OR '1'='1",
            "SELECT * FROM users",
            "INSERT INTO users VALUES (1, 'admin', 'password')",
            "DELETE FROM users",
            "DROP TABLE users",
            "UPDATE users SET password='hacked' WHERE id=1",
            "EXEC xp_cmdshell('dir')",
            "net user admin password /add"
        };

        for (String input : riskyInputs) {
            assertTrue(sqlInjectionUtil.containsSqlInjection(input));
        }
    }

    @Test
    void testContainsSqlInjection_Negative() {
        // 测试不包含SQL注入风险的输入
        String[] safeInputs = {
            "123",
            "test",
            "user@example.com",
            "Hello World",
            "123-456-7890"
        };

        for (String input : safeInputs) {
            assertFalse(sqlInjectionUtil.containsSqlInjection(input));
        }
    }

    @Test
    void testContainsSqlInjection_Null() {
        assertFalse(sqlInjectionUtil.containsSqlInjection(null));
    }

    @Test
    void testContainsSqlInjection_Empty() {
        assertFalse(sqlInjectionUtil.containsSqlInjection(""));
    }

    @Test
    void testFilterSqlInjection() {
        // 测试过滤SQL注入风险字符
        String riskyInput = "1' OR '1'='1' --";
        String filteredInput = sqlInjectionUtil.filterSqlInjection(riskyInput);
        assertFalse(filteredInput.contains("OR"));
        assertFalse(filteredInput.contains("--"));
    }

    @Test
    void testIsValidInput_Valid() {
        // 测试有效的输入
        assertTrue(sqlInjectionUtil.isValidInput("test", 10));
    }

    @Test
    void testIsValidInput_Invalid_Length() {
        // 测试长度超过限制的输入
        assertFalse(sqlInjectionUtil.isValidInput("testtesttest", 5));
    }

    @Test
    void testIsValidInput_Invalid_SqlInjection() {
        // 测试包含SQL注入风险的输入
        assertFalse(sqlInjectionUtil.isValidInput("1' OR '1'='1", 10));
    }

    @Test
    void testIsValidInput_Null() {
        // 测试空输入
        assertTrue(sqlInjectionUtil.isValidInput(null, 10));
    }

    @Test
    void testSanitizeInput() {
        // 测试清理和验证输入
        String input = "1' OR '1'='1' --";
        String sanitizedInput = sqlInjectionUtil.sanitizeInput(input, 10);
        assertFalse(sanitizedInput.contains("OR"));
        assertFalse(sanitizedInput.contains("--"));
        assertTrue(sanitizedInput.length() <= 10);
    }

    @Test
    void testSanitizeInput_Null() {
        // 测试空输入
        assertNull(sqlInjectionUtil.sanitizeInput(null, 10));
    }

    @Test
    void testSanitizeInput_Empty() {
        // 测试空字符串输入
        assertEquals("", sqlInjectionUtil.sanitizeInput("", 10));
    }
}
