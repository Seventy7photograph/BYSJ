package bysj.pets.bec.service.impl;

import bysj.pets.bec.dto.CartItemDTO;
import bysj.pets.bec.entity.Cart;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.mapper.CartMapper;
import bysj.pets.bec.mapper.ProductMapper;
import bysj.pets.bec.service.CartService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 购物车服务实现类
 */
@Service
public class CartServiceImpl extends ServiceImpl<CartMapper, Cart> implements CartService {

    @Autowired
    private CartMapper cartMapper;

    @Autowired
    private ProductMapper productMapper;

    @Override
    @Transactional(readOnly = true)
    public List<CartItemDTO> getUserCartItems(Long userId) {
        List<CartItemDTO> cartItems = cartMapper.selectUserCartItems(userId);
        
        // 为每个购物车商品填充商品类型相关字段
        for (CartItemDTO cartItem : cartItems) {
            Product product = productMapper.selectById(cartItem.getProductId());
            if (product != null) {
                // 填充商品类型相关字段，进行Byte到Integer的转换
                if (product.getProductType() != null) {
                    cartItem.setProduct_type(product.getProductType().intValue());
                    
                    // 设置商品类型名称
                    if (product.getProductType().intValue() == 2) {
                        cartItem.setProductType("second-hand");
                    } else if (product.getProductType().intValue() == 1) {
                        cartItem.setProductType("new");
                    } else {
                        cartItem.setProductType("rent");
                    }
                }
                
                // 填充成色字段，进行Byte到Integer的转换
                if (product.getCondition() != null) {
                    cartItem.setCondition(product.getCondition().intValue());
                }
                
                // 根据成色设置quality字段，直接使用condition值作为quality，方便前端映射
                if (product.getCondition() != null) {
                    cartItem.setQuality(String.valueOf(product.getCondition()));
                }
            }
        }
        
        return cartItems;
    }

    @Override
    @Transactional
    public boolean addToCart(Long userId, Long productId, Integer quantity) {
        // 检查商品是否存在
        Product product = productMapper.selectById(productId);
        if (product == null) {
            return false;
        }

        // 检查是否已存在购物车记录
        Cart existingCartItem = cartMapper.selectCartItemByUserIdAndProductId(userId, productId);
        if (existingCartItem != null) {
            // 已存在，更新数量
            existingCartItem.setQuantity(existingCartItem.getQuantity() + quantity);
            existingCartItem.setUpdateTime(LocalDateTime.now());
            return updateById(existingCartItem);
        } else {
            // 不存在，创建新记录
            Cart cart = new Cart();
            cart.setUserId(userId);
            cart.setProductId(productId);
            cart.setQuantity(quantity);
            cart.setSelectStatus((byte) 1); // 默认选中
            cart.setCreateTime(LocalDateTime.now());
            cart.setUpdateTime(LocalDateTime.now());
            return save(cart);
        }
    }

    @Override
    @Transactional
    public boolean updateCartItemQuantity(Long cartId, Integer quantity) {
        if (quantity < 1) {
            return false;
        }
        Cart cart = getById(cartId);
        if (cart != null) {
            cart.setQuantity(quantity);
            cart.setUpdateTime(LocalDateTime.now());
            return updateById(cart);
        }
        return false;
    }

    @Override
    @Transactional
    public boolean removeCartItem(Long cartId) {
        return removeById(cartId);
    }

    @Override
    @Transactional
    public boolean batchRemoveCartItems(Long userId, List<Long> productIds) {
        return cartMapper.deleteCartItemsByUserAndProductIds(userId, productIds) > 0;
    }

    @Override
    @Transactional
    public boolean clearCart(Long userId) {
        return cartMapper.clearUserCart(userId) > 0;
    }

    @Override
    @Transactional
    public boolean batchAddToCart(Long userId, List<Long> productIds) {
        if (productIds == null || productIds.isEmpty()) {
            return false;
        }

        // 批量添加每个商品到购物车，数量默认为1
        for (Long productId : productIds) {
            addToCart(userId, productId, 1);
        }

        return true;
    }
}
