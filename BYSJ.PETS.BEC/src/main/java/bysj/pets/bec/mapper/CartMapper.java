package bysj.pets.bec.mapper;

import bysj.pets.bec.dto.CartItemDTO;
import bysj.pets.bec.entity.Cart;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 购物车Mapper接口
 */
public interface CartMapper extends BaseMapper<Cart> {
    /**
     * 获取用户购物车列表
     */
    List<CartItemDTO> selectUserCartItems(@Param("userId") Long userId);

    /**
     * 根据用户ID和商品ID查询购物车记录
     */
    Cart selectCartItemByUserIdAndProductId(@Param("userId") Long userId, @Param("productId") Long productId);

    /**
     * 批量删除购物车记录
     */
    int deleteCartItemsByUserAndProductIds(@Param("userId") Long userId, @Param("productIds") List<Long> productIds);

    /**
     * 清空用户购物车
     */
    int clearUserCart(@Param("userId") Long userId);
}
