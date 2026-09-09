package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.Role;
import bysj.pets.bec.mapper.RoleMapper;
import bysj.pets.bec.service.IRoleService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 用途：存储系统角色（超级管理员 / 普通管理员 / 运营管理员），支撑基于角色的权限控制（RBAC）。 服务实现类
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
@Service
public class RoleServiceImpl extends ServiceImpl<RoleMapper, Role> implements IRoleService {

}
