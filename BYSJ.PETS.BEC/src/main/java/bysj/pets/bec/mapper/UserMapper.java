package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.User;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;

/**
 * <p>
 * 用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。	备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。 Mapper 接口
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
public interface UserMapper extends BaseMapper<User> {
    /**
     * 根据用户名查询用户ID
     */
    Long selectUserIdByUsername(@Param("username") String username);
    
    /**
     * 根据用户名查询用户信息
     */
    User selectUserByUsername(@Param("username") String username);
    
    /**
     * 根据用户ID查询用户名
     */
    String selectUsernameById(@Param("userId") Long userId);
}
