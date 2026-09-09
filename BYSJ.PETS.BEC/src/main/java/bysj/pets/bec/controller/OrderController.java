package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 订单控制器
 */
@RestController
@RequestMapping("/orders")
public class OrderController {

    @Autowired
    private OrderService orderService;

    // 移除直接依赖JwtUtils，改用SecurityContext获取当前用户

    /**
     * 从购物车创建订单
     */
    @PostMapping("/create-from-cart")
    public Result<Map<String, Object>> createOrderFromCart(
            @RequestBody Map<String, Object> request) {
        // 从SecurityContext获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        // 处理订单创建
        Object productIdsObj = request.get("productIds");
        List<Long> productIds = new ArrayList<>();
        
        // 调试日志
        System.out.println("请求体: " + request);
        System.out.println("productIdsObj类型: " + (productIdsObj != null ? productIdsObj.getClass().getName() : "null"));
        
        // 处理不同类型的productIds
        if (productIdsObj instanceof List<?>) {
            // 直接处理List类型
            for (Object item : (List<?>) productIdsObj) {
                if (item instanceof Number) {
                    productIds.add(((Number) item).longValue());
                    System.out.println("添加商品ID(Number): " + item);
                } else if (item instanceof String) {
                    try {
                        long productId = Long.parseLong((String) item);
                        productIds.add(productId);
                        System.out.println("添加商品ID(String): " + item);
                    } catch (NumberFormatException e) {
                        System.out.println("忽略无法转换的商品ID: " + item);
                    }
                } else {
                    System.out.println("忽略未知类型的商品ID: " + item);
                }
            }
        } else if (productIdsObj instanceof Number) {
            // 处理单个Number类型
            long productId = ((Number) productIdsObj).longValue();
            productIds.add(productId);
            System.out.println("添加单个商品ID(Number): " + productId);
        } else if (productIdsObj instanceof String) {
            // 处理单个String类型
            try {
                long productId = Long.parseLong((String) productIdsObj);
                productIds.add(productId);
                System.out.println("添加单个商品ID(String): " + productIdsObj);
            } catch (NumberFormatException e) {
                System.out.println("忽略无法转换的单个商品ID: " + productIdsObj);
            }
        } else {
            System.out.println("productIdsObj不是预期的类型");
        }
        
        // 调试日志
        System.out.println("最终productIds: " + productIds);
        
        if (productIds.isEmpty()) {
            return Result.error("请选择要购买的商品");
        }

        // 提取租赁天数
        Integer leaseTerm = null;
        Object leaseTermObj = request.get("leaseTerm");
        if (leaseTermObj instanceof Number) {
            leaseTerm = ((Number) leaseTermObj).intValue();
        } else if (leaseTermObj instanceof String) {
            try {
                leaseTerm = Integer.parseInt((String) leaseTermObj);
            } catch (NumberFormatException e) {
                // 忽略无效的租赁天数，使用默认值
            }
        }

        // 提取数量参数
        Integer quantity = null;
        Object quantityObj = request.get("quantity");
        if (quantityObj instanceof Number) {
            quantity = ((Number) quantityObj).intValue();
        } else if (quantityObj instanceof String) {
            try {
                quantity = Integer.parseInt((String) quantityObj);
            } catch (NumberFormatException e) {
                // 忽略无效的数量，使用默认值
            }
        }

        // 调用服务层创建订单
        try {
            Map<String, Object> orderInfo = orderService.createOrderFromCart(username, productIds, quantity, leaseTerm);
            return Result.success("订单创建成功", orderInfo);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("创建订单失败，请稍后重试");
        }
    }

