package bysj.pets.bec.utils;

import cn.hutool.core.io.FileUtil;
import cn.hutool.core.util.IdUtil;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.Objects;

@Component
public class FileUploadUtil {
    // 从配置文件读取存储路径
    @Value("${file.upload.path}")
    private String uploadPath;

    // 从配置文件读取访问前缀
    @Value("${file.access.prefix}")
    private String accessPrefix;

    /**
     * 上传图片（支持压缩）
     * @param file 上传的文件
     * @return 图片的访问URL/存储路径
     */
    public String uploadImage(MultipartFile file) throws IOException {
        // 1. 校验文件类型（仅允许图片）
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("仅支持上传图片文件！");
        }

        // 2. 生成唯一文件名（防止重复，UUID+原文件后缀）
        String originalFileName = file.getOriginalFilename();
        String suffix = FileUtil.extName(Objects.requireNonNull(originalFileName));
        String uniqueFileName = IdUtil.simpleUUID() + "." + suffix;

        // 3. 创建存储目录（如果不存在）
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            boolean mkdirs = uploadDir.mkdirs();
            if (!mkdirs) {
                throw new IOException("创建存储目录失败！");
            }
        }

        // 4. 保存文件（并压缩，宽度1920px，高度自适应）
        // 修正路径拼接方式
        File destFile = new File(uploadPath + File.separator + uniqueFileName);
        try {
            Thumbnails.of(file.getInputStream())
                    .size(1920, 0)  // 宽度1920，高度0表示自适应
                    .outputQuality(0.8)  // 压缩质量80%
                    .toFile(destFile);
        } catch (Exception e) {
            // 如果压缩失败，直接保存原始文件
            file.transferTo(destFile);
        }

        // 5. 返回访问URL（前端可直接访问）
//        return accessPrefix + uniqueFileName;
        // 5. 返回访问URL（确保以/images/开头，与WebMvcConfig配置匹配）
        // 修正：确保URL格式为 "/images/文件名"
        return "/images/" + uniqueFileName;
    }
}
