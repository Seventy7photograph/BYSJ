package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * <p>
 * 用途：存储系统角色（超级管理员 / 普通管理员 / 运营管理员），支撑基于角色的权限控制（RBAC）。
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */

@ToString
@Data
@Accessors(chain = true)
public class Role implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 角色唯一标识
     */
    @TableId(value = "role_id", type = IdType.AUTO)
    private Integer roleId;

    /**
     * 角色名称（如 “超级管理员”“普通管理员”“运营管理员”）
     */
    private String roleName;

    /**
     * 角色id,1 - 个人用户，2 - 企业用户（器材商家），3 - 管理员，4 -超级管理员
     */
    private Byte userType;

    /**
     * 角色编码（如 “ADMIN_SUPER”“ADMIN_NORMAL”“ADMIN_OP”）
     */
    private String roleCode;

    /**
     * 角色描述（如 “超级管理员拥有全系统权限，可修改所有配置”）
     */
    private String description;

    /**
     * 角色创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /**
     * 角色信息更新时间
     */
    private LocalDateTime updateTime;
}
