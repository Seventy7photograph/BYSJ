package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.Evaluation;
import bysj.pets.bec.mapper.EvaluationMapper;
import bysj.pets.bec.service.EvaluationService;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 评价服务实现类
 */
@Service
public class EvaluationServiceImpl implements EvaluationService {

    @Autowired
    private EvaluationMapper evaluationMapper;

    @Override
    public Evaluation submitEvaluation(Evaluation evaluation) {
        // 设置默认值
        evaluation.setEvalStatus((byte) 1); // 正常展示
        evaluation.setCreateTime(LocalDateTime.now());
        evaluation.setUpdateTime(LocalDateTime.now());

        // 检查是否已经评价过
        Evaluation existingEvaluation = evaluationMapper.getEvaluationByOrderId(evaluation.getOrderId());
        if (existingEvaluation != null) {
            throw new RuntimeException("该订单已评价");
        }

        // 保存评价
        evaluationMapper.insert(evaluation);
        return evaluation;
    }

    @Override
    public List<Evaluation> getEvaluationsByProductId(Long productId) {
        return evaluationMapper.getEvaluationsByProductId(productId);
    }

    @Override
    public List<Evaluation> getEvaluationsByUserId(Long userId) {
        return evaluationMapper.getEvaluationsByUserId(userId);
    }

    @Override
    public boolean deleteEvaluation(Long evaluationId, Long userId) {
        // 检查评价是否存在且属于该用户
        Evaluation evaluation = evaluationMapper.selectById(evaluationId);
        if (evaluation == null || !evaluation.getUserId().equals(userId)) {
            return false;
        }

        // 软删除
        evaluation.setEvalStatus((byte) 0);
        evaluation.setUpdateTime(LocalDateTime.now());
        evaluationMapper.updateById(evaluation);
        return true;
    }

    @Override
    public Evaluation replyEvaluation(Long evaluationId, String replyContent, Long sellerId) {
        // 检查评价是否存在且属于该商家
        Evaluation evaluation = evaluationMapper.selectById(evaluationId);
        if (evaluation == null || !evaluation.getSellerId().equals(sellerId)) {
            throw new RuntimeException("无权回复该评价");
        }

        // 更新回复
        evaluation.setReplyContent(replyContent);
        evaluation.setReplyTime(LocalDateTime.now());
        evaluation.setUpdateTime(LocalDateTime.now());
        evaluationMapper.updateById(evaluation);
        return evaluation;
    }
}
