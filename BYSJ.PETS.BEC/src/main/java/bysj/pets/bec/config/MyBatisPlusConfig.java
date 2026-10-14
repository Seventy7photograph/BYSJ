package bysj.pets.bec.config;


import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("bysj.pets.bec.mapper") // 确保包路径正确
public class MyBatisPlusConfig {

        /**
         * 新的分页插件,一缓和二缓遵循mybatis的规则,需要设置 MybatisConfiguration#useDeprecatedExecutor = false 避免缓存出现问题
         */
        @Bean
        public MybatisPlusInterceptor mybatisPlusInterceptor() {
                MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
                PaginationInnerInterceptor paginationInnerInterceptor = new PaginationInnerInterceptor(DbType.MYSQL);
                // 设置最大单页限制数量，默认 500 条，-1 不受限制
                paginationInnerInterceptor.setMaxLimit(-1L);
                // 开启 count 的 join 优化,只针对 left join !!!
                paginationInnerInterceptor.setOptimizeJoin(true);
                interceptor.addInnerInterceptor(paginationInnerInterceptor);
                return interceptor;
        }

}