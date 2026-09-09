package bysj.pets.bec.utils;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 敏感数据脱敏工具类测试
 */
class SensitiveDataMaskUtilTest {

    private SensitiveDataMaskUtil sensitiveDataMaskUtil;

    @BeforeEach
    void setUp() {
        sensitiveDataMaskUtil = new SensitiveDataMaskUtil();
    }

    @Test
    void testMaskPhone() {
        String phone = "13812345678";
        String maskedPhone = sensitiveDataMaskUtil.mask(phone, SensitiveDataMaskUtil.MaskType.PHONE);
        assertEquals("138****5678", maskedPhone);
    }

    @Test
    void testMaskIdCard() {
        String idCard = "110101199001011234";
        String maskedIdCard = sensitiveDataMaskUtil.mask(idCard, SensitiveDataMaskUtil.MaskType.ID_CARD);
        assertEquals("110101********1234", maskedIdCard);
    }

    @Test
    void testMaskBankCard() {
        String bankCard = "6222021234567890123";
        String maskedBankCard = sensitiveDataMaskUtil.mask(bankCard, SensitiveDataMaskUtil.MaskType.BANK_CARD);
        assertEquals("6222****0123", maskedBankCard);
    }

    @Test
    void testMaskName() {
        // 测试双字名
        String name1 = "张三";
        String maskedName1 = sensitiveDataMaskUtil.mask(name1, SensitiveDataMaskUtil.MaskType.NAME);
        assertEquals("张*", maskedName1);

        // 测试三字名
        String name2 = "李四华";
        String maskedName2 = sensitiveDataMaskUtil.mask(name2, SensitiveDataMaskUtil.MaskType.NAME);
        assertEquals("李*华", maskedName2);

        // 测试四字名
        String name3 = "王五麻子";
        String maskedName3 = sensitiveDataMaskUtil.mask(name3, SensitiveDataMaskUtil.MaskType.NAME);
        assertEquals("王*子", maskedName3);
    }

    @Test
    void testMaskEmail() {
        String email = "zhangsan@example.com";
        String maskedEmail = sensitiveDataMaskUtil.mask(email, SensitiveDataMaskUtil.MaskType.EMAIL);
        assertEquals("zha****@example.com", maskedEmail);
    }

    @Test
    void testMaskAddress() {
        String address = "北京市海淀区中关村大街123号";
        String maskedAddress = sensitiveDataMaskUtil.mask(address, SensitiveDataMaskUtil.MaskType.ADDRESS);
        assertEquals("北京市海淀区中关****", maskedAddress);
    }

    @Test
    void testMaskPassword() {
        String password = "password123";
        String maskedPassword = sensitiveDataMaskUtil.mask(password, SensitiveDataMaskUtil.MaskType.PASSWORD);
        assertEquals("******", maskedPassword);
    }

    @Test
    void testMaskCustom() {
        String data = "1234567890";
        String maskedData = sensitiveDataMaskUtil.maskCustom(data, 2, 3, '*');
        assertEquals("12*****890", maskedData);
    }

    @Test
    void testMaskNull() {
        assertNull(sensitiveDataMaskUtil.mask(null, SensitiveDataMaskUtil.MaskType.PHONE));
    }

    @Test
    void testMaskEmpty() {
        assertEquals("", sensitiveDataMaskUtil.mask("", SensitiveDataMaskUtil.MaskType.PHONE));
    }

    @Test
    void testMaskShortData() {
        // 测试短手机号
        String shortPhone = "138";
        assertEquals(shortPhone, sensitiveDataMaskUtil.mask(shortPhone, SensitiveDataMaskUtil.MaskType.PHONE));

        // 测试短身份证号
        String shortIdCard = "110101";
        assertEquals(shortIdCard, sensitiveDataMaskUtil.mask(shortIdCard, SensitiveDataMaskUtil.MaskType.ID_CARD));

        // 测试短银行卡号
        String shortBankCard = "6222";
        assertEquals(shortBankCard, sensitiveDataMaskUtil.mask(shortBankCard, SensitiveDataMaskUtil.MaskType.BANK_CARD));

        // 测试短姓名
        String shortName = "张";
        assertEquals(shortName, sensitiveDataMaskUtil.mask(shortName, SensitiveDataMaskUtil.MaskType.NAME));

        // 测试短地址
        String shortAddress = "北京";
        assertEquals(shortAddress, sensitiveDataMaskUtil.mask(shortAddress, SensitiveDataMaskUtil.MaskType.ADDRESS));
    }
}
