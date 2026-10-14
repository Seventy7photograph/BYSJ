package bysj.pets.bec.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 敏感数据脱敏工具类
 * 实现对各种敏感数据的脱敏处理，确保数据安全合规
 */
@Component
public class SensitiveDataMaskUtil {

    private static final Logger logger = LoggerFactory.getLogger(SensitiveDataMaskUtil.class);

    /**
     * 脱敏类型枚举
     */
    public enum MaskType {
        PHONE,        // 手机号
        ID_CARD,      // 身份证号
        BANK_CARD,    // 银行卡号
        NAME,         // 姓名
        EMAIL,        // 邮箱
        ADDRESS,      // 地址
        PASSWORD      // 密码
    }

    /**
     * 统一的敏感数据脱敏方法
     * @param data 原始数据
     * @param type 脱敏类型
     * @return 脱敏后的数据
     */
    public String mask(String data, MaskType type) {
        if (data == null || data.isEmpty()) {
            return data;
        }

        switch (type) {
            case PHONE:
                return maskPhone(data);
            case ID_CARD:
                return maskIdCard(data);
            case BANK_CARD:
                return maskBankCard(data);
            case NAME:
                return maskName(data);
            case EMAIL:
                return maskEmail(data);
            case ADDRESS:
                return maskAddress(data);
            case PASSWORD:
                return maskPassword(data);
            default:
                return data;
        }
    }

    /**
     * 手机号脱敏
     * 保留前3位和后4位，中间用*代替
     * 示例：138****1234
     */
    public String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    /**
     * 身份证号脱敏
     * 保留前6位和后4位，中间用*代替
     * 示例：110101********1234
     */
    public String maskIdCard(String idCard) {
        if (idCard == null || idCard.length() < 10) {
            return idCard;
        }
        return idCard.substring(0, 6) + "********" + idCard.substring(idCard.length() - 4);
    }

    /**
     * 银行卡号脱敏
     * 保留前4位和后4位，中间用*代替
     * 示例：6222****1234
     */
    public String maskBankCard(String bankCard) {
        if (bankCard == null || bankCard.length() < 8) {
            return bankCard;
        }
        return bankCard.substring(0, 4) + "****" + bankCard.substring(bankCard.length() - 4);
    }

    /**
     * 姓名脱敏
     * 单字名：保留姓氏，名字用*代替
     * 多字名：保留姓氏和最后一个字，中间用*代替
     * 示例：张*，李**华
     */
    public String maskName(String name) {
        if (name == null || name.length() < 2) {
            return name;
        }
        if (name.length() == 2) {
            return name.substring(0, 1) + "*";
        }
        return name.substring(0, 1) + "*" + name.substring(name.length() - 1);
    }

    /**
     * 邮箱脱敏
     * 保留用户名的前3位和域名，中间用*代替
     * 示例：zhan****@example.com
     */
    public String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return email;
        }
        String[] parts = email.split("@");
        String username = parts[0];
        String domain = parts[1];
        if (username.length() <= 3) {
            return username + "****@" + domain;
        }
        return username.substring(0, 3) + "****@" + domain;
    }

    /**
     * 地址脱敏
     * 保留省市区，详细地址用*代替
     * 示例：北京市海淀区****
     */
    public String maskAddress(String address) {
        if (address == null || address.length() < 10) {
            return address;
        }
        // 简单实现：保留前10个字符，后面用*代替
        return address.substring(0, 10) + "****";
    }

    /**
     * 密码脱敏
     * 全部用*代替
     * 示例：******
     */
    public String maskPassword(String password) {
        if (password == null) {
            return password;
        }
        return "******";
    }

    /**
     * 自定义脱敏
     * @param data 原始数据
     * @param start 保留开始位置
     * @param end 保留结束位置（从末尾开始计算）
     * @param maskChar 脱敏字符
     * @return 脱敏后的数据
     */
    public String maskCustom(String data, int start, int end, char maskChar) {
        if (data == null || data.length() <= start + end) {
            return data;
        }
        StringBuilder sb = new StringBuilder();
        sb.append(data.substring(0, start));
        for (int i = 0; i < data.length() - start - end; i++) {
            sb.append(maskChar);
        }
        sb.append(data.substring(data.length() - end));
        return sb.toString();
    }
}
