package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * <p>
 * 租赁器材状态表
 * </p>
 *
 * @author zsj
 * @since 2025-12-28
 */
@Data
@ToString
@Accessors(chain = true)
@TableName("rental_equipment_status")
public class RentalEquipmentStatus implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 外键，关联product.product_id
     */
    @TableField("product_id")
    private Long productId;

    /**
     * 器材序列号
     */
    @TableField("equipment_sn")
    private String equipmentSn;

    /**
     * 器材状态：0-可租, 1-已租出, 2-维修中, 3-已报废
     */
    @TableField("status")
    private Byte status;

    /**
     * 当前租赁订单ID（状态为1时非空）
     */
    @TableField("current_rental_order_id")
    private Long currentRentalOrderId;

    /**
     * 上次维护日期
     */
    @TableField("last_maintenance_date")
    private LocalDate lastMaintenanceDate;

    /**
     * 下次维护日期
     */
    @TableField("next_maintenance_date")
    private LocalDate nextMaintenanceDate;

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