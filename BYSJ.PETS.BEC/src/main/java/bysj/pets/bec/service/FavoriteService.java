package bysj.pets.bec.service;

import bysj.pets.bec.dto.FavoriteDTO;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import bysj.pets.bec.entity.Favorite;

import java.util.List;
import java.util.Map;

/**
 * 收藏Service接口
 */
public interface FavoriteService extends IService<Favorite> {

    /**
     * 收藏商品
     */
    boolean addFavorite(Long userId, Long productId);

    /**
     * 取消收藏
     */
    boolean removeFavorite(Long userId, Long favoriteId);

    /**
     * 批量取消收藏
     */
    boolean batchRemoveFavorites(Long userId, List<Long> favoriteIds);

    /**
     * 检查商品是否已收藏
     */
    boolean checkIsFavorite(Long userId, Long productId);

    /**
     * 根据商品ID取消收藏
     */
    boolean removeFavoriteByProductId(Long userId, Long productId);

    /**
     * 分页查询用户收藏列表
     */
    IPage<FavoriteDTO> getUserFavorites(Long userId, int page, int size);
}
