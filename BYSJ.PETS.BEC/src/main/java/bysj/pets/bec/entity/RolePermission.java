package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

/**
 * <p>
 * 用途：RBAC 模型的中间表，实现角色与权限的多对多关联（如 "普通管理员" 关联 "商品审核""订单查看" 权限）。
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */
@TableName("role_permission")
public class RolePermission {

    /**
     * 关联记录唯一标识
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 关联role.role_id，角色删除时同步删除关联记录
     */
    private Integer roleId;

    /**
     * 关联permission.permission_id，权限删除时同步删除关联记录
     */
    private Integer permissionId;

    /**
     * 关联记录创建时间
     */
    private LocalDateTime createTime;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getRoleId() {
        return roleId;
    }

    public void setRoleId(Integer roleId) {
        this.roleId = roleId;
    }

    public Integer getPermissionId() {
        return permissionId;
    }

    public void setPermissionId(Integer permissionId) {
        this.permissionId = permissionId;
    }

    public LocalDateTime getCreateTime() {
        return createTime;
    }

    public void setCreateTime(LocalDateTime createTime) {
        this.createTime = createTime;
    }

    @Override
    public String toString() {
        return "RolePermission{" +
                "id=" + id +
                ", roleId=" + roleId +
                ", permissionId=" + permissionId +
                ", createTime=" + createTime +
                '}';
    }
}
