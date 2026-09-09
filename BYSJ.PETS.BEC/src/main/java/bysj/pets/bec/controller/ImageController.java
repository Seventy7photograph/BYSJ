package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.dto.ProductImageDTO;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Autowired;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import bysj.pets.bec.entity.SysImage;
import bysj.pets.bec.entity.ProductImage;
import bysj.pets.bec.mapper.SysImageMapper;
import bysj.pets.bec.mapper.ProductImageMapper;
import bysj.pets.bec.utils.FileUploadUtil;


import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;


@RestController
@RequestMapping("/image")
public class ImageController {

    @Autowired
    private FileUploadUtil fileUploadUtil;
    @Autowired
    private SysImageMapper sysImageMapper;
    @Autowired
    private ProductImageMapper productImageMapper;

    /**
     * 图片上传接口（图库/商品图片通用）
     */
    @PostMapping("/upload")
    public Result<?> upload(@RequestParam("file") MultipartFile file) {
        try {
            // 添加文件空值和文件名空值判断
            if (file.isEmpty() || file.getOriginalFilename() == null) {
                return Result.error("上传文件不能为空");
            }

            // 1. 上传文件，获取访问URL
            String storagePath = fileUploadUtil.uploadImage(file);

            // 2. 保存到图库表
            SysImage sysImage = new SysImage();
            sysImage.setOriginalName(file.getOriginalFilename());
            sysImage.setStoragePath(storagePath);
            sysImage.setFileSize(file.getSize());
            sysImage.setFileType(file.getContentType());
            sysImage.setBusinessType("product");
            sysImage.setUploadTime(LocalDateTime.now());

            System.out.println("插入前的SysImage对象: " + sysImage);
            System.out.println("插入前id值: " + sysImage.getId());

            sysImageMapper.insert(sysImage);

            System.out.println("插入后的SysImage对象: " + sysImage);
            System.out.println("插入后id值: " + sysImage.getId());

            SysImage insertedImage = sysImageMapper.selectOne(new LambdaQueryWrapper<SysImage>()
                    .eq(SysImage::getStoragePath, storagePath)
                    .orderByDesc(SysImage::getUploadTime)
                    .last("LIMIT 1"));

            System.out.println("查询到的SysImage ID: " + (insertedImage != null ? insertedImage.getId() : "null"));

            return Result.success("上传成功", insertedImage);
        } catch (IOException | IllegalArgumentException e) {
            e.printStackTrace();
            return Result.error(e.getMessage());
        }
    }


    /**
     * 商品绑定图片（多图）
     */
    @PostMapping("/bind/product")
    @Transactional
    public Result<?> bindProductImage(@RequestBody ProductImageDTO dto) {
        // 1. 先删除该商品已绑定的同类型图片（可选，根据业务需求）
        LambdaQueryWrapper<ProductImage> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ProductImage::getProductId, dto.getProductId())
                .eq(ProductImage::getImageType, dto.getImageType());
        productImageMapper.delete(wrapper);
        // 2. 批量绑定图片
        List<Long> imageIds = dto.getImageIds();
        for (int i = 0; i < imageIds.size(); i++) {
            ProductImage productImage = new ProductImage();
            productImage.setProductId(dto.getProductId());
            productImage.setImageId(imageIds.get(i));
            productImage.setImageType(dto.getImageType());
            productImage.setSort(i); // 排序号
            productImageMapper.insert(productImage);
        }
        return Result.success("绑定成功");
    }

    /**
     * 图库分页查询
     */
    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer pageNum,
                          @RequestParam(defaultValue = "10") Integer pageSize,
                          @RequestParam(required = false) String businessType) {
        Page<SysImage> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<SysImage> wrapper = new LambdaQueryWrapper<>();
        if (businessType != null) {
            wrapper.eq(SysImage::getBusinessType, businessType);
        }
        wrapper.orderByDesc(SysImage::getUploadTime);
        sysImageMapper.selectPage(page, wrapper);
        return Result.success(String.valueOf(page));
    }
}

