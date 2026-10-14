package bysj.pets.bec.controller;


import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.service.impl.CaptchaService;
import bysj.pets.bec.service.IUserService;
import bysj.pets.bec.utils.CaptchaUtils;
import bysj.pets.bec.utils.JwtUtils;
import bysj.pets.bec.utils.EmailUtils;
import bysj.pets.bec.utils.RedisCacheUtil;
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

@RestController
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private CaptchaService captchaService;

    @Autowired
    private RedisCacheUtil redisCacheUtil;

    /**
     * 密码重置验证码。
     *
     * 原来是一个静态的 ConcurrentHashMap：进程重启就丢，多实例部署互相看不见，
     * 而且**永不过期** —— 邮件里写着"有效期5分钟"，实际永久有效。
     * 现在放 Redis，按 key 设 5 分钟 TTL，与邮件文案一致。
     */
    private static final String RESET_CODE_PREFIX = "pwd:reset:code:";
    private static final String RESET_COOLDOWN_PREFIX = "pwd:reset:cooldown:";
    private static final long RESET_CODE_TTL_SECONDS = 5 * 60;

    private String resetCodeKey(String email) {
        return RESET_CODE_PREFIX + email.trim().toLowerCase();
    }

    private String resetCooldownKey(String email) {
        return RESET_COOLDOWN_PREFIX + email.trim().toLowerCase();
    }

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
            String email = request.getEmail() == null ? "" : request.getEmail().trim();
            if (email.isEmpty()) {
                return ResponseEntity.badRequest().body(Result.error("请提供邮箱地址"));
            }
            // 重新发送间隔：前端有 60 秒倒计时，但那只是体验，服务端必须也拦一道，
            // 否则接口可以被直接用来刷邮件。
            if (Boolean.TRUE.equals(redisCacheUtil.hasKey(resetCooldownKey(email)))) {
                return ResponseEntity.badRequest().body(Result.error("验证码已发送，请 60 秒后再试"));
            }
            // 生成6位验证码
            String code = String.format("%06d", (int) (Math.random() * 1000000));
            // 缓存验证码，5 分钟有效
            redisCacheUtil.setCache(resetCodeKey(email), code, RESET_CODE_TTL_SECONDS);
            redisCacheUtil.setCache(resetCooldownKey(email), "1", 60);
            // 发送邮件
            EmailUtils.sendEmail(email, "密码重置验证码", "您的密码重置验证码为：" + code + "，有效期5分钟。");
            return ResponseEntity.ok(Result.success("验证码发送成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Result.error("发送验证码失败"));
        }
    }

    // 验证重置密码验证码
    @PostMapping("/auth/verify-reset-code")
    public ResponseEntity<Result<?>> verifyResetPasswordCode(@RequestBody VerifyCodeRequest request) {
        try {
            Object storedCode = request.getEmail() == null ? null : redisCacheUtil.getCache(resetCodeKey(request.getEmail()));
            if (storedCode == null || !storedCode.toString().equals(request.getCode())) {
                return ResponseEntity.badRequest().body(Result.error("验证码错误或已过期"));
            }
            return ResponseEntity.ok(Result.success("验证码验证成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Result.error("验证验证码失败"));
        }
    }

    /**
     * 重置密码。
     *
     * 原实现把 username 和 email 当成两个互不相关的入参：只要给任意一个自己
     * 能收到验证码的邮箱，再填上别人的用户名，就能把别人的密码改掉。
     * 这里必须校验邮箱确实是该账号绑定的邮箱。
     */
    @PostMapping("/auth/reset-password")
    public ResponseEntity<Result<?>> resetPassword(@RequestBody ResetPasswordRequest request) {
        try {
            if (request.getUsername() == null || request.getEmail() == null || request.getCode() == null) {
                return ResponseEntity.badRequest().body(Result.error("请求参数不完整"));
            }
            if (request.getNewPassword() == null || request.getNewPassword().length() < 6) {
                return ResponseEntity.badRequest().body(Result.error("新密码至少 6 位"));
            }

            User account = userService.findByUsername(request.getUsername());
            if (account == null) {
                return ResponseEntity.badRequest().body(Result.error("账号不存在"));
            }
            String boundEmail = account.getEmail();
            if (boundEmail == null || !boundEmail.equalsIgnoreCase(request.getEmail().trim())) {
                return ResponseEntity.badRequest().body(Result.error("邮箱与该账号绑定的邮箱不一致"));
            }

            // 验证验证码
            Object storedCode = redisCacheUtil.getCache(resetCodeKey(request.getEmail()));
            if (storedCode == null || !storedCode.toString().equals(request.getCode())) {
                return ResponseEntity.badRequest().body(Result.error("验证码错误或已过期"));
            }

            userService.resetPasswordByUsername(request.getUsername(), request.getNewPassword());
            // 验证码一次性使用
            redisCacheUtil.deleteCache(resetCodeKey(request.getEmail()));
            return ResponseEntity.ok(Result.success("密码重置成功"));
        } catch (Exception e) {
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
