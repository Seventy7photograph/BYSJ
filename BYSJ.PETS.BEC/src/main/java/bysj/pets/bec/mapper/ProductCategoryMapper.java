package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Brand;
import bysj.pets.bec.entity.ProductCategory;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

public interface ProductCategoryMapper extends BaseMapper<ProductCategory> {
    /**
     * 查询所有主分类
     */
    List<ProductCategory> selectMainCategories();

    // 根据祖先分类ID查询所有子孙分类（含自身）的category_code
    List<String> selectAllChildCategoryCodes(@Param("ancestorId") Integer ancestorId);

    // 根据父类ID查询子类分类（状态正常的）
    List<ProductCategory> selectChildCategoriesByParentId(@Param("parentId") Integer parentId);

    // 查询所有分类
    List<ProductCategory> selectAllCategories();

    // 查询所有品牌
    List<Brand> selectAllBrands();

    List<Brand> selectChildBrandsByParentId(@Param("parentId") Integer parentId);
}