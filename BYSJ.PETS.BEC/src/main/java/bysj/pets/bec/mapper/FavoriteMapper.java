package bysj.pets.bec.mapper;

import bysj.pets.bec.dto.FavoriteDTO;
import bysj.pets.bec.entity.Favorite;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 收藏Mapper接口
 */
public interface FavoriteMapper extends BaseMapper<Favorite> {

    /**
     * 分页查询用户收藏列表
     */
    IPage<FavoriteDTO> selectUserFavorites(IPage<FavoriteDTO> page, @Param("userId") Long userId);

    /**
     * 检查商品是否已收藏
     */
    Integer checkProductIsFavorite(@Param("userId") Long userId, @Param("productId") Long productId);

    /**
     * 批量删除收藏
     */
    int batchDeleteFavorites(@Param("userId") Long userId, @Param("favoriteIds") List<Long> favoriteIds);

    /**
     * 根据userId和productId删除收藏
     */
    int removeFavoriteByProductId(@Param("userId") Long userId, @Param("productId") Long productId);
}
