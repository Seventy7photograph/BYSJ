package bysj.pets.bec.controller;


import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.service.impl.CaptchaService;
import bysj.pets.bec.service.IUserService;
import bysj.pets.bec.utils.CaptchaUtils;
import bysj.pets.bec.utils.JwtUtils;
import bysj.pets.bec.utils.EmailUtils;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private CaptchaService captchaService;

    // 验证码缓存，key为邮箱，value为验证码
    private static final Map<String, String> VERIFICATION_CODES = new ConcurrentHashMap<>();

    @Autowired
    private IUserService userService;

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody LoginRequest loginRequest) {
        // 1. 验证验证码
        boolean captchaValid = captchaService.validateCaptcha(
                loginRequest.getCaptchaKey(),
                loginRequest.getCaptcha()
        );
        if (!captchaValid) {
            Map<String, Object> error = new HashMap<>();
            error.put("code", 400);
            error.put("msg", "验证码错误或已过期");
            return error;
        }
        // 2. 认证用户名密码
        Authentication authentication;
        try {
            authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getUsername(),
                            loginRequest.getPassword()
                    )
            );
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("code", 400);
            error.put("msg", "用户名或密码错误");
            return error;
        }
        System.out.println(loginRequest.getUsername());
        System.out.println(loginRequest.getPassword());
        // 3. 从认证结果中获取UserDetails对象
        org.springframework.security.core.userdetails.User userDetails = 
            (org.springframework.security.core.userdetails.User) authentication.getPrincipal();
        
        // 4. 获取角色信息，去掉ROLE_前缀
        String[] roles = userDetails.getAuthorities().stream()
            .map(authority -> {
                String authorityName = authority.getAuthority();
                return authorityName.startsWith("ROLE_") 
                    ? authorityName.substring(5) 
                    : authorityName;
            })
            .toArray(String[]::new);
        
        // 5. 生成JWT令牌，包含角色信息
        String token = jwtUtils.generateToken(authentication.getName(), roles);

        // 4. 返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("msg", "登录成功");
        result.put("data", token);
        return result;
    }

    // 获取验证码接口 - 明确泛型类型
    @GetMapping("/captcha")
    public Result<Map<String, String>> getCaptcha() {
        CaptchaUtils.CaptchaResult result = captchaService.generateCaptcha();
        Map<String, String> data = new HashMap<>();
        data.put("key", result.getKey());
        data.put("image", result.getImage());
        // 使用带数据的success方法
        return Result.success("获取验证码成功", data);
    }

    // 登录请求参数封装
    @Data
    public static class LoginRequest {
        private String username;
        private String password;
        private String captcha;      // 验证码
        private String captchaKey;   // 验证码标识

        // getter和setter
        /*public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getCaptcha() { return captcha; }
        public void setCaptcha(String captcha) { this.captcha = captcha; }
        public String getCaptchaKey() { return captchaKey; }
        public void setCaptchaKey(String captchaKey) { this.captchaKey = captchaKey; }*/
    }


    //注册

    // 注册接口 - 修复泛型声明
    @PostMapping("/register")
    public ResponseEntity<Result<?>> register(@RequestBody User user) {
        try {
            User registeredUser = userService.register(user);
            // 统一使用Result.success响应
            return ResponseEntity.ok(Result.success("注册成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Result.error(e.getMessage()));
        }
    }

    // 验证用户是否存在并获取邮箱
    @PostMapping("/auth/check-user")
    public ResponseEntity<Result<?>> checkUser(@RequestBody CheckUserRequest request) {
        try {
            User user = userService.findByUsername(request.getUsername());
            if (user == null) {
                return ResponseEntity.badRequest().body(Result.error("用户不存在"));
            }
            if (user.getEmail() == null || user.getEmail().isEmpty()) {
                return ResponseEntity.badRequest().body(Result.error("用户未绑定邮箱"));
            }
            Map<String, String> data = new HashMap<>();
            data.put("email", user.getEmail());
            return ResponseEntity.ok(Result.success("用户验证成功", data));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Result.error("验证用户失败"));
        }
    }

    // 发送重置密码验证码
    @PostMapping("/auth/send-reset-code")
    public ResponseEntity<Result<?>> sendResetPasswordCode(@RequestBody SendCodeRequest request) {
        try {
            // 生成6位验证码
            String code = String.format("%06d", (int) (Math.random() * 1000000));
            // 缓存验证码
            VERIFICATION_CODES.put(request.getEmail(), code);
            // 发送邮件
            EmailUtils.sendEmail(request.getEmail(), "密码重置验证码", "您的密码重置验证码为：" + code + "，有效期5分钟。");
            return ResponseEntity.ok(Result.success("验证码发送成功"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Result.error("发送验证码失败"));
        }
    }

    // 验证重置密码验证码
    @PostMapping("/auth/verify-reset-code")
    public ResponseEntity<Result<?>> verifyResetPasswordCode(@RequestBody VerifyCodeRequest request) {
        try {
            String storedCode = VERIFICATION_CODES.get(request.getEmail());
            if (storedCode == null || !storedCode.equals(request.getCode())) {
                return ResponseEntity.badRequest().body(Result.error("验证码错误或已过期"));
            }
            return ResponseEntity.ok(Result.success("验证码验证成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Result.error("验证验证码失败"));
        }
    }

    // 重置密码
    @PostMapping("/auth/reset-password")
    public ResponseEntity<Result<?>> resetPassword(@RequestBody ResetPasswordRequest request) {
        try {
            // 验证验证码
            String storedCode = VERIFICATION_CODES.get(request.getEmail());
            if (storedCode == null || !storedCode.equals(request.getCode())) {
                return ResponseEntity.badRequest().body(Result.error("验证码错误或已过期"));
            }
            // 重置密码（使用用户名）
            userService.resetPasswordByUsername(request.getUsername(), request.getNewPassword());
            // 清除验证码
            VERIFICATION_CODES.remove(request.getEmail());
            return ResponseEntity.ok(Result.success("密码重置成功"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Result.error("重置密码失败"));
        }
    }

    // 请求参数封装
    @Data
    private static class CheckUserRequest {
        private String username;
    }

    @Data
    private static class SendCodeRequest {
        private String email;
    }

    @Data
    private static class VerifyCodeRequest {
        private String email;
        private String code;
    }

    @Data
    private static class ResetPasswordRequest {
        private String username;
        private String email;
        private String code;
        private String newPassword;
    }
}