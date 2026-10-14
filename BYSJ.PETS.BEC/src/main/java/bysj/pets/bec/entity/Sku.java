package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Date;

/**
 * SKU实体类
 */
@ToString
@Data
@Accessors(chain = true)
@TableName("sku")
public class Sku implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * SKU ID
     */
    @TableId(value = "sku_id", type = IdType.AUTO)
    private Long skuId;

    /**
     * 商品ID
     */
    private Long productId;

    /**
     * SKU属性
     */
    private String skuAttribute;

    /**
     * SKU值
     */
    private String skuValue;

    /**
     * SKU价格
     */
    private BigDecimal price;

    /**
     * SKU库存
     */
    private Integer stock;

    /**
     * SKU安全库存
     */
    private Integer minStock;

    /**
     * SKU销量
     */
    private Integer sales;

    /**
     * 创建时间
     */
    private Date createTime;

    /**
     * 更新时间
     */
    private Date updateTime;
}