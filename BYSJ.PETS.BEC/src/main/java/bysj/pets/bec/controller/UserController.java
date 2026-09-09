package bysj.pets.bec.controller;

import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.utils.JwtUtils;
import bysj.pets.bec.config.Result;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * <p>
 * 用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。	备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。 前端控制器
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // 头像存储路径
    private static final String AVATAR_PATH = "G:/study/AAA-BYSJ/BYSJ.PETS.FEC/public/head/";

    /**
     * 获取当前用户信息
     */
    @GetMapping("/profile")
    public Result<User> getCurrentUser(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader) {
        String username = null;
        
        // 1. 首先尝试从SecurityContext中获取用户信息
        org.springframework.security.core.Authentication authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated() && authentication.getPrincipal() != null) {
            if (authentication.getPrincipal() instanceof org.springframework.security.core.userdetails.UserDetails) {
                username = ((org.springframework.security.core.userdetails.UserDetails) authentication.getPrincipal()).getUsername();
            } else {
                username = authentication.getPrincipal().toString();
            }
        }
        
        // 2. 如果SecurityContext中没有用户信息，尝试从Authorization请求头获取token
        if (username == null && tokenHeader != null && tokenHeader.startsWith("Bearer ")) {
            String token = tokenHeader.substring(7);
            if (token != null && !token.isEmpty()) {
                username = jwtUtils.getUsernameFromToken(token);
            }
        }
        
        // 3. 验证用户名
        if (username == null) {
            return Result.error("用户未登录");
        }

        // 根据用户名获取用户信息
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }

        // 隐藏敏感信息
        user.setPassword(null);
        return Result.success("获取用户信息成功", user);
    }

    /**
     * 更新个人信息
     */
    @PutMapping("/profile")
    public Result<User> updateProfile(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody User userUpdate) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户信息
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }

        // 更新用户信息（只允许更新部分字段）
        user.setNickname(userUpdate.getNickname());
        user.setPhone(userUpdate.getPhone());
        user.setEmail(userUpdate.getEmail());
        user.setGender(userUpdate.getGender());
        user.setRealName(userUpdate.getRealName());
        user.setIdCard(userUpdate.getIdCard());
        user.setUpdateTime(LocalDateTime.now());

        // 保存更新
        userMapper.updateById(user);

        // 隐藏敏感信息
        user.setPassword(null);
        return Result.success("更新用户信息成功", user);
    }

    /**
     * 修改密码
     */
    @PutMapping("/password")
    public Result<?> changePassword(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody PasswordChangeRequest passwordChangeRequest) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户信息
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }

        // 验证旧密码
        if (!passwordEncoder.matches(passwordChangeRequest.getOldPassword(), user.getPassword())) {
            return Result.error("旧密码错误");
        }

        // 更新密码
        user.setPassword(passwordEncoder.encode(passwordChangeRequest.getNewPassword()));
        user.setUpdateTime(LocalDateTime.now());
        userMapper.updateById(user);

        return Result.success("密码修改成功");
    }

    /**
     * 上传头像
     */
    @PostMapping("/avatar")
    public Result<String> uploadAvatar(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestParam("file") MultipartFile file) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户信息
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }

        // 验证文件
        if (file.isEmpty()) {
            return Result.error("请选择要上传的头像文件");
        }

        // 确保头像目录存在
        File avatarDir = new File(AVATAR_PATH);
        if (!avatarDir.exists()) {
            avatarDir.mkdirs();
        }

        // 生成唯一文件名
        String originalFilename = file.getOriginalFilename();
        String fileExtension = originalFilename.substring(originalFilename.lastIndexOf("."));
        String fileName = UUID.randomUUID().toString() + fileExtension;
        String filePath = AVATAR_PATH + fileName;

        try {
            // 保存文件
            file.transferTo(new File(filePath));

            // 更新用户头像路径
            String avatarUrl = "/head/" + fileName;
            user.setAvatarUrl(avatarUrl);
            user.setUpdateTime(LocalDateTime.now());
            userMapper.updateById(user);

            return Result.success("头像上传成功", avatarUrl);
        } catch (IOException e) {
            e.printStackTrace();
            return Result.error("头像上传失败");
        }
    }

    /**
     * 密码修改请求实体
     */
    static class PasswordChangeRequest {
        private String oldPassword;
        private String newPassword;

        public String getOldPassword() {
            return oldPassword;
        }

        public void setOldPassword(String oldPassword) {
            this.oldPassword = oldPassword;
        }

        public String getNewPassword() {
            return newPassword;
        }

        public void setNewPassword(String newPassword) {
            this.newPassword = newPassword;
        }
    }
}
