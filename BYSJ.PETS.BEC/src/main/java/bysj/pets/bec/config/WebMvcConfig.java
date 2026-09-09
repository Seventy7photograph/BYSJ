package bysj.pets.bec.config;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${file.upload.path}")
    private String uploadPath;

    @Value("${file.access.prefix}")
    private String accessPrefix;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 映射：http://localhost:5173/images/xxx.jpg -> G:/study/AAA-BYSJ/images/xxx.jpg
//        registry.addResourceHandler("/images/**")
//                .addResourceLocations("file:" + uploadPath);

        // 配置图片资源访问路径映射
        // 将URL中以"/images/**"开头的请求映射到本地图片目录
        registry.addResourceHandler("/images/**")
                .addResourceLocations("file:G:/study/AAA-BYSJ/images/");
    }
}