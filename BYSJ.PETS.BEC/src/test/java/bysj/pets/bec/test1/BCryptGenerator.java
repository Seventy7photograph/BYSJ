package bysj.pets.bec.test1;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class BCryptGenerator {
    public static void main(String[] args) {
        // 初始化 BCrypt 编码器（强度 12，默认值）
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
        // 要加密的明文密码（比如 123456）
        String rawPassword = "123456";
        // 生成加密后的密文
        String encodedPassword = encoder.encode(rawPassword);
        // 打印密文（复制这个结果到数据库）
        System.out.println("BCrypt 密文：" + encodedPassword);
    }
}
