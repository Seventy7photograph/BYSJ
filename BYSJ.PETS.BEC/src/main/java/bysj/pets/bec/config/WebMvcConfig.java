package bysj.pets.bec.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 静态资源映射。
 *
 * 原实现把 /images/** 硬编码到了 `file:G:/study/AAA-BYSJ/images/` —— 另一个
 * 项目的目录，而且完全忽略了配置文件里的 file.upload.path。结果是：后端能"跑通"
 * 只是因为开发机上恰好存在那个旧目录，换台机器 /images 下所有图片全部 404。
 *
 * 现在只有一条映射：上传目录 → /uploads/**，路径来自 StorageProperties。
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final StorageProperties storageProperties;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path root = Paths.get(storageProperties.getRoot()).toAbsolutePath().normalize();
        if (!Files.exists(root)) {
            try {
                Files.createDirectories(root);
            } catch (Exception e) {
                log.warn("无法创建上传目录 {}，图片接口将不可用: {}", root, e.getMessage());
            }
        }

        String prefix = storageProperties.getUrlPrefix();
        if (prefix == null || prefix.isBlank()) {
            prefix = "/uploads";
        }
        if (!prefix.startsWith("/")) {
            prefix = "/" + prefix;
        }

        // 末尾必须是 /，否则 Spring 会把最后一段当文件名
        String location = root.toUri().toString();
        if (!location.endsWith("/")) {
            location = location + "/";
        }

        registry.addResourceHandler(prefix + "/**")
                .addResourceLocations(location)
                .setCachePeriod(60 * 60 * 24 * 30);

        log.info("上传目录映射：{} -> {}", prefix + "/**", location);
    }
}
