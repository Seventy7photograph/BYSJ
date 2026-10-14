package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.RolePermission;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

/**
 * <p>
 * 用途：RBAC 模型的中间表，实现角色与权限的多对多关联（如 "普通管理员" 关联 "商品审核""订单查看" 权限）。 映射器
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
public interface RolePermissionMapper extends BaseMapper<RolePermission> {

}
