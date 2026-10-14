package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.SysImage;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.SysImageMapper;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.StorageService;
import bysj.pets.bec.utils.JwtUtils;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

/**
 * 文件接口。
 *
 * 全站只有一个上传入口：POST /files/upload。商品图、头像、店铺 logo、资质材料、
 * 评价图都走它，靠 bizType 区分，统一登记进 sys_image、统一返回 URL。
 *
 * 历史接口 /image/upload 保留为别名（仍可用），/image/page 仍可查图库。
 */
@RestController
@RequestMapping("/files")
@RequiredArgsConstructor
public class FileController {

    private final StorageService storageService;
    private final SysImageMapper sysImageMapper;
    private final UserMapper userMapper;
    private final JwtUtils jwtUtils;

    /**
     * 上传一张图片。
     * 表单字段：file（文件）、bizType（可选，默认 product）。
     */
    @PostMapping("/upload")
    public Result<Map<String, Object>> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "bizType", required = false) String bizType,
            @RequestHeader(value = "Authorization", required = false) String tokenHeader) {
        try {
            Long userId = currentUserId(tokenHeader);
            StorageService.StoredFile stored = storageService.storeImage(file, bizType, userId);

            // 头像与店铺 logo 是"上传即生效"的单值字段，直接回写，避免前端
            // 先上传再调一次接口把同一张图重新提交一遍（原来那样每换一次头像
            // 都会在 sys_image 里多留一份副本）。
            String biz = bizType == null ? "" : bizType;
            if (userId != null && ("avatar".equals(biz) || "shop_logo".equals(biz))) {
                User patch = new User();
                patch.setUserId(userId);
                if ("avatar".equals(biz)) {
                    patch.setAvatarUrl(stored.url());
                } else {
                    patch.setShopLogoUrl(stored.url());
                }
                patch.setUpdateTime(java.time.LocalDateTime.now());
                userMapper.updateById(patch);
            }

            Map<String, Object> data = new HashMap<>();
            data.put("id", stored.id());
            data.put("url", stored.url());
            data.put("key", stored.key());
            data.put("name", stored.name());
            data.put("size", stored.size());
            data.put("width", stored.width());
            data.put("height", stored.height());
            return Result.success("上传成功", data);
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error("上传失败：" + e.getMessage());
        }
    }

    /**
     * 图库分页查询。
     *
     * 原 /image/page 返回的是 `Result.success(String.valueOf(page))` —— 一个
     * Page 对象的 toString()，前端拿到的是一串字面量文本而不是数据。这里返回真正的分页结构。
     */
    @GetMapping("/page")
    public Result<Map<String, Object>> page(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "20") Integer pageSize,
            @RequestParam(required = false) String bizType) {
        Page<SysImage> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<SysImage> wrapper = new LambdaQueryWrapper<>();
        if (bizType != null && !bizType.isBlank()) {
            wrapper.eq(SysImage::getBusinessType, bizType);
        }
        wrapper.orderByDesc(SysImage::getUploadTime);
        sysImageMapper.selectPage(page, wrapper);

        Map<String, Object> data = new HashMap<>();
        data.put("list", page.getRecords());
        data.put("total", page.getTotal());
        data.put("pageNum", page.getCurrent());
        data.put("pageSize", page.getSize());
        data.put("pages", page.getPages());
        return Result.success("查询成功", data);
    }

    private Long currentUserId(String tokenHeader) {
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return null;
        }
        try {
            String username = jwtUtils.getUsernameFromToken(tokenHeader.substring(7));
            if (username == null) return null;
            User user = userMapper.selectOne(
                    new LambdaQueryWrapper<User>().eq(User::getUsername, username).last("LIMIT 1"));
            return user == null ? null : user.getUserId();
        } catch (Exception e) {
            return null;
        }
    }
}
