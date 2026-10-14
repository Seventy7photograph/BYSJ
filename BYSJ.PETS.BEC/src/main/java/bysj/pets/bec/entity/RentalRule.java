package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * <p>
 * 租赁规则表
 * </p>
 *
 * @author zsj
 * @since 2025-12-28
 */
@Data
@ToString
@Accessors(chain = true)
@TableName("rental_rule")
public class RentalRule implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 规则名称
     */
    @TableField("rule_name")
    private String ruleName;

    /**
     * 规则内容
     */
    @TableField("rule_content")
    private String ruleContent;

    /**
     * 规则类型：general-通用规则, damage-损坏赔偿, late-逾期规则
     */
    @TableField("rule_type")
    private String ruleType;

    /**
     * 是否启用：0-禁用, 1-启用
     */
    @TableField("is_active")
    private Byte isActive;

    /**
     * 创建时间
     */
    @TableField("created_time")
    private LocalDateTime createdTime;

    /**
     * 更新时间
     */
    @TableField("updated_time")
    private LocalDateTime updatedTime;

}