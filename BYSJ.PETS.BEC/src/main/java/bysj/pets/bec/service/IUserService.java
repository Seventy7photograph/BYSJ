package bysj.pets.bec.service;

import bysj.pets.bec.entity.User;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。	备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。 服务类
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
public interface IUserService extends IService<User> {
    /**
     * 用户注册
     * @param user 用户信息
     * @return 注册成功的用户信息
     */
    User register(User user);

    /**
     * 检查用户名是否已存在
     * @param username 用户名
     * @return 是否存在
     */
    boolean checkUsernameExists(String username);

    /**
     * 根据用户名查找用户
     * @param username 用户名
     * @return 用户信息
     */
    User findByUsername(String username);

    /**
     * 根据邮箱重置密码
     * @param email 邮箱
     * @param newPassword 新密码
     */
    void resetPasswordByEmail(String email, String newPassword);

    /**
     * 根据用户名重置密码
     * @param username 用户名
     * @param newPassword 新密码
     */
    void resetPasswordByUsername(String username, String newPassword);
}
