package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@TableName("product_detail")
public class ProductDetail implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "detail_id", type = IdType.AUTO)
    private Long detailId;

    @TableField("product_id")
    private Long productId;

    @TableField("parameters")
    private String parameters;

    @TableField("warranty_info")
    private String warrantyInfo;

    @TableField("authorization")
    private String authorization;

    @TableField("img_urls")
    private String imgUrls;

    @TableField("description")
    private String description;

    @TableField("usage_duration")
    private String usageDuration;

    @TableField("repair_history")
    private Byte repairHistory;

    @TableField("accessories")
    private String accessories;

    @TableField("create_time")
    private LocalDateTime createTime;

    @TableField("update_time")
    private LocalDateTime updateTime;
}
