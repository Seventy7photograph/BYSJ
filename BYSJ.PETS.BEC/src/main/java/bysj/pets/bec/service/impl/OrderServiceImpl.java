package bysj.pets.bec.service.impl;

import bysj.pets.bec.dto.CartItemDTO;
import bysj.pets.bec.dto.OrderItemDTO;
import bysj.pets.bec.entity.Orders;
import bysj.pets.bec.entity.OrderItem;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.entity.UserAddress;
import bysj.pets.bec.entity.Cart;
import bysj.pets.bec.entity.Rental;
import bysj.pets.bec.mapper.*;
import bysj.pets.bec.entity.SysNotice;
import bysj.pets.bec.service.CartService;
import bysj.pets.bec.service.OrderService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

/**
 * 订单服务实现类
 */
@Service
public class OrderServiceImpl extends ServiceImpl<OrderMapper, Orders> implements OrderService {

    @Autowired
    private OrderMapper orderMapper;

    @Autowired
    private OrderItemMapper orderItemMapper;

    @Autowired
    private CartService cartService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private CartMapper cartMapper;
    
    @Autowired
    private UserAddressMapper userAddressMapper;

    @Autowired
    private RentalMapper rentalMapper;
    
    @Autowired
    private SysNoticeMapper sysNoticeMapper;

