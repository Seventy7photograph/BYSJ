package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * 库存历史记录实体类
 */
@Data
@TableName("inventory_history")
public class InventoryHistory implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("inventory_id")
    private Long inventoryId;

    @TableField("change_time")
    private Date changeTime;

    @TableField("change_type")
    private String changeType;

    @TableField("before_stock")
    private Integer beforeStock;

    @TableField("after_stock")
    private Integer afterStock;

    @TableField("change_quantity")
    private Integer changeQuantity;

    @TableField("reason")
    private String reason;

    @TableField("operator")
    private String operator;
}
