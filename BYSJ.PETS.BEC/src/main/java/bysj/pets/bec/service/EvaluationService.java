package bysj.pets.bec.service;

import bysj.pets.bec.entity.Evaluation;

import java.util.List;

/**
 * 评价服务接口
 */
public interface EvaluationService {

    /**
     * 提交评价
     */
    Evaluation submitEvaluation(Evaluation evaluation);

    /**
     * 根据商品ID获取评价列表
     */
    List<Evaluation> getEvaluationsByProductId(Long productId);

    /**
     * 根据用户ID获取评价列表
     */
    List<Evaluation> getEvaluationsByUserId(Long userId);

    /**
     * 删除评价
     */
    boolean deleteEvaluation(Long evaluationId, Long userId);

    /**
     * 商家回复评价
     */
    Evaluation replyEvaluation(Long evaluationId, String replyContent, Long sellerId);
}
