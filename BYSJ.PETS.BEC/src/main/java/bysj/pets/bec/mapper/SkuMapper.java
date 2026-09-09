package bysj.pets.bec.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import bysj.pets.bec.entity.Sku;

import java.util.List;
import java.util.Map;

public interface SkuMapper extends BaseMapper<Sku> {
    /**
     * 根据商品ID获取SKU列表
     */
    List<Map<String, Object>> selectSkuListByProductId(Long productId);

    /**
     * 根据SKU ID获取SKU信息
     */
    Map<String, Object> selectSkuById(Long skuId);

    /**
     * 插入SKU
     */
    int insertSku(Sku sku);

    /**
     * 更新SKU
     */
    int updateSku(Sku sku);

    /**
     * 删除SKU
     */
    int deleteSku(Long skuId);
}