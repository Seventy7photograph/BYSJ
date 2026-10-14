package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.FieldStrategy;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName("product_category")
public class ProductCategory {
    @TableId(type = IdType.AUTO)
    private Integer categoryId;

    @TableField("category_name")
    private String categoryName;

    @TableField(value = "parent_id", insertStrategy = FieldStrategy.ALWAYS)
    private Integer parentId;

    @TableField("category_code")
    private String categoryCode;

    @TableField("sort")
    private Integer sort;

    @TableField("status")
    private Integer status;

    @TableField("description")
    private String description;

    @TableField("create_by")
    private Long createBy;

    @TableField("create_time")
    private LocalDateTime createTime;

    @TableField("update_by")
    private Long updateBy;

    @TableField("update_time")
    private LocalDateTime updateTime;
    
    // 非数据库字段，用于构建树形结构
    @TableField(exist = false)
    private List<ProductCategory> children;
}