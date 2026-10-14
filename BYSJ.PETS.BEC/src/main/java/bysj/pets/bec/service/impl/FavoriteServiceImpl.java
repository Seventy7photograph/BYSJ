package bysj.pets.bec.service.impl;

import bysj.pets.bec.dto.FavoriteDTO;
import bysj.pets.bec.entity.Favorite;
import bysj.pets.bec.entity.Product;
import bysj.pets.bec.mapper.FavoriteMapper;
import bysj.pets.bec.mapper.ProductMapper;
import bysj.pets.bec.service.FavoriteService;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 收藏Service实现类
 */
@Service
public class FavoriteServiceImpl extends ServiceImpl<FavoriteMapper, Favorite> implements FavoriteService {

    @Autowired
    private ProductMapper productMapper;

    @Override
    @Transactional
    public boolean addFavorite(Long userId, Long productId) {
        // 检查是否已收藏
        if (checkIsFavorite(userId, productId)) {
            return false; // 已收藏，返回false
        }

        // 创建收藏记录
        Favorite favorite = new Favorite();
        favorite.setUserId(userId);
        favorite.setProductId(productId);
        favorite.setCreateTime(LocalDateTime.now());

        return save(favorite);
    }

    @Override
    @Transactional
    public boolean removeFavorite(Long userId, Long favoriteId) {
        // 确保用户只能删除自己的收藏
        return lambdaUpdate()
                .eq(Favorite::getUserId, userId)
                .eq(Favorite::getId, favoriteId)
                .remove();
    }

    @Override
    @Transactional
    public boolean batchRemoveFavorites(Long userId, List<Long> favoriteIds) {
        if (favoriteIds == null || favoriteIds.isEmpty()) {
            return false;
        }

        return baseMapper.batchDeleteFavorites(userId, favoriteIds) > 0;
    }

    @Override
    @Transactional(readOnly = true)
    public boolean checkIsFavorite(Long userId, Long productId) {
        Integer count = baseMapper.checkProductIsFavorite(userId, productId);
        return count != null && count > 0;
    }

    @Override
    @Transactional(readOnly = true)
    public IPage<FavoriteDTO> getUserFavorites(Long userId, int page, int size) {
        IPage<FavoriteDTO> pageResult = new Page<>(page, size);
        IPage<FavoriteDTO> favorites = baseMapper.selectUserFavorites(pageResult, userId);
        
        // 为每个收藏商品填充商品类型相关字段
        for (FavoriteDTO favorite : favorites.getRecords()) {
            // 直接使用XML查询返回的字段，无需再次查询数据库
            Integer productType = favorite.getProduct_type();
            Integer condition = favorite.getCondition();
            
            // 设置商品类型名称
            if (productType != null) {
                if (productType == 2) {
                    favorite.setProductType("second-hand");
                } else if (productType == 1) {
                    favorite.setProductType("new");
                } else {
                    favorite.setProductType("rent");
                }
            }
            
            // 根据成色设置quality字段，直接使用condition值作为quality，方便前端映射
            if (condition != null) {
                favorite.setQuality(String.valueOf(condition));
            }
        }
        
        return favorites;
    }

    @Override
    @Transactional
    public boolean removeFavoriteByProductId(Long userId, Long productId) {
        // 调用Mapper方法，根据userId和productId删除收藏记录
        return baseMapper.removeFavoriteByProductId(userId, productId) > 0;
    }
}
