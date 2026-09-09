package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.service.RefundService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import java.util.Map;

@RestController
@RequestMapping("/refunds")
public class RefundController {

    @Autowired
    private RefundService refundService;

    /**
     * 申请退款
     */
    @PostMapping("/apply")
    public Result<Map<String, Object>> applyRefund(
            @RequestBody Map<String, Object> request) {
        try {
            // 从SecurityContext获取当前登录用户
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            Long orderId = Long.parseLong(request.get("orderId").toString());
            String refundReason = (String) request.get("refundReason");
            String refundDescription = (String) request.get("refundDescription");

            Map<String, Object> result = refundService.applyRefund(username, orderId, refundReason, refundDescription);
            return Result.success("退款申请提交成功", result);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("提交退款申请失败，请稍后重试");
        }
    }

    /**
     * 处理退款（模拟）
     */
    @PostMapping("/process")
    public Result<Map<String, Object>> processRefund(
            @RequestBody Map<String, Object> request) {
        try {
            Long refundId = Long.parseLong(request.get("refundId").toString());
            Integer status = Integer.parseInt(request.get("status").toString());

            Map<String, Object> result = refundService.processRefund(refundId, status);
            return Result.success("退款处理成功", result);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("处理退款失败，请稍后重试");
        }
    }

    /**
     * 获取订单的退款信息
     */
    @GetMapping("/order/{orderId}")
    public Result<Map<String, Object>> getRefundByOrderId(
            @PathVariable Long orderId) {
        try {
            // 从SecurityContext获取当前登录用户
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            var refund = refundService.getRefundByOrderId(orderId);
            Map<String, Object> result = new java.util.HashMap<>();
            result.put("refund", refund);
            return Result.success("获取退款信息成功", result);
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("获取退款信息失败，请稍后重试");
        }
    }

    /**
     * 检查订单是否可以退款
     */
    @GetMapping("/can-refund/{orderId}")
    public Result<Map<String, Object>> checkCanRefund(
            @PathVariable Long orderId) {
        try {
            // 从SecurityContext获取当前登录用户
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            boolean canRefund = refundService.canRefund(username, orderId);
            Map<String, Object> result = new java.util.HashMap<>();
            result.put("canRefund", canRefund);
            return Result.success("检查成功", result);
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("检查失败，请稍后重试");
        }
    }

    @Autowired
    private UserMapper userMapper;

    /**
     * 商家获取退款列表
     */
    @GetMapping("/merchant/list")
    public Result<Map<String, Object>> getMerchantRefundList(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String orderNo,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        try {
            // 获取当前登录的商家信息
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            // 根据用户名查询商家信息
            User user = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
            if (user == null) {
                return Result.error("商家不存在");
            }
            
            Long merchantId = user.getUserId();
            
            Map<String, Object> result = refundService.getMerchantRefundList(status, orderNo, merchantId, page, pageSize);
            return Result.success("获取退款列表成功", result);
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("获取退款列表失败，请稍后重试");
        }
    }
}