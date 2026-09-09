package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName("brand")
public class Brand {
    @TableId(type = IdType.AUTO)
    private Integer brandId;

    @TableField("brand_name")
    private String brandName;

    @TableField("parent_id")
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

    @TableField(exist = false)
    private List<Brand> children;
}
