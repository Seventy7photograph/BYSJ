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
    /** 相对存储根目录的键，例如 2026/10/ab12....png；与 URL 一一对应但不受前缀变更影响。 */
    @TableField("storage_key")
    private String storageKey;
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