    /**
     * 从购物车创建订单，支持直接购买
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> createOrderFromCart(String username, List<Long> productIds, Integer quantity, Integer leaseTerm) {
        // 设置租赁天数默认值为1天
        if (leaseTerm == null || leaseTerm <= 0) {
            leaseTerm = 1;
        }
        // 设置数量默认值为1
        if (quantity == null || quantity <= 0) {
            quantity = 1;
        }
        // 1. 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            throw new RuntimeException("用户不存在");
        }

        // 2. 获取用户购物车中的所有商品
        List<CartItemDTO> cartItems = cartService.getUserCartItems(userId);
        Map<Long, CartItemDTO> cartItemMap = cartItems.stream()
                .collect(Collectors.toMap(CartItemDTO::getProductId, item -> item));
        
        // 3. 处理商品列表，支持直接购买
        List<CartItemDTO> selectedCartItems = new ArrayList<>();
        
        for (Long productId : productIds) {
            CartItemDTO cartItem = cartItemMap.get(productId);
            Product product = productMapper.selectById(productId);
            
            if (product != null) {
                if (cartItem != null) {
                    // 商品在购物车中，使用购物车中的数量
                    selectedCartItems.add(cartItem);
                } else {
                    // 直接购买，商品不在购物车中，创建临时购物车项
                    CartItemDTO tempItem = new CartItemDTO();
                    tempItem.setId(-1L); // 临时ID
                    tempItem.setProductId(product.getProductId());
                    tempItem.setProductName(product.getModel());
                    tempItem.setPrice(product.getPrice());
                    tempItem.setQuantity(quantity); // 使用传入的数量参数
                    tempItem.setStock(product.getStock());
                    tempItem.setSelected(true);
                    selectedCartItems.add(tempItem);
                }
            }
        }

        if (selectedCartItems.isEmpty()) {
            throw new RuntimeException("未找到商品信息");
        }

        // 3. 检查用户是否有收货地址
        List<UserAddress> userAddresses = userAddressMapper.selectList(
                new LambdaQueryWrapper<UserAddress>()
                        .eq(UserAddress::getUserId, userId)
        );
        
        // 如果用户没有地址，提示用户添加地址
        if (userAddresses.isEmpty()) {
            throw new RuntimeException("请先添加收货地址");
        }
        
        // 从用户地址列表中选择一个默认地址，如果没有默认地址则选择第一个
        UserAddress defaultAddress = userAddresses.stream()
                .filter(address -> address.getIsDefault() == 1)
                .findFirst()
                .orElse(userAddresses.get(0));
        
        // 4. 计算订单总金额和押金总额，同时检查商品类型和卖家
        BigDecimal totalAmount = BigDecimal.ZERO;
        BigDecimal totalDeposit = BigDecimal.ZERO;
        boolean hasRentalProducts = false;
        boolean hasNonRentalProducts = false;
        Long sellerId = null;
        
        // 检查是否包含不同类型的商品和不同卖家的商品
        for (CartItemDTO cartItem : selectedCartItems) {
            Product product = productMapper.selectById(cartItem.getProductId());
            if (product != null) {
                // 检查卖家一致性
                if (sellerId == null) {
                    sellerId = product.getSellerId();
                } else if (!sellerId.equals(product.getSellerId())) {
                    throw new RuntimeException("不允许同时购买不同卖家的商品");
                }
                
                if (product.getProductType() == 3) {
                    hasRentalProducts = true;
                    // 计算押金（商品原价的10%）
                    BigDecimal deposit = product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)).multiply(BigDecimal.valueOf(cartItem.getQuantity()));
                    totalDeposit = totalDeposit.add(deposit);
                    // 租赁商品，租金 = 单价 * 租赁天数
                    totalAmount = totalAmount.add(product.getPrice().multiply(BigDecimal.valueOf(leaseTerm)).multiply(BigDecimal.valueOf(cartItem.getQuantity())));
                } else {
                    hasNonRentalProducts = true;
                    // 普通商品，总价 = 单价 * 数量
                    totalAmount = totalAmount.add(product.getPrice().multiply(BigDecimal.valueOf(cartItem.getQuantity())));
                }
            }
        }
        
        // 总金额 = 商品总价 + 押金总额
        totalAmount = totalAmount.add(totalDeposit);
        
        // 不允许混合不同类型的商品下单
        if (hasRentalProducts && hasNonRentalProducts) {
            throw new RuntimeException("不允许同时购买租赁商品和普通商品");
        }
        
        // 5. 创建订单
        Orders order = new Orders();
        order.setOrderNo(generateOrderNo());
        order.setUserId(userId);
        order.setSellerId(sellerId);
        // 设置地址信息 - 保存完整地址快照
        order.setAddressId(defaultAddress.getAddressId());
        order.setRecipient(defaultAddress.getRecipient());
        order.setPhone(defaultAddress.getPhone());
        order.setProvince(defaultAddress.getProvince());
        order.setCity(defaultAddress.getCity());
        order.setDistrict(defaultAddress.getDistrict());
        order.setDetail(defaultAddress.getDetail());
        order.setTotalAmount(totalAmount);
        order.setShippingFee(BigDecimal.ZERO); // 暂免运费
        order.setPayAmount(totalAmount);
        order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.PENDING_PAYMENT.getCode()); // 待支付
        order.setPaymentMethod("online"); // 在线支付
        order.setCreateTime(LocalDateTime.now());
        order.setUpdateTime(LocalDateTime.now());

        // 保存订单
        baseMapper.insert(order);
        System.out.println("订单保存成功，订单ID: " + order.getOrderId());
        
        // 生成订单创建消息
        createOrderStatusMessage(userId, order.getOrderId(), order.getOrderNo(), order.getOrderStatus());

        // 6. 创建订单项
        List<OrderItem> orderItems = new ArrayList<>();
        for (CartItemDTO cartItem : selectedCartItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.setOrderId(order.getOrderId());
            orderItem.setProductId(cartItem.getProductId());
            orderItem.setQuantity(cartItem.getQuantity());
            
            // 查询商品详情
            Product product = productMapper.selectById(cartItem.getProductId());
            if (product != null) {
                orderItem.setUnitPrice(product.getPrice());
                
                // 根据商品类型设置押金和租赁天数
                if (product.getProductType() == 3) {
                    // 租赁商品，设置押金（商品原价的10%）
                    orderItem.setDeposit(product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)));
                    // 设置租赁天数
                    orderItem.setLeaseTerm(leaseTerm);
                } else {
                    // 普通商品，暂免押金
                    orderItem.setDeposit(BigDecimal.ZERO);
                }
            } else {
                orderItem.setUnitPrice(cartItem.getPrice());
                orderItem.setDeposit(BigDecimal.ZERO);
            }
            
            orderItem.setFreight(BigDecimal.ZERO); // 暂免运费
            orderItem.setItemStatus(0); // 待履约
            orderItem.setCreateTime(LocalDateTime.now());
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItems.add(orderItem);
        }

        // 保存订单项
        if (!orderItemMapper.insertBatch(orderItems)) {
            throw new RuntimeException("创建订单项失败");
        }
        
        // 7. 如果是租赁商品，创建租赁订单记录
        if (hasRentalProducts) {
            // 创建租赁记录
            Rental rental = new Rental();
            rental.setOrderId(order.getOrderId());
            
            // 设置起租时间和到期时间
            LocalDateTime now = LocalDateTime.now();
            rental.setStartDate(now);
            rental.setEndDate(now.plusDays(leaseTerm));
            
            // 设置租期
            rental.setLeaseTerm(leaseTerm);
            
            // 计算总租金（订单总金额减去押金）
            BigDecimal totalRentalFee = totalAmount.subtract(totalDeposit);
            rental.setRent(totalRentalFee);
            
            // 默认取货和归还方式：2 - 快递配送/自行寄送
            rental.setPickupType(2);
            rental.setReturnType(2);
            
            // 默认归还状态：0 - 未归还
            rental.setReturnStatus(0);
            
            // 默认续租状态：0 - 无续租
            rental.setRenewStatus(0);
            
            // 默认逾期天数：0
            rental.setOverdueDays(0);
            
            // 初始状态图：暂时使用空JSON数组
            rental.setInitialImg("[]");
            
            // 设置创建时间和更新时间
            rental.setCreateTime(now);
            rental.setUpdateTime(now);
            
            // 保存租赁记录
            if (rentalMapper.insert(rental) <= 0) {
                throw new RuntimeException("创建租赁记录失败");
            }
            
            System.out.println("创建租赁记录成功，租赁记录ID: " + rental.getRentalId());
        }

        // 8. 返回订单信息
        Map<String, Object> result = new HashMap<>();
        result.put("orderId", order.getOrderId());
        result.put("orderNo", order.getOrderNo());
        result.put("totalAmount", order.getTotalAmount());
        result.put("hasRentalProducts", hasRentalProducts);
        return result;
    }
    
    /**
     * 获取临时订单信息（不创建正式订单）
     */
    @Override
    public Map<String, Object> getTempOrder(String username, List<Long> productIds, Integer quantity, Integer leaseTerm) {
        // 1. 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            throw new RuntimeException("用户不存在");
        }
        
