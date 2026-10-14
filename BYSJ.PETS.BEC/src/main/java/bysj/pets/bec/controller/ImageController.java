package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.dto.ProductImageDTO;
import bysj.pets.bec.entity.ProductImage;
import bysj.pets.bec.mapper.ProductImageMapper;
import bysj.pets.bec.service.StorageService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 商品图片接口。
 *
 * 上传本身已经收敛到 /files/upload（见 FileController），这里只负责
 * 「把图库里的图片绑定到商品上」这一件事。
 *
 * 原 /image/upload 保留为别名，方便仍在用旧地址的页面平滑过渡；
 * 它现在同样走 StorageService，不再自己写盘。
 */
@RestController
@RequestMapping("/image")
@RequiredArgsConstructor
public class ImageController {

    private final StorageService storageService;
    private final ProductImageMapper productImageMapper;
    private final FileController fileController;

    // POST /image/upload 已移除：上传只有 /files/upload 一个入口。
    // 保留一个没有权限项覆盖、且与主入口行为重复的别名，只会让"谁能传文件"
    // 这件事有两个答案。

    /**
     * 商品绑定图片（整组替换）。
     *
     * 原实现用 delete() 物理删除绑定关系后重新插入，product_image 的
     * is_deleted 列因此永远不会被用到；这里改为软删旧的、插入新的，
     * 历史绑定关系可追溯。
     */
    @PostMapping("/bind/product")
    @Transactional
    public Result<?> bindProductImage(@RequestBody ProductImageDTO dto) {
        if (dto.getProductId() == null) {
            return Result.error("缺少商品ID");
        }
        String imageType = (dto.getImageType() == null || dto.getImageType().isBlank())
                ? "main" : dto.getImageType();
        List<Long> imageIds = dto.getImageIds() == null ? List.of() : dto.getImageIds();

        // 1. 先软删该商品同类型的旧绑定
        productImageMapper.update(null, new LambdaUpdateWrapper<ProductImage>()
                .eq(ProductImage::getProductId, dto.getProductId())
                .eq(ProductImage::getImageType, imageType)
                .set(ProductImage::getIsDeleted, 1));

        // 2. 写入新绑定，sort 决定主图
        for (int i = 0; i < imageIds.size(); i++) {
            ProductImage productImage = new ProductImage();
            productImage.setProductId(dto.getProductId());
            productImage.setImageId(imageIds.get(i));
            productImage.setImageType(imageType);
            productImage.setSort(i);
            productImage.setIsDeleted(0);
            productImageMapper.insert(productImage);
        }
        return Result.success("绑定成功");
    }

    // GET /image/product/{productId} 已移除：商家端读的是
    // /merchant/product/{productId}/images，两套查询做同一件事没有意义。
}
