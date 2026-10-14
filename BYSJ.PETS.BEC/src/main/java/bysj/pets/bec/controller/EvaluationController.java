package bysj.pets.bec.controller;

import bysj.pets.bec.entity.Evaluation;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.EvaluationService;
import bysj.pets.bec.config.Result;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 评价控制器
 */
@RestController
@RequestMapping("/evaluations")
public class EvaluationController {

    @Autowired
    private EvaluationService evaluationService;

    @Autowired
    private UserMapper userMapper;

    /**
     * 提交评价
     */
    @PostMapping
    public Result submitEvaluation(@RequestBody Evaluation evaluation, Authentication authentication) {
        // 获取当前用户信息
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        String username = userDetails.getUsername();
        
        // 根据用户名查询用户的真实userId
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }
        evaluation.setUserId(user.getUserId());

        // 设置默认的seller_id为1（可以根据实际情况从商品信息中获取）
        evaluation.setSellerId(1L);

        try {
            Evaluation submittedEvaluation = evaluationService.submitEvaluation(evaluation);
            return Result.success(submittedEvaluation);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }

    /**
     * 根据商品ID获取评价列表
     */
    @GetMapping("/product/{productId}")
    public Result getProductEvaluations(@PathVariable Long productId) {
        List<Evaluation> evaluations = evaluationService.getEvaluationsByProductId(productId);
        return Result.success(evaluations);
    }

    /**
     * 根据用户ID获取评价列表
     */
    @GetMapping("/user")
    public Result getUserEvaluations(Authentication authentication) {
        // 获取当前用户信息
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        String username = userDetails.getUsername();
        
        // 根据用户名查询用户的真实userId
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }
        Long userId = user.getUserId();

        List<Evaluation> evaluations = evaluationService.getEvaluationsByUserId(userId);
        return Result.success(evaluations);
    }

    /**
     * 删除评价
     */
    @DeleteMapping("/{evaluationId}")
    public Result deleteEvaluation(@PathVariable Long evaluationId, Authentication authentication) {
        // 获取当前用户信息
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        String username = userDetails.getUsername();
        
        // 根据用户名查询用户的真实userId
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("用户不存在");
        }
        Long userId = user.getUserId();

        boolean success = evaluationService.deleteEvaluation(evaluationId, userId);
        if (success) {
            return Result.success("删除成功");
        } else {
            return Result.error("删除失败");
        }
    }

    /**
     * 商家回复评价
     */
    @PostMapping("/{evaluationId}/reply")
    public Result replyEvaluation(@PathVariable Long evaluationId, @RequestParam String replyContent, Authentication authentication) {
        // 获取当前商家信息
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        String username = userDetails.getUsername();
        
        // 根据用户名查询商家的真实userId
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        if (user == null) {
            return Result.error("商家不存在");
        }
        Long sellerId = user.getUserId();

        try {
            Evaluation evaluation = evaluationService.replyEvaluation(evaluationId, replyContent, sellerId);
            return Result.success(evaluation);
        } catch (Exception e) {
            return Result.error(e.getMessage());
        }
    }
}
