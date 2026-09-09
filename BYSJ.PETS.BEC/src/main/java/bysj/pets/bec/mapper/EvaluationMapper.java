package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Evaluation;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 评价Mapper
 */
public interface EvaluationMapper extends BaseMapper<Evaluation> {

    /**
     * 根据商品ID获取评价列表
     */
    List<Evaluation> getEvaluationsByProductId(Long productId);

    /**
     * 根据订单ID获取评价
     */
    Evaluation getEvaluationByOrderId(Long orderId);

    /**
     * 根据用户ID获取评价列表
     */
    List<Evaluation> getEvaluationsByUserId(Long userId);
}
