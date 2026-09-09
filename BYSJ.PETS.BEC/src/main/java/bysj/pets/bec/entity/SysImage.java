package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("sys_image")
@KeySequence
public class SysImage {
    @TableId(type = IdType.AUTO)
    private Long id;
    @TableField("image_name")
    private String imageName;
    @TableField("original_name")
    private String originalName;
    @TableField("storage_path")
    private String storagePath;
    @TableField("file_size")
    private Long fileSize;
    @TableField("file_type")
    private String fileType;
    @TableField("width")
    private Integer width;
    @TableField("height")
    private Integer height;
    @TableField("upload_user_id")
    private Long uploadUserId;
    @TableField("upload_time")
    private LocalDateTime uploadTime;
    @TableField("business_type")
    private String businessType;
    @TableLogic
    @TableField("is_deleted")
    private Integer isDeleted;
}