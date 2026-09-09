package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * 库存实体类
 */
@Data
@TableName("inventory")
public class Inventory implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("product_id")
    private Long productId;

    @TableField("product_name")
    private String productName;

    @TableField("product_type")
    private String productType;

    @TableField("sku_id")
    private Long skuId;

    @TableField("sku_attribute")
    private String skuAttribute;

    @TableField("sku_value")
    private String skuValue;

    @TableField("current_stock")
    private Integer currentStock;

    @TableField("min_stock")
    private Integer minStock;

    @TableField("sales")
    private Integer sales;

    @TableField("create_time")
    private Date createTime;

    @TableField("last_update_time")
    private Date lastUpdateTime;
}
