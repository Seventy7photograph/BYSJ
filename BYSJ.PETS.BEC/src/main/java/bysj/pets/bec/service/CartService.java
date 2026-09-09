package bysj.pets.bec.service;

import bysj.pets.bec.dto.CartItemDTO;
import bysj.pets.bec.entity.Cart;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

/**
 * 购物车服务接口
 */
public interface CartService extends IService<Cart> {
    /**
     * 获取用户购物车列表
     */
    List<CartItemDTO> getUserCartItems(Long userId);

    /**
     * 添加商品到购物车
     */
    boolean addToCart(Long userId, Long productId, Integer quantity);

    /**
     * 更新购物车商品数量
     */
    boolean updateCartItemQuantity(Long cartId, Integer quantity);

    /**
     * 删除购物车商品
     */
    boolean removeCartItem(Long cartId);

    /**
     * 批量删除购物车商品
     */
    boolean batchRemoveCartItems(Long userId, List<Long> productIds);

    /**
     * 清空购物车
     */
    boolean clearCart(Long userId);
    
    /**
     * 批量添加商品到购物车
     */
    boolean batchAddToCart(Long userId, List<Long> productIds);
}
