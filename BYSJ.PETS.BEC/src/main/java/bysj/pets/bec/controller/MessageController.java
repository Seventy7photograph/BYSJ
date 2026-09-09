package bysj.pets.bec.controller;

import bysj.pets.bec.entity.SysNotice;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.SysNoticeMapper;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.config.Result;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 消息中心Controller
 */
@RestController
@RequestMapping("/message")
public class MessageController {

    @Resource
    private SysNoticeMapper sysNoticeMapper;
    
    @Resource
    private UserMapper userMapper;
    
    /**
     * 获取当前用户的消息列表
     */
    @GetMapping("/list")
    public Result getMessageList(@RequestParam(defaultValue = "1") Integer page,
                                 @RequestParam(defaultValue = "10") Integer pageSize,
                                 @RequestParam(required = false) Byte noticeType) {
        // 获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        
        if (user == null) {
            return Result.error("用户不存在");
        }
        
        // 查询用户的消息
        QueryWrapper<SysNotice> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", user.getUserId());
        queryWrapper.eq("notice_status", 0); // 正常状态的消息
        
        if (noticeType != null) {
            queryWrapper.eq("notice_type", noticeType);
        }
        
        // 按创建时间倒序排序
        queryWrapper.orderByDesc("create_time");
        
        Page<SysNotice> noticePage = sysNoticeMapper.selectPage(new Page<>(page, pageSize), queryWrapper);
        return Result.success(noticePage);
    }
    
    /**
     * 获取未读消息数量
     */
    @GetMapping("/unread/count")
    public Result getUnreadMessageCount() {
        // 获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        
        if (user == null) {
            return Result.error("用户不存在");
        }
        
        // 查询未读消息数量
        QueryWrapper<SysNotice> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", user.getUserId());
        queryWrapper.eq("is_read", 0); // 未读
        queryWrapper.eq("notice_status", 0); // 正常状态
        
        long count = sysNoticeMapper.selectCount(queryWrapper);
        return Result.success(count);
    }
    
    /**
     * 标记单条消息为已读
     */
    @PutMapping("/{id}/read")
    public Result markMessageAsRead(@PathVariable Long id) {
        // 获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        
        if (user == null) {
            return Result.error("用户不存在");
        }
        
        // 更新消息状态为已读
        UpdateWrapper<SysNotice> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("notice_id", id);
        updateWrapper.eq("user_id", user.getUserId());
        updateWrapper.set("is_read", (byte) 1);
        
        int result = sysNoticeMapper.update(null, updateWrapper);
        if (result > 0) {
            return Result.success("标记成功");
        } else {
            return Result.error("标记失败");
        }
    }
    
    /**
     * 标记所有消息为已读
     */
    @PutMapping("/all/read")
    public Result markAllMessagesAsRead() {
        // 获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        
        if (user == null) {
            return Result.error("用户不存在");
        }
        
        // 更新所有消息状态为已读
        UpdateWrapper<SysNotice> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("user_id", user.getUserId());
        updateWrapper.eq("is_read", 0); // 只更新未读消息
        updateWrapper.set("is_read", (byte) 1);
        
        sysNoticeMapper.update(null, updateWrapper);
        return Result.success("标记成功");
    }
    
    /**
     * 删除消息
     */
    @DeleteMapping("/{id}")
    public Result deleteMessage(@PathVariable Long id) {
        // 获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        
        if (user == null) {
            return Result.error("用户不存在");
        }
        
        // 逻辑删除消息（更新状态为已删除）
        UpdateWrapper<SysNotice> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("notice_id", id);
        updateWrapper.eq("user_id", user.getUserId());
        updateWrapper.set("notice_status", (byte) 2); // 2-已删除
        
        int result = sysNoticeMapper.update(null, updateWrapper);
        if (result > 0) {
            return Result.success("删除成功");
        } else {
            return Result.error("删除失败");
        }
    }
}
