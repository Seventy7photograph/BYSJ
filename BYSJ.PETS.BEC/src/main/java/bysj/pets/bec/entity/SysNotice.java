package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;

/**
 * 系统通知表实体类
 */
@TableName("sys_notice")
public class SysNotice implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long noticeId;
    private Long userId;
    private String content;
    private Byte noticeType;
    private LocalDateTime createTime;
    private Byte isRead;
    private LocalDateTime expireTime;
    private Byte noticeStatus;

    public Long getNoticeId() {
        return noticeId;
    }

    public void setNoticeId(Long noticeId) {
        this.noticeId = noticeId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Byte getNoticeType() {
        return noticeType;
    }

    public void setNoticeType(Byte noticeType) {
        this.noticeType = noticeType;
    }

    public LocalDateTime getCreateTime() {
        return createTime;
    }

    public void setCreateTime(LocalDateTime createTime) {
        this.createTime = createTime;
    }

    public Byte getIsRead() {
        return isRead;
    }

    public void setIsRead(Byte isRead) {
        this.isRead = isRead;
    }

    public LocalDateTime getExpireTime() {
        return expireTime;
    }

    public void setExpireTime(LocalDateTime expireTime) {
        this.expireTime = expireTime;
    }

    public Byte getNoticeStatus() {
        return noticeStatus;
    }

    public void setNoticeStatus(Byte noticeStatus) {
        this.noticeStatus = noticeStatus;
    }
}