        // 设置租赁天数默认值为1天
        if (leaseTerm == null || leaseTerm <= 0) {
            leaseTerm = 1;
        }
        // 设置数量默认值为1
        if (quantity == null || quantity <= 0) {
            quantity = 1;
        }
        
        // 2. 查询商品信息，支持直接购买（商品不在购物车中的情况）
        List<CartItemDTO> selectedCartItems = new ArrayList<>();
        
        for (Long productId : productIds) {
            // 先尝试从购物车中查询
            Cart cartItem = cartMapper.selectOne(
                    new LambdaQueryWrapper<Cart>()
                            .eq(Cart::getUserId, userId)
                            .eq(Cart::getProductId, productId)
            );
            
            // 查询商品详情
            Product product = productMapper.selectById(productId);
            if (product != null) {
                // 转换为DTO
                CartItemDTO cartItemDTO = new CartItemDTO();
                if (cartItem != null) {
                    cartItemDTO.setId(cartItem.getCartId());
                    cartItemDTO.setQuantity(cartItem.getQuantity());
                } else {
                    // 直接购买，商品不在购物车中，创建临时购物车项
                    cartItemDTO.setId(-1L); // 临时ID
                    cartItemDTO.setQuantity(quantity); // 使用传入的数量参数
                }
                cartItemDTO.setProductId(product.getProductId());
                cartItemDTO.setProductName(product.getModel());
                
                // 查询商品图片
                String productImage = productMapper.selectMainImageByProductId(productId);
                cartItemDTO.setProductImage(productImage);
                
                cartItemDTO.setPrice(product.getPrice());
                cartItemDTO.setStock(product.getStock());
                cartItemDTO.setSelected(true);
                selectedCartItems.add(cartItemDTO);
            }
        }
        
        if (selectedCartItems.isEmpty()) {
            throw new RuntimeException("未找到商品信息");
        }

        // 3. 计算订单总金额和押金总额，同时检查卖家一致性
        BigDecimal totalAmount = BigDecimal.ZERO;
        BigDecimal totalDeposit = BigDecimal.ZERO;
        Long sellerId = null;
        
