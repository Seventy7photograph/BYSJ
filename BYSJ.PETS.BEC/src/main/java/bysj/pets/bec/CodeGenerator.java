package bysj.pets.bec;


import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.generator.FastAutoGenerator;
import com.baomidou.mybatisplus.generator.engine.FreemarkerTemplateEngine;
import com.baomidou.mybatisplus.generator.fill.Column;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class CodeGenerator {
    public static void main(String[] args) {
        // 1. 配置数据库连接信息（请替换为你的实际数据库信息）
        FastAutoGenerator.create(
                        "jdbc:mysql://localhost:3306/db_bysj_pets?useSSL=false&serverTimezone=UTC&characterEncoding=utf8",
                        "root",
                        "123456"
                )
                // 2. 全局配置
                .globalConfig(builder -> builder
                        .author("zsj") // 作者名
                        .outputDir(System.getProperty("user.dir") + "/src/main/java") // 代码输出目录
                        .commentDate("yyyy-MM-dd") // 注释日期格式
                )

                // 3. 包配置（生成代码的包结构）
                .packageConfig(builder -> builder
                        .parent("bysj.pets.bec") // 父包名
                        .entity("entity") // 实体类包名
                        .mapper("mapper") // Mapper接口包名
                       .service("service") // Service接口包名
                       .serviceImpl("service.impl") // Service实现类包名
                       .controller("controller") // 控制器包名
                )
                // 4. 策略配置
                .strategyConfig(builder -> builder
                        .addInclude("product") // 指定生成user表
                        .entityBuilder()
                        .enableLombok() // 启用Lombok注解
                        .addTableFills(
                                new Column("create_time", FieldFill.INSERT) // create_time字段自动填充（插入时）
                        )
                        .enableChainModel() // 启用链式调用
                        .build()
                )
                // 5. 模板引擎配置
                .templateEngine(new FreemarkerTemplateEngine())
                .execute();
    }

    // 注：由于已明确指定user表，getTables方法不再需要，可删除或保留（不影响）
    protected static List<String> getTables(String tables) {
        return "all".equals(tables) ? Collections.emptyList() : Arrays.asList(tables.split(","));
    }
}