package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("product_image")
public class ProductImage {
    @TableId(type = IdType.AUTO)
    private Long id;
    @TableField(value = "product_id", insertStrategy = FieldStrategy.ALWAYS)
    private Long productId;
    @TableField(value = "image_id", insertStrategy = FieldStrategy.ALWAYS)
    private Long imageId;
    @TableField(value = "image_type", insertStrategy = FieldStrategy.ALWAYS)
    private String imageType;
    @TableField(value = "sort", insertStrategy = FieldStrategy.ALWAYS)
    private Integer sort;
    @TableField(value = "create_time", insertStrategy = FieldStrategy.ALWAYS)
    private LocalDateTime createTime;
    @TableLogic
    @TableField(value = "is_deleted", insertStrategy = FieldStrategy.ALWAYS)
    private Integer isDeleted;
}