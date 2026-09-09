package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Role;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

/**
 * <p>
 * 用途：存储系统角色（超级管理员 / 普通管理员 / 运营管理员），支撑基于角色的权限控制（RBAC）。 Mapper 接口
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
public interface RoleMapper extends BaseMapper<Role> {

}
