package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_log")
public class SysLog {
    @TableId(type = IdType.AUTO)
    private Long logId;
    private Long userId;
    private Integer logType;
    private String operation;
    private String module;
    private String ip;
    private String errorMsg;
    private LocalDateTime createTime;
}
