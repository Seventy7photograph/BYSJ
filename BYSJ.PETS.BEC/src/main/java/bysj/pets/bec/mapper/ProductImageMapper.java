package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.ProductImage;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ProductImageMapper extends BaseMapper<ProductImage> {
    /**
     * 根据商品ID查询主图
     */
    ProductImage selectMainImageByProductId(@Param("productId") Long productId);
}
