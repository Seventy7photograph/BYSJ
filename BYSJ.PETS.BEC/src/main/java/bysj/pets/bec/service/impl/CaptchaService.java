package bysj.pets.bec.service.impl;

import bysj.pets.bec.utils.CaptchaUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
public class CaptchaService {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    // 验证码有效期5分钟
    private static final long EXPIRE_MINUTES = 5;

    // Redis键前缀
    private static final String CAPTCHA_PREFIX = "captcha:";

    /**
     * 生成验证码
     */
    public CaptchaUtils.CaptchaResult generateCaptcha() {
        CaptchaUtils.CaptchaResult result = CaptchaUtils.generateCaptcha();
        String key = CAPTCHA_PREFIX + result.getKey();
        
        // 存储验证码到Redis，设置过期时间
        redisTemplate.opsForValue().set(key, result.getCode(), EXPIRE_MINUTES, TimeUnit.MINUTES);

        return result;
    }

    /**
     * 验证验证码
     */
    public boolean validateCaptcha(String key, String code) {
        if (key == null || code == null) {
            return false;
        }

        String redisKey = CAPTCHA_PREFIX + key;
        String storedCode = (String) redisTemplate.opsForValue().get(redisKey);
        if (storedCode == null) {
            return false; // 验证码已过期或不存在
        }

        // 验证成功后移除验证码，防止重复使用
        redisTemplate.delete(redisKey);
        return storedCode.equalsIgnoreCase(code);
    }
}