    /**
     * 获取订单列表
     */
    @GetMapping("/list")
    public Result<Map<String, Object>> getOrderList(
            @RequestParam(value = "type", required = false) String type,
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "orderNo", required = false) String orderNo,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        // 从SecurityContext获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        // 调用服务层获取订单列表
        Map<String, Object> orderList = orderService.getOrderList(username, type, status, orderNo, pageNum, pageSize);
        return Result.success("获取订单列表成功", orderList);
    }

    /**
     * 模拟支付订单
     */
    @PostMapping("/pay/{orderId}")
    public Result<Map<String, Object>> payOrder(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long orderId,
            @RequestBody Map<String, Object> request) {

        // 提取支付方式和地址ID
        String paymentMethod = (String) request.get("paymentMethod");
        Long addressId = null;
        if (request.get("addressId") != null) {
            if (request.get("addressId") instanceof Number) {
                addressId = ((Number) request.get("addressId")).longValue();
            } else if (request.get("addressId") instanceof String) {
                try {
                    addressId = Long.parseLong((String) request.get("addressId"));
                } catch (NumberFormatException e) {
                    return Result.error("无效的地址ID");
                }
            }
        }

        // 调用服务层模拟支付
        Map<String, Object> payResult = orderService.simulatePay(orderId, paymentMethod, addressId);
        return Result.success("支付成功", payResult);
    }
    
    /**
     * 获取单个订单详情（通过订单ID）
     */
    @GetMapping("/{orderId}")
    public Result<Map<String, Object>> getOrderDetail(
            @PathVariable Long orderId) {
        // 从SecurityContext获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        
        // 调用服务层获取订单详情
        try {
            Map<String, Object> orderDetail = orderService.getOrderDetail(username, orderId);
            return Result.success("获取订单详情成功", orderDetail);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("获取订单详情失败，请稍后重试");
        }
    }
    
    /**
     * 获取单个订单详情（通过订单号）
     */
    @GetMapping("/by-order-no/{orderNo}")
    public Result<Map<String, Object>> getOrderDetailByOrderNo(
            @PathVariable String orderNo) {
        // 从SecurityContext获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        
        // 调用服务层通过订单号获取订单详情
        try {
            Map<String, Object> orderDetail = orderService.getOrderDetailByOrderNo(username, orderNo);
            return Result.success("获取订单详情成功", orderDetail);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("获取订单详情失败，请稍后重试");
        }
    }
    
    /**
     * 取消订单
     */
    @PostMapping("/{orderId}/cancel")
    public Result<Object> cancelOrder(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long orderId) {
        
        // 调用服务层取消订单
        try {
            orderService.cancelOrder(orderId);
            return Result.success("订单取消成功");
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("取消订单失败，请稍后重试");
        }
    }
    
    /**
     * 获取临时订单信息（不创建正式订单）
     */
    @PostMapping("/temp")
    public Result<Map<String, Object>> getTempOrder(
            @RequestBody Map<String, Object> request) {
        // 从SecurityContext获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        // 提取商品ID列表
        Object productIdsObj = request.get("productIds");
        List<Long> productIds = new ArrayList<>();
        
        // 处理不同类型的productIds
        if (productIdsObj instanceof List<?>) {
            // 直接处理List类型
            for (Object item : (List<?>) productIdsObj) {
                if (item instanceof Number) {
                    productIds.add(((Number) item).longValue());
                } else if (item instanceof String) {
                    try {
                        productIds.add(Long.parseLong((String) item));
                    } catch (NumberFormatException e) {
                        // 忽略无效的商品ID
                    }
                }
            }
        } else if (productIdsObj instanceof Number) {
            // 处理单个Number类型
            productIds.add(((Number) productIdsObj).longValue());
        } else if (productIdsObj instanceof String) {
            // 处理单个String类型
            try {
                productIds.add(Long.parseLong((String) productIdsObj));
            } catch (NumberFormatException e) {
                // 忽略无效的商品ID
            }
        }

        if (productIds.isEmpty()) {
            return Result.error("请选择要购买的商品");
        }

        // 提取租赁天数
        Integer leaseTerm = null;
        Object leaseTermObj = request.get("leaseTerm");
        if (leaseTermObj instanceof Number) {
            leaseTerm = ((Number) leaseTermObj).intValue();
        } else if (leaseTermObj instanceof String) {
            try {
                leaseTerm = Integer.parseInt((String) leaseTermObj);
            } catch (NumberFormatException e) {
                // 忽略无效的租赁天数，使用默认值
            }
        }

        // 提取数量参数
        Integer quantity = null;
        Object quantityObj = request.get("quantity");
        if (quantityObj instanceof Number) {
            quantity = ((Number) quantityObj).intValue();
        } else if (quantityObj instanceof String) {
            try {
                quantity = Integer.parseInt((String) quantityObj);
            } catch (NumberFormatException e) {
                // 忽略无效的数量，使用默认值
            }
        }

        // 调用服务层获取临时订单信息
        try {
            Map<String, Object> tempOrderInfo = orderService.getTempOrder(username, productIds, quantity, leaseTerm);
            return Result.success("获取临时订单信息成功", tempOrderInfo);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("获取临时订单信息失败，请稍后重试");
        }
    }
    
    /**
     * 检查是否有未付款的订单
     */
    @PostMapping("/check-pending")
    public Result<Map<String, Object>> checkPendingOrder(
            @RequestBody Map<String, Object> request) {
        // 从SecurityContext获取当前登录用户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        
        // 提取商品ID列表
        Object productIdsObj = request.get("productIds");
        List<Long> productIdList = new ArrayList<>();
        
        // 处理不同类型的productIds
        if (productIdsObj instanceof List<?>) {
            // 直接处理List类型
            for (Object item : (List<?>) productIdsObj) {
                if (item instanceof Number) {
                    productIdList.add(((Number) item).longValue());
                } else if (item instanceof String) {
                    try {
                        productIdList.add(Long.parseLong((String) item));
                    } catch (NumberFormatException e) {
                        // 忽略无效的商品ID
                    }
                }
            }
        } else if (productIdsObj instanceof Number) {
            // 处理单个Number类型
            productIdList.add(((Number) productIdsObj).longValue());
        } else if (productIdsObj instanceof String) {
            // 处理单个String类型
            try {
                productIdList.add(Long.parseLong((String) productIdsObj));
            } catch (NumberFormatException e) {
                // 忽略无效的商品ID
            }
        }
        
        try {
            Map<String, Object> checkResult = orderService.checkPendingOrder(username, productIdList);
            return Result.success("检查未付款订单成功", checkResult);
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("检查未付款订单失败，请稍后重试");
        }
    }
    
    /**
     * 确认收货
     */
    @PostMapping("/{orderId}/confirm-receive")
    public Result<Object> confirmReceive(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long orderId) {
        
        // 调用服务层确认收货
        try {
            orderService.confirmReceive(orderId);
            return Result.success("确认收货成功");
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("确认收货失败，请稍后重试");
        }
    }
    
    /**
     * 归还租赁商品
     */
    @PostMapping("/{orderId}/return")
    public Result<Object> returnRental(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long orderId) {
        
        // 调用服务层归还租赁商品
        try {
            orderService.returnRental(orderId);
            return Result.success("归还成功");
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("归还失败，请稍后重试");
        }
    }
    
    /**
     * 商家确认归还
     */
    @PostMapping("/{orderId}/confirm-return")
    public Result<Object> confirmReturn(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long orderId) {
        
        // 调用服务层确认归还
        try {
            orderService.confirmReturn(orderId);
            return Result.success("确认归还成功");
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("确认归还失败，请稍后重试");
        }
    }
    
    /**
     * 商家发货
     */
    @PostMapping("/{orderId}/ship")
    public Result<Object> sellerShip(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long orderId) {
        
        // 调用服务层商家发货
        try {
            orderService.sellerShip(orderId);
            return Result.success("发货成功");
        } catch (RuntimeException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("发货失败，请稍后重试");
        }
    }

    /**
     * 更新超过14天的订单状态为已完成
     */
    @PostMapping("/update-overdue")
    public Result<Void> updateOverdueOrders() {
        try {
            orderService.updateOverdueOrdersToCompleted();
            return Result.success("更新成功");
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("更新失败，请稍后重试");
        }
    }
}