        for (CartItemDTO cartItem : selectedCartItems) {
            Product product = productMapper.selectById(cartItem.getProductId());
            if (product != null) {
                // 检查卖家一致性
                if (sellerId == null) {
                    sellerId = product.getSellerId();
                } else if (!sellerId.equals(product.getSellerId())) {
                    throw new RuntimeException("不允许同时购买不同卖家的商品");
                }
                
                if (product.getProductType() == 3) {
                    // 计算押金（商品原价的10%）
                    BigDecimal deposit = product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)).multiply(BigDecimal.valueOf(cartItem.getQuantity()));
                    totalDeposit = totalDeposit.add(deposit);
                    // 租赁商品，租金 = 单价 * 租赁天数
                    totalAmount = totalAmount.add(product.getPrice().multiply(BigDecimal.valueOf(leaseTerm)).multiply(BigDecimal.valueOf(cartItem.getQuantity())));
                } else {
                    // 普通商品，总价 = 单价 * 数量
                    totalAmount = totalAmount.add(product.getPrice().multiply(BigDecimal.valueOf(cartItem.getQuantity())));
                }
            } else {
                // 商品不存在，使用DTO中的价格
                totalAmount = totalAmount.add(cartItem.getPrice().multiply(BigDecimal.valueOf(cartItem.getQuantity())));
            }
        }
        
        // 总金额 = 商品总价 + 押金总额
        totalAmount = totalAmount.add(totalDeposit);

        // 4. 准备订单项DTO列表
        List<OrderItemDTO> orderItemDTOs = new ArrayList<>();
        for (CartItemDTO cartItem : selectedCartItems) {
            OrderItemDTO dto = new OrderItemDTO();
            dto.setProductId(cartItem.getProductId());
            dto.setProductName(cartItem.getProductName());
            dto.setProductImage(cartItem.getProductImage());
            dto.setUnitPrice(cartItem.getPrice());
            dto.setQuantity(cartItem.getQuantity());
            
            // 查询商品详情
            Product product = productMapper.selectById(cartItem.getProductId());
            if (product != null) {
                dto.setProductType(product.getProductType());
                dto.setCondition(product.getCondition());
                // 查询品牌名称
                String brandName = productMapper.selectBrandNameByProductId(cartItem.getProductId());
                dto.setBrandName(brandName);
                // 查询商品规格
                String specifications = productMapper.selectSpecificationsByProductId(cartItem.getProductId());
                dto.setSpecifications(specifications);
                // 设置押金（商品原价的10%）
                if (product.getProductType() == 3) {
                    dto.setDeposit(product.getOriginalPrice().multiply(BigDecimal.valueOf(0.1)));
                    dto.setLeaseTerm(leaseTerm); // 设置租赁天数
                } else {
                    dto.setDeposit(BigDecimal.ZERO);
                }
            }
            
            orderItemDTOs.add(dto);
        }
        
        // 5. 返回临时订单信息，不保存到数据库
        Map<String, Object> result = new HashMap<>();
        result.put("totalAmount", totalAmount);
        result.put("shippingFee", BigDecimal.ZERO); // 暂免运费
        result.put("orderItems", orderItemDTOs);
        return result;
    }

    /**
     * 获取用户订单列表
     */
    @Override
    public Map<String, Object> getOrderList(String username, String type, String status, String orderNo, Integer pageNum, Integer pageSize) {
        // 1. 根据用户名获取用户信息
        User user = userMapper.selectUserByUsername(username);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        
        Long userId = user.getUserId();
        Byte userType = user.getUserType();

        // 2. 根据用户类型和类型过滤查询订单列表
        Page<Orders> page = new Page<>(pageNum, pageSize);
        IPage<Orders> orderPage;
        
        if (userType == 2) {
            // 商家用户，查询自己销售的订单
            if (type != null && ("new".equals(type) || "used".equals(type) || "rental".equals(type))) {
                orderPage = orderMapper.selectSellerOrdersByType(page, userId, type);
            } else {
                orderPage = orderMapper.selectSellerOrders(page, userId);
            }
        } else {
            // 个人用户或管理员，查询自己购买的订单
            if (type != null && ("new".equals(type) || "used".equals(type) || "rental".equals(type))) {
                orderPage = orderMapper.selectUserOrdersByType(page, userId, type);
            } else {
                orderPage = orderMapper.selectUserOrders(page, userId);
            }
        }

        // 3. 查询每个订单的订单项，并转换为OrderItemDTO
        List<Orders> orders = orderPage.getRecords();
        List<Map<String, Object>> orderList = new ArrayList<>();
        
        for (Orders order : orders) {
            List<OrderItem> orderItems = orderItemMapper.selectByOrderId(order.getOrderId());
            List<OrderItemDTO> orderItemDTOs = new ArrayList<>();
            
            // 构建订单项DTO列表
            for (OrderItem orderItem : orderItems) {
                OrderItemDTO dto = new OrderItemDTO();
                // 复制基本信息
                dto.setItemId(orderItem.getItemId());
                dto.setOrderId(orderItem.getOrderId());
                dto.setProductId(orderItem.getProductId());
                dto.setUnitPrice(orderItem.getUnitPrice());
                dto.setQuantity(orderItem.getQuantity());
                dto.setItemStatus(orderItem.getItemStatus());
                dto.setDeposit(orderItem.getDeposit());
                
                // 查询商品信息
                Product product = productMapper.selectById(orderItem.getProductId());
                if (product != null) {
                    dto.setProductName(product.getModel());
                    dto.setProductType(product.getProductType());
                    dto.setCondition(product.getCondition());
                    dto.setUnitPrice(product.getPrice());
                }
                
                // 查询商品图片
                String productImage = productMapper.selectMainImageByProductId(orderItem.getProductId());
                dto.setProductImage(productImage);
                
                // 查询商品规格
                String specifications = productMapper.selectSpecificationsByProductId(orderItem.getProductId());
                dto.setSpecifications(specifications);
                
                // 查询品牌名称
                String brandName = productMapper.selectBrandNameByProductId(orderItem.getProductId());
                dto.setBrandName(brandName);
                
                orderItemDTOs.add(dto);
            }
            
            // 检查订单状态是否匹配
            boolean isMatchStatus = true;
            if (status != null && !status.isEmpty()) {
                try {
                    Integer orderStatus = Integer.parseInt(status);
                    isMatchStatus = order.getOrderStatus().equals(orderStatus);
                } catch (NumberFormatException e) {
                    isMatchStatus = false;
                }
            }
            
            // 检查订单号是否匹配
            boolean isMatchOrderNo = true;
            if (orderNo != null && !orderNo.isEmpty()) {
                isMatchOrderNo = order.getOrderNo().contains(orderNo);
            }
            
            // 如果匹配所有条件，则添加到结果列表
            if (isMatchStatus && isMatchOrderNo) {
                // 查询用户名
                String userName = userMapper.selectUsernameById(order.getUserId());
                
                // 构建订单数据
                Map<String, Object> orderData = new HashMap<>();
                orderData.put("orderId", order.getOrderId());
                orderData.put("orderNo", order.getOrderNo());
                orderData.put("userName", userName);
                orderData.put("totalAmount", order.getTotalAmount());
                orderData.put("orderStatus", order.getOrderStatus());
                orderData.put("createTime", order.getCreateTime());
                orderData.put("customerName", order.getRecipient());
                // 添加订单项信息
                orderData.put("items", orderItemDTOs);
                
                orderList.add(orderData);
            }
        }

        // 4. 返回结果，使用前端期望的格式（list和total）
        Map<String, Object> result = new HashMap<>();
        result.put("list", orderList);
        result.put("total", orderPage.getTotal());
        return result;
    }

    /**
     * 模拟支付订单
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> simulatePay(Long orderId, String paymentMethod, Long addressId) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }

        // 2. 更新订单状态、支付方式、地址、支付时间和支付流水号
        order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.PAID.getCode()); // 已支付
        if (paymentMethod != null) {
            order.setPaymentMethod(paymentMethod);
        }
        if (addressId != null) {
            order.setAddressId(addressId);
        }
        // 设置支付时间
        LocalDateTime payTime = LocalDateTime.now();
        order.setPayTime(payTime);
        // 设置支付流水号（使用时间戳和订单ID生成）
        String transactionId = "TXN" + System.currentTimeMillis() + "_" + orderId;
        order.setTransactionId(transactionId);
        order.setUpdateTime(payTime);
        if (!updateById(order)) {
            throw new RuntimeException("更新订单状态失败");
        }
        
        // 生成订单支付成功消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), order.getOrderStatus());

        // 3. 更新订单项状态，同时检查商品类型
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        boolean hasRentalProducts = false;
        
        for (OrderItem orderItem : orderItems) {
            Product product = productMapper.selectById(orderItem.getProductId());
            if (product != null) {
                if (product.getProductType() == 3) {
                    hasRentalProducts = true;
                    // 租赁商品支付后处理
                    orderItem.setItemStatus(1); // 已出租
                    // 更新商品库存（减少可租数量）
                    product.setStock(product.getStock() - orderItem.getQuantity());
                    productMapper.updateById(product);
                } else {
                    // 普通商品支付后处理
                    orderItem.setItemStatus(1); // 已发货
                    // 更新商品库存
                    product.setStock(product.getStock() - orderItem.getQuantity());
                    productMapper.updateById(product);
                }
            } else {
                orderItem.setItemStatus(1); // 默认已处理
            }
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
        
        // 4. 从购物车中移除已购买的商品
        // 获取用户ID
        Long userId = order.getUserId();
        // 从订单项中提取商品ID列表
        List<Long> productIds = orderItems.stream()
                .map(OrderItem::getProductId)
                .collect(Collectors.toList());
        // 从购物车中移除这些商品
        cartService.batchRemoveCartItems(userId, productIds);
        
        // 5. 如果是租赁商品，更新租赁记录状态
        if (hasRentalProducts) {
            // 查找对应的租赁记录
            LambdaQueryWrapper<Rental> queryWrapper = new LambdaQueryWrapper<>();
            queryWrapper.eq(Rental::getOrderId, orderId);
            Rental rental = rentalMapper.selectOne(queryWrapper);
            
            if (rental != null) {
                // 更新租赁记录的更新时间
                rental.setUpdateTime(LocalDateTime.now());
                // 保存更新
                rentalMapper.updateById(rental);
                System.out.println("更新租赁记录成功，租赁记录ID: " + rental.getRentalId());
            }
        }

        // 6. 返回支付结果
        Map<String, Object> result = new HashMap<>();
        result.put("orderId", orderId);
        result.put("paymentId", orderId); // 暂时使用orderId作为paymentId
        result.put("orderStatus", order.getOrderStatus());
        result.put("isRentalOrder", hasRentalProducts);
        result.put("payTime", LocalDateTime.now());
        return result;
    }

    /**
     * 生成订单号
     * 格式：ORD + 时间戳（yyMMddHHmmssSSS） + 进程ID + 自增序列号
     */
    private String generateOrderNo() {
        // 使用线程安全的序列号生成
        String timestamp = new SimpleDateFormat("yyMMddHHmmssSSS").format(new Date());
        // 获取进程ID
        String processId = String.format("%03d", ProcessHandle.current().pid() % 1000);
        // 简单的自增序列号（单JVM内线程安全）
        long sequence = this.sequence.incrementAndGet();
        String sequenceStr = String.format("%04d", sequence % 10000);
        
        return "ORD" + timestamp + processId + sequenceStr;
    }
    
    // 自增序列号，初始值为0，线程安全
    private final AtomicLong sequence = new AtomicLong(0);
    
    /**
     * 生成订单状态变更消息
     */
    private void createOrderStatusMessage(Long userId, Long orderId, String orderNo, Integer status) {
        SysNotice notice = new SysNotice();
        notice.setUserId(userId);
        notice.setCreateTime(LocalDateTime.now());
        notice.setIsRead((byte) 0);
        notice.setNoticeStatus((byte) 0);
        notice.setNoticeType((byte) 1); // 订单相关消息
        
        String content = "";
        switch (status) {
            case 0: // 待支付
                content = "您的订单 " + orderNo + " 已创建，等待支付";
                break;
            case 1: // 已支付
                content = "您的订单 " + orderNo + " 支付成功";
                break;
            case 2: // 已发货
                content = "您的订单 " + orderNo + " 已发货";
                break;
            case 3: // 已完成
                content = "您的订单 " + orderNo + " 已完成";
                break;
            case 4: // 已取消
                content = "您的订单 " + orderNo + " 已取消";
                break;
            case 5: // 退款中
                content = "您的订单 " + orderNo + " 正在退款处理中";
                break;
            case 6: // 退款成功
                content = "您的订单 " + orderNo + " 退款成功";
                break;
            case 7: // 退款失败
                content = "您的订单 " + orderNo + " 退款失败";
                break;
            case 8: // 租赁中
                content = "您的租赁订单 " + orderNo + " 已确认收货，开始租赁";
                break;
            case 9: // 归还中
                content = "您的租赁订单 " + orderNo + " 正在归还中";
                break;
            default:
                content = "您的订单 " + orderNo + " 状态发生变更";
        }
        
        notice.setContent(content);
        sysNoticeMapper.insert(notice);
    }
    
    /**
     * 获取单个订单详情
     */
    @Override
    public Map<String, Object> getOrderDetail(String username, Long orderId) {
        // 1. 根据用户名获取用户信息
        User user = userMapper.selectUserByUsername(username);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        
        Long userId = user.getUserId();
        Byte userType = user.getUserType();
        
        // 2. 查询订单信息
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 3. 验证订单是否属于该用户（根据用户类型）
        if (userType == 2) {
            // 商家用户，验证订单的seller_id是否等于用户ID
            if (!order.getSellerId().equals(userId)) {
                throw new RuntimeException("无权访问该订单");
            }
        } else {
            // 个人用户或管理员，验证订单的user_id是否等于用户ID
            if (!order.getUserId().equals(userId)) {
                throw new RuntimeException("无权访问该订单");
            }
        }
        
        // 4. 查询订单项信息
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        
        // 5. 转换订单项为DTO，添加完整的商品信息
        List<OrderItemDTO> orderItemDTOs = new ArrayList<>();
        for (OrderItem orderItem : orderItems) {
            OrderItemDTO dto = new OrderItemDTO();
            // 复制订单项基本信息
            BeanUtils.copyProperties(orderItem, dto);
            
            // 查询商品信息
            Product product = productMapper.selectById(orderItem.getProductId());
            if (product != null) {
                // 设置商品名称
                dto.setProductName(product.getModel());
                // 设置商品类型和成色
                dto.setProductType(product.getProductType());
                dto.setCondition(product.getCondition());
                // 设置商品价格
                dto.setUnitPrice(product.getPrice());
            }
            
            // 查询商品图片
            String productImage = productMapper.selectMainImageByProductId(orderItem.getProductId());
            dto.setProductImage(productImage);
            
            // 查询商品规格
            String specifications = productMapper.selectSpecificationsByProductId(orderItem.getProductId());
            dto.setSpecifications(specifications);
            
            // 查询品牌名称
            String brandName = productMapper.selectBrandNameByProductId(orderItem.getProductId());
            dto.setBrandName(brandName);
            
            orderItemDTOs.add(dto);
        }
        
        // 6. 构建返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("order", order);
        result.put("orderItems", orderItemDTOs);
        
        return result;
    }
    
    /**
     * 通过订单号获取单个订单详情
     */
    @Override
    public Map<String, Object> getOrderDetailByOrderNo(String username, String orderNo) {
        // 1. 根据用户名获取用户信息
        User user = userMapper.selectUserByUsername(username);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        
        Long userId = user.getUserId();
        Byte userType = user.getUserType();
        
        // 2. 根据订单号查询订单
        LambdaQueryWrapper<Orders> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Orders::getOrderNo, orderNo);
        Orders order = getOne(queryWrapper);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 3. 验证订单是否属于该用户（根据用户类型）
        if (userType == 2) {
            // 商家用户，验证订单的seller_id是否等于用户ID
            if (!order.getSellerId().equals(userId)) {
                throw new RuntimeException("无权访问该订单");
            }
        } else {
            // 个人用户或管理员，验证订单的user_id是否等于用户ID
            if (!order.getUserId().equals(userId)) {
                throw new RuntimeException("无权访问该订单");
            }
        }
        
        // 4. 查询订单项信息
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(order.getOrderId());
        
        // 5. 转换订单项为DTO，添加完整的商品信息
        List<OrderItemDTO> orderItemDTOs = new ArrayList<>();
        for (OrderItem orderItem : orderItems) {
            OrderItemDTO dto = new OrderItemDTO();
            // 复制订单项基本信息
            BeanUtils.copyProperties(orderItem, dto);
            
            // 查询商品信息
            Product product = productMapper.selectById(orderItem.getProductId());
            if (product != null) {
                // 设置商品名称
                dto.setProductName(product.getModel());
                // 设置商品类型和成色
                dto.setProductType(product.getProductType());
                dto.setCondition(product.getCondition());
                // 设置商品价格
                dto.setUnitPrice(product.getPrice());
            }
            
            // 查询商品图片
            String productImage = productMapper.selectMainImageByProductId(orderItem.getProductId());
            dto.setProductImage(productImage);
            
            // 查询商品规格
            String specifications = productMapper.selectSpecificationsByProductId(orderItem.getProductId());
            dto.setSpecifications(specifications);
            
            // 查询品牌名称
            String brandName = productMapper.selectBrandNameByProductId(orderItem.getProductId());
            dto.setBrandName(brandName);
            
            orderItemDTOs.add(dto);
        }
        
        // 6. 构建返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("order", order);
        result.put("orderItems", orderItemDTOs);
        
        return result;
    }
    
    /**
     * 取消订单
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelOrder(Long orderId) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 2. 检查订单状态是否可取消
        if (order.getOrderStatus() != bysj.pets.bec.entity.enumtype.OrderStatus.PENDING_PAYMENT.getCode()) {
            throw new RuntimeException("只有待付款订单可以取消");
        }
        
        // 3. 更新订单状态为已取消
        order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.CANCELLED.getCode());
        order.setUpdateTime(LocalDateTime.now());
        if (!updateById(order)) {
            throw new RuntimeException("取消订单失败");
        }
        
        // 生成订单取消消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), order.getOrderStatus());
        
        // 4. 更新订单项状态
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        for (OrderItem orderItem : orderItems) {
            orderItem.setItemStatus(4); // 已取消
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
    }
    
    /**
     * 商家发货
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void sellerShip(Long orderId) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 2. 检查订单状态是否可发货
        if (order.getOrderStatus() != bysj.pets.bec.entity.enumtype.OrderStatus.PAID.getCode()) {
            throw new RuntimeException("只有已支付订单可以发货");
        }
        
        // 3. 更新订单状态为已发货
        order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.SHIPPED.getCode());
        order.setUpdateTime(LocalDateTime.now());
        if (!updateById(order)) {
            throw new RuntimeException("发货失败");
        }
        
        // 生成订单发货消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), order.getOrderStatus());
        
        // 4. 更新订单项状态
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        for (OrderItem orderItem : orderItems) {
            orderItem.setItemStatus(2); // 已发货
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
    }
    
    /**
     * 确认收货
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void confirmReceive(Long orderId) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 2. 检查订单状态是否可确认收货
        if (order.getOrderStatus() != bysj.pets.bec.entity.enumtype.OrderStatus.SHIPPED.getCode()) {
            throw new RuntimeException("只有已发货订单可以确认收货");
        }
        
        // 3. 检查是否为租赁订单
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        boolean isRentalOrder = false;
        for (OrderItem orderItem : orderItems) {
            Product product = productMapper.selectById(orderItem.getProductId());
            if (product != null && product.getProductType() == 3) {
                isRentalOrder = true;
                break;
            }
        }
        
        // 4. 根据订单类型更新状态
        if (isRentalOrder) {
            // 租赁订单，更新为租赁中状态
            order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.RENTING.getCode());
        } else {
            // 普通订单，更新为已完成状态
            order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.COMPLETED.getCode());
        }
        order.setUpdateTime(LocalDateTime.now());
        if (!updateById(order)) {
            throw new RuntimeException("确认收货失败");
        }
        
        // 生成订单确认收货消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), order.getOrderStatus());
        
        // 5. 更新订单项状态
        for (OrderItem orderItem : orderItems) {
            if (isRentalOrder) {
                orderItem.setItemStatus(4); // 租赁中
            } else {
                orderItem.setItemStatus(3); // 已完成
            }
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
    }
    
    /**
     * 归还租赁商品
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void returnRental(Long orderId) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 2. 检查订单状态是否可归还
        if (order.getOrderStatus() != bysj.pets.bec.entity.enumtype.OrderStatus.RENTING.getCode()) {
            throw new RuntimeException("只有租赁中订单可以归还");
        }
        
        // 3. 更新订单状态为归还中
        order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.RETURNING.getCode());
        order.setUpdateTime(LocalDateTime.now());
        if (!updateById(order)) {
            throw new RuntimeException("归还失败");
        }
        
        // 生成订单归还消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), order.getOrderStatus());
        
        // 4. 更新订单项状态
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        for (OrderItem orderItem : orderItems) {
            orderItem.setItemStatus(5); // 归还中
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
        
        // 5. 更新租赁记录
        LambdaQueryWrapper<Rental> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Rental::getOrderId, orderId);
        Rental rental = rentalMapper.selectOne(queryWrapper);
        if (rental != null) {
            rental.setReturnStatus(1); // 归还中
            rental.setUpdateTime(LocalDateTime.now());
            rentalMapper.updateById(rental);
        }
    }
    
    /**
     * 商家确认归还
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void confirmReturn(Long orderId) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 2. 检查订单状态是否可确认归还
        if (order.getOrderStatus() != bysj.pets.bec.entity.enumtype.OrderStatus.RETURNING.getCode()) {
            throw new RuntimeException("只有归还中订单可以确认归还");
        }
        
        // 3. 更新订单状态为已完成
        order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.COMPLETED.getCode());
        order.setUpdateTime(LocalDateTime.now());
        if (!updateById(order)) {
            throw new RuntimeException("确认归还失败");
        }
        
        // 生成订单完成消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), order.getOrderStatus());
        
        // 4. 更新订单项状态
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        for (OrderItem orderItem : orderItems) {
            orderItem.setItemStatus(3); // 已完成
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
        
        // 5. 更新租赁记录
        LambdaQueryWrapper<Rental> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Rental::getOrderId, orderId);
        Rental rental = rentalMapper.selectOne(queryWrapper);
        if (rental != null) {
            rental.setReturnStatus(2); // 已归还
            rental.setUpdateTime(LocalDateTime.now());
            rentalMapper.updateById(rental);
        }
        
        // 6. 恢复商品库存
        for (OrderItem orderItem : orderItems) {
            Product product = productMapper.selectById(orderItem.getProductId());
            if (product != null) {
                product.setStock(product.getStock() + orderItem.getQuantity());
                productMapper.updateById(product);
            }
        }
    }
    
    /**
     * 检查是否有未付款的订单
     */
    @Override
    public Map<String, Object> checkPendingOrder(String username, List<Long> productIds) {
        Map<String, Object> result = new HashMap<>();
        result.put("hasPendingOrder", false);
        result.put("orderId", null);
        result.put("orderInfoMatches", false);
        
        // 1. 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            throw new RuntimeException("用户不存在");
        }
        
        // 2. 查询用户所有待支付订单
        List<Orders> pendingOrders = list(
                new LambdaQueryWrapper<Orders>()
                        .eq(Orders::getUserId, userId)
                        .eq(Orders::getOrderStatus, bysj.pets.bec.entity.enumtype.OrderStatus.PENDING_PAYMENT.getCode()) // 待支付
        );
        
        if (pendingOrders.isEmpty()) {
            return result;
        }
        
        // 3. 检查是否有订单包含请求中的所有商品
        for (Orders order : pendingOrders) {
            // 查询该订单的所有商品ID
            List<OrderItem> orderItems = orderItemMapper.selectByOrderId(order.getOrderId());
            List<Long> orderProductIds = orderItems.stream()
                    .map(OrderItem::getProductId)
                    .collect(Collectors.toList());
            
            // 检查订单中的商品ID集合是否与请求中的商品ID集合完全一致
            // 注意：这里假设商品ID的顺序不影响比较结果
            Set<Long> requestSet = new HashSet<>(productIds);
            Set<Long> orderSet = new HashSet<>(orderProductIds);
            
            if (requestSet.equals(orderSet)) {
                // 找到了包含所有请求商品的未付款订单
                result.put("hasPendingOrder", true);
                result.put("orderId", order.getOrderId());
                result.put("orderInfoMatches", true);
                return result;
            }
        }
        
        // 4. 如果没有完全匹配的订单，返回第一个未付款订单的信息
        if (!pendingOrders.isEmpty()) {
            result.put("hasPendingOrder", true);
            result.put("orderId", pendingOrders.get(0).getOrderId());
            result.put("orderInfoMatches", false);
        }
        
        return result;
    }

    /**
     * 更新超过14天的订单状态为已完成
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateOverdueOrdersToCompleted() {
        // 计算14天前的时间
        LocalDateTime fourteenDaysAgo = LocalDateTime.now().minusDays(14);
        
        // 查询所有创建时间超过14天且状态不是已完成或已取消的订单
        List<Orders> overdueOrders = list(
                new LambdaQueryWrapper<Orders>()
                        .lt(Orders::getCreateTime, fourteenDaysAgo)
                        .notIn(Orders::getOrderStatus, 
                                bysj.pets.bec.entity.enumtype.OrderStatus.COMPLETED.getCode(),
                                bysj.pets.bec.entity.enumtype.OrderStatus.CANCELLED.getCode())
        );
        
        for (Orders order : overdueOrders) {
            // 更新订单状态为已完成
            order.setOrderStatus(bysj.pets.bec.entity.enumtype.OrderStatus.COMPLETED.getCode());
            order.setUpdateTime(LocalDateTime.now());
            updateById(order);
            
            // 更新订单项状态
            List<OrderItem> orderItems = orderItemMapper.selectByOrderId(order.getOrderId());
            for (OrderItem orderItem : orderItems) {
                orderItem.setItemStatus(3); // 已完成
                orderItem.setUpdateTime(LocalDateTime.now());
                orderItemMapper.updateById(orderItem);
            }
        }
    }
    
    /**
     * 更新订单状态
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateOrderStatus(Long orderId, Integer status) {
        // 1. 查询订单
        Orders order = getById(orderId);
        if (order == null) {
            throw new RuntimeException("订单不存在");
        }
        
        // 2. 更新订单状态
        order.setOrderStatus(status);
        order.setUpdateTime(LocalDateTime.now());
        if (!updateById(order)) {
            throw new RuntimeException("更新订单状态失败");
        }
        
        // 生成订单状态变更消息
        createOrderStatusMessage(order.getUserId(), orderId, order.getOrderNo(), status);
        
        // 3. 更新订单项状态
        List<OrderItem> orderItems = orderItemMapper.selectByOrderId(orderId);
        for (OrderItem orderItem : orderItems) {
            if (status == bysj.pets.bec.entity.enumtype.OrderStatus.REFUNDING.getCode()) {
                orderItem.setItemStatus(5); // 退款处理中
            }
            orderItem.setUpdateTime(LocalDateTime.now());
            orderItemMapper.updateById(orderItem);
        }
    }
}
