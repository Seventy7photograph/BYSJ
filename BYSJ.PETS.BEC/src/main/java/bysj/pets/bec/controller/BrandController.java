package bysj.pets.bec.controller;

import bysj.pets.bec.entity.Brand;
import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.BrandMapper;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.config.Result;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/brands")
public class BrandController {

    @Autowired
    private BrandMapper brandMapper;

    @Autowired
    private UserMapper userMapper;

    @GetMapping
    public Result getBrandList() {
        QueryWrapper<Brand> queryWrapper = new QueryWrapper<>();
        queryWrapper.orderByAsc("sort");
        List<Brand> brands = brandMapper.selectList(queryWrapper);
        return Result.success(brands);
    }

    @GetMapping("/{id}")
    public Result getBrandById(@PathVariable Integer id) {
        Brand brand = brandMapper.selectById(id);
        if (brand == null) {
            return Result.error("品牌不存在");
        }
        return Result.success(brand);
    }

    @PostMapping
    public Result addBrand(@RequestBody Brand brand) {
        Long userId = getCurrentUserId();
        
        // 检查品牌名称和分类编码的组合是否已存在
        QueryWrapper<Brand> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("brand_name", brand.getBrandName());
        queryWrapper.eq("category_code", brand.getCategoryCode());
        Brand existingBrand = brandMapper.selectOne(queryWrapper);
        if (existingBrand != null) {
            return Result.error("品牌名称和分类编码的组合已存在");
        }
        
        if (brand.getParentId() == null || brand.getParentId() == 0) {
            brand.setSort(0);
        } else {
            Brand parentBrand = brandMapper.selectById(brand.getParentId());
            if (parentBrand != null) {
                brand.setSort(parentBrand.getSort() + 1);
            } else {
                brand.setSort(0);
            }
        }
        brand.setCreateBy(userId);
        brand.setCreateTime(java.time.LocalDateTime.now());
        brand.setUpdateTime(java.time.LocalDateTime.now());
        
        brandMapper.insert(brand);
        return Result.success("品牌添加成功");
    }

    @PutMapping("/{id}")
    public Result updateBrand(@PathVariable Integer id, @RequestBody Brand brand) {
        Brand existingBrand = brandMapper.selectById(id);
        if (existingBrand == null) {
            return Result.error("品牌不存在");
        }
        
        // 检查品牌名称和分类编码的组合是否已存在（排除当前品牌）
        QueryWrapper<Brand> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("brand_name", brand.getBrandName());
        queryWrapper.eq("category_code", brand.getCategoryCode());
        queryWrapper.ne("brand_id", id);
        Brand duplicateBrand = brandMapper.selectOne(queryWrapper);
        if (duplicateBrand != null) {
            return Result.error("品牌名称和分类编码的组合已存在");
        }
        
        Long userId = getCurrentUserId();
        brand.setBrandId(id);
        brand.setUpdateBy(userId);
        brand.setUpdateTime(java.time.LocalDateTime.now());
        
        brandMapper.updateById(brand);
        
        if (brand.getStatus() != null && existingBrand.getStatus() != null && brand.getStatus() != existingBrand.getStatus()) {
            QueryWrapper<Brand> childQueryWrapper = new QueryWrapper<>();
            childQueryWrapper.eq("parent_id", id);
            List<Brand> childBrands = brandMapper.selectList(childQueryWrapper);
            for (Brand childBrand : childBrands) {
                childBrand.setStatus(brand.getStatus());
                childBrand.setUpdateTime(java.time.LocalDateTime.now());
                brandMapper.updateById(childBrand);
            }
        }
        
        return Result.success("品牌更新成功");
    }

    @DeleteMapping("/{id}")
    public Result deleteBrand(@PathVariable Integer id) {
        Brand brand = brandMapper.selectById(id);
        if (brand == null) {
            return Result.error("品牌不存在");
        }
        
        brandMapper.deleteById(id);
        return Result.success("品牌删除成功");
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            return null;
        }
        String username = authentication.getName();
        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        return user != null ? user.getUserId() : null;
    }
}
