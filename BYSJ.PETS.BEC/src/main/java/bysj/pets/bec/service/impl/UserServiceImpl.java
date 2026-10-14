package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.IUserService;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

/**
 * <p>
 * 用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。	备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。 服务实现类
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements IUserService {
    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public User register(User user) {
        // 检查用户名是否已存在
        if (checkUsernameExists(user.getUsername())) {
            throw new RuntimeException("用户名已存在");
        }


        // 加密密码
        user.setPassword(passwordEncoder.encode(user.getPassword()));

        // 设置创建时间
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());

        // 保存用户信息
        save(user);

        return user;
    }

    @Override
    public boolean checkUsernameExists(String username) {
        return count(new QueryWrapper<User>().eq("username", username)) > 0;
    }

    @Override
    public User findByUsername(String username) {
        return getOne(new QueryWrapper<User>().eq("username", username));
    }

    @Override
    public void resetPasswordByEmail(String email, String newPassword) {
        List<User> users = list(new QueryWrapper<User>().eq("email", email));
        if (users == null || users.isEmpty()) {
            throw new RuntimeException("用户不存在");
        }
        if (users.size() > 1) {
            throw new RuntimeException("邮箱对应多个用户，请联系管理员");
        }
        User user = users.get(0);
        // 加密新密码
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdateTime(LocalDateTime.now());
        updateById(user);
    }

    @Override
    public void resetPasswordByUsername(String username, String newPassword) {
        User user = getOne(new QueryWrapper<User>().eq("username", username));
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        // 加密新密码
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdateTime(LocalDateTime.now());
        updateById(user);
    }
}
