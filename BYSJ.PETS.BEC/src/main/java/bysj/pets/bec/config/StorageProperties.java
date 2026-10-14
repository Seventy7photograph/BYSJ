package bysj.pets.bec.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 文件存储配置。
 *
 * 重构前项目里没有一份真正的存储配置：WebMvcConfig 把 /images/** 硬编码映射到
 * 另一个项目目录（G:/study/AAA-BYSJ/images/），FileUploadUtil 又写到
 * file.upload.path（另一个旧项目路径），还有一个从未被使用的 file.access.prefix。
 * 三处配置互相矛盾，换台机器或换个目录就必然坏。
 *
 * 现在只有一份：{@code file.storage.*}。存储根目录之外的任何路径都不需要知道。
 */
@Data
@Component
@ConfigurationProperties(prefix = "file.storage")
public class StorageProperties {

    /** 存储根目录。上传的文件按 yyyy/MM 分目录落在它下面。 */
    private String root = "./data/uploads";

    /** 对外 URL 前缀，与 WebMvcConfig 的资源映射保持一致。 */
    private String urlPrefix = "/uploads";

    /** 单文件大小上限（MB）。 */
    private long maxSizeMb = 10;

    /** 压缩后的最长边（像素）。0 表示不压缩。 */
    private int maxEdge = 1920;

    /** 压缩质量 0.0-1.0。 */
    private double quality = 0.85;

    /** 允许的扩展名。 */
    /** pdf 只在 shop_auth（营业执照/资质）下有意义，见 StorageService 的分支。 */
    private List<String> allowedExtensions = List.of("jpg", "jpeg", "png", "webp", "gif", "bmp", "pdf");

    /** 允许的业务类型，避免前端随便传一个字符串污染图库。 */
    private List<String> allowedBizTypes =
            List.of("product", "avatar", "shop_logo", "shop_auth", "evaluation", "notice");

    /** 允许 PDF 的业务类型。 */
    private List<String> pdfBizTypes = List.of("shop_auth");
}
