package bysj.pets.bec.service;

import bysj.pets.bec.config.StorageProperties;
import bysj.pets.bec.entity.SysImage;
import bysj.pets.bec.mapper.SysImageMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.Locale;
import java.util.UUID;

/**
 * 文件存储的唯一入口。
 *
 * 职责边界很清楚：校验 → 落盘 → 登记到 sys_image → 返回可直接使用的 URL。
 * 业务代码不再自己拼路径、自己 transferTo、自己猜 URL 前缀。
 *
 * 约定：
 *   - 存储目录 {@link StorageProperties#getRoot()}，按 yyyy/MM 分目录；
 *   - 对外 URL 为 {@code <urlPrefix>/yyyy/MM/<uuid>.<ext>}，由 WebMvcConfig 静态映射提供；
 *   - 每一次成功落盘都对应 sys_image 里的一行，删除时先软删这一行，
 *     物理文件交给清理任务处理，避免删记录时把还在被引用的文件删掉。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StorageService {

    private static final DateTimeFormatter MONTH_DIR = DateTimeFormatter.ofPattern("yyyy/MM");

    private final StorageProperties properties;
    private final SysImageMapper sysImageMapper;

    /** 落盘结果。前端拿 url 就能直接显示。 */
    public record StoredFile(
            Long id,
            String url,
            String key,
            String name,
            long size,
            Integer width,
            Integer height
    ) {}

    /**
     * 保存一张图片并登记图库。
     *
     * @param file    上传的文件
     * @param bizType 业务类型，见 {@link StorageProperties#getAllowedBizTypes()}
     * @param userId  上传人，可为 null（历史数据/种子图）
     */
    public StoredFile storeImage(MultipartFile file, String bizType, Long userId) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("上传文件为空");
        }

        String biz = (bizType == null || bizType.isBlank()) ? "product" : bizType.trim();
        if (!properties.getAllowedBizTypes().contains(biz)) {
            throw new IllegalArgumentException("不支持的业务类型：" + biz);
        }

        long maxBytes = properties.getMaxSizeMb() * 1024L * 1024L;
        if (file.getSize() > maxBytes) {
            throw new IllegalArgumentException("单张图片不能超过 " + properties.getMaxSizeMb() + "MB");
        }

        String originalName = file.getOriginalFilename() == null ? "unnamed" : file.getOriginalFilename();
        String extension = extensionOf(originalName);
        if (extension == null || !properties.getAllowedExtensions().contains(extension)) {
            throw new IllegalArgumentException("只支持 " + String.join(" / ", properties.getAllowedExtensions()) + " 格式的图片");
        }

        String contentType = file.getContentType();
        boolean isPdf = "pdf".equals(extension);
        if (isPdf && !properties.getPdfBizTypes().contains(biz)) {
            throw new IllegalArgumentException("该场景只支持上传图片");
        }
        // Content-Type 只当提示：浏览器的文件选择器会给出 image/png 这类值，但
        // 命令行工具、移动端 WebView、部分代理会送 application/octet-stream。
        // 真正的把关是下一步的解码 —— 解不出图像就拒绝，这比相信一个头部更可靠。
        if (!isPdf && contentType != null && !contentType.startsWith("image/")
                && !contentType.equalsIgnoreCase("application/octet-stream")) {
            throw new IllegalArgumentException("只支持上传图片文件");
        }

        int sourceWidth = 0;
        int sourceHeight = 0;
        if (!isPdf) {
            // 先解码，确认这确实是一张能读的图片，而不是改了后缀的其它文件
            BufferedImage decoded;
            try (InputStream in = file.getInputStream()) {
                decoded = ImageIO.read(in);
            }
            if (decoded == null) {
                throw new IllegalArgumentException("无法解析该图片，请换一张再试");
            }
            sourceWidth = decoded.getWidth();
            sourceHeight = decoded.getHeight();
        }

        String month = LocalDateTime.now().format(MONTH_DIR);
        String storedName = UUID.randomUUID().toString().replace("-", "") + "." + extension;
        Path relativeKey = Paths.get(month, storedName);
        Path targetDir = Paths.get(properties.getRoot()).resolve(month).toAbsolutePath().normalize();
        Path target = targetDir.resolve(storedName);

        // 防御：拼出来的路径必须仍在存储根目录内
        Path root = Paths.get(properties.getRoot()).toAbsolutePath().normalize();
        if (!target.startsWith(root)) {
            throw new IllegalArgumentException("非法的存储路径");
        }

        Files.createDirectories(targetDir);

        long storedSize;
        if (isPdf) {
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, target, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
            storedSize = Files.size(target);
        } else {
            try (InputStream in = file.getInputStream()) {
                if (properties.getMaxEdge() > 0 && Math.max(sourceWidth, sourceHeight) > properties.getMaxEdge()) {
                    Thumbnails.of(in)
                            .size(properties.getMaxEdge(), properties.getMaxEdge())
                            .keepAspectRatio(true)
                            .outputQuality(properties.getQuality())
                            .toFile(target.toFile());
                } else {
                    Thumbnails.of(in)
                            .scale(1.0)
                            .outputQuality(properties.getQuality())
                            .toFile(target.toFile());
                }
                storedSize = Files.size(target);
            } catch (IOException e) {
                // 压缩失败就原样落盘，不让一次编码问题挡住上传
                try (InputStream fallback = file.getInputStream()) {
                    Files.copy(fallback, target, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                }
                storedSize = Files.size(target);
            }
        }

        Integer width = isPdf ? null : sourceWidth;
        Integer height = isPdf ? null : sourceHeight;
        if (!isPdf) {
            try (InputStream in = Files.newInputStream(target)) {
                BufferedImage stored = ImageIO.read(in);
                if (stored != null) {
                    width = stored.getWidth();
                    height = stored.getHeight();
                }
            } catch (IOException ignored) {
                // 尺寸只是元数据，读不到就沿用原图尺寸
            }
        }

        String url = normalizePrefix(properties.getUrlPrefix()) + "/" + month + "/" + storedName;

        SysImage record = new SysImage();
        record.setImageName(stripExtension(originalName));
        record.setOriginalName(originalName);
        record.setStoragePath(url);
        record.setStorageKey(relativeKey.toString().replace('\\', '/'));
        record.setFileSize(storedSize);
        record.setFileType(isPdf ? "application/pdf" : contentType);
        record.setWidth(width);
        record.setHeight(height);
        record.setUploadUserId(userId);
        record.setUploadTime(LocalDateTime.now());
        record.setBusinessType(biz);
        record.setIsDeleted(0);
        sysImageMapper.insert(record);

        log.debug("文件已保存 bizType={} url={} size={}B", biz, url, storedSize);
        return new StoredFile(record.getId(), url, record.getStorageKey(), originalName, storedSize, width, height);
    }

    /**
     * 把任意历史 URL（/images/x.png、/head/x.png、/uploads/...）解析成本地绝对路径。
     * 供需要读取文件内容的场景使用（导出、生成缩略图等）。
     */
    public Path resolveExisting(String urlOrKey) {
        if (urlOrKey == null || urlOrKey.isBlank()) return null;
        String prefix = normalizePrefix(properties.getUrlPrefix());
        String key = urlOrKey.trim();
        if (key.startsWith(prefix)) {
            key = key.substring(prefix.length());
        }
        while (key.startsWith("/")) key = key.substring(1);
        Path root = Paths.get(properties.getRoot()).toAbsolutePath().normalize();
        Path resolved = root.resolve(key).normalize();
        return resolved.startsWith(root) && Files.exists(resolved) ? resolved : null;
    }

    /** 软删除图库中的一行；物理文件留给清理任务。 */
    public void softDelete(Long imageId) {
        if (imageId == null) return;
        SysImage record = new SysImage();
        record.setId(imageId);
        record.setIsDeleted(1);
        sysImageMapper.updateById(record);
    }

    /** 计算内容的 SHA-256，用于排查重复上传（不参与去重决策）。 */
    public static String sha256(byte[] content) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(content));
        } catch (Exception e) {
            return null;
        }
    }

    private static String normalizePrefix(String prefix) {
        if (prefix == null || prefix.isBlank()) return "/uploads";
        String normalized = prefix.trim();
        if (!normalized.startsWith("/")) normalized = "/" + normalized;
        while (normalized.endsWith("/")) normalized = normalized.substring(0, normalized.length() - 1);
        return normalized;
    }

    private static String extensionOf(String filename) {
        int dot = filename.lastIndexOf('.');
        if (dot < 0 || dot == filename.length() - 1) return null;
        return filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private static String stripExtension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot > 0 ? filename.substring(0, dot) : filename;
    }
}
