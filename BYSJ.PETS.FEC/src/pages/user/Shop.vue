<template>
  <div class="goods-market-page">
<!-- 顶部摄影器材分类导航 -->
<div class="category-nav">
  <el-menu
    mode="horizontal"
    trigger="hover"
    @select="handleCategorySelect"
    background-color="#89CFF0"
    text-color="#333"
    active-text-color="#fff"
    style="border-bottom: 1px solid #e6e6e6; height: 48px; line-height: 48px;"
    v-model:default-active="activeMenuIndex"
    :unique-opened="true"
    >

    <el-menu-item index="all">
      <img src="/public/热门.png" alt="热门商品" style="height: 32px; margin-right: 6px;">
      <span>热门商品</span>
    </el-menu-item>

    <el-menu-item
      v-for="mainItem in categoryList"
      :key="mainItem.id"
      :index="mainItem.value"
    >
      <img :src="mainItem.img" alt="{{ mainItem.name }}" style="height: 32px; margin-right: 6px;">
      <span>{{ mainItem.name }}</span>
    </el-menu-item>
  </el-menu>
   <!-- 引入分类数据组件 -->
    <CategoryDataComponent ref="categoryDataRef" />
</div>


    <!-- 筛选栏 -->
    <div class="filter-bar">
      <!-- 品牌筛选 -->
      <el-select v-if="selectedMainCategory !== 'all'" v-model="selectedBrand" placeholder="品牌" size="small" @change="loadGoodsList" style="width: 120px;">
        <el-option
          v-for="brand in currentBrands"
          :key="brand.value"
          :label="brand.label"
          :value="brand.value"
        />
      </el-select>

      <!-- 器材类型筛选（根据选中的大类动态变化） -->
      <el-select v-if="selectedMainCategory !== 'all'" v-model="selectedType" placeholder="器材类型" size="small" @change="loadGoodsList" style="width: 120px;">
        <el-option
          v-for="type in currentTypes"
          :key="type.value"
          :label="type.label"
          :value="type.value"
        />
      </el-select>

      <!-- 搜索框（调整宽度） -->
      <div style="display: flex; align-items: center;">
        <el-input
          v-model="searchKeyword"
          placeholder="输入器材名称（如：索尼A7M4）"
          size="small"
          style="width: 250px;"
          @keyup.enter="loadGoodsList"
          clearable
        />
        <el-button type="primary" size="small" @click="loadGoodsList" style="margin-left: 5px;">搜索</el-button>
      </div>
      <!-- 排序下拉 -->
      <el-select v-model="sortType" placeholder="排序" size="small" @change="loadGoodsList" style="width: 100px;">
        <el-option label="默认排序" value="default" />
        <el-option label="价格升序" value="price_asc" />
        <el-option label="价格降序" value="price_desc" />
      </el-select>

      <!-- 添加筛选按钮 -->
      <el-button
        type="default"
        size="small"
        @click="showFilterDrawer = true"
        class="filter-btn"
      >
        筛选器
      </el-button>
    </div>

    <!-- 分割线 -->
    <div class="divider" style="margin: 20px 0;"><el-divider /></div>

    <!-- 3.商品卡片列表 -->
    <div class="products-container">
      <!-- 空数据提示 -->
      <div v-if="goodsList.length === 0 && !loading" class="empty-tip">
        <el-empty
          description="暂无相关商品，换个关键词试试吧～"
          :image-size="120"
        />
      </div>

      <!-- 骨架屏（加载中显示） -->
      <template v-else-if="loading">
        <div class="skeleton-item" v-for="index in 12" :key="`skeleton-${index}`">
          <el-skeleton animated :rows="3" :throttle="0.5">
            <template #template>
              <div class="skeleton-item-content">
                <el-skeleton-item variant="image" style="width: 100%; height: 200px;" />
                <div class="skeleton-text">
                  <el-skeleton-item variant="text" style="width: 80%;" />
                  <el-skeleton-item variant="text" style="width: 40%; margin-top: 10px;" />
                  <el-skeleton-item variant="text" style="width: 60%; margin-top: 10px;" />
                </div>
              </div>
            </template>
          </el-skeleton>
        </div>
      </template>

      <!-- 商品列表（有数据时显示） -->
      <template v-else>
        <div class="product-item" v-for="(goods, index) in goodsList" :key="`product-${index}`" @click="goToProductDetail(goods.productId)">
          <div class="product-image">
            <img :src="goods.imageUrl" :alt="goods.name">
          </div>
          <div class="product-info">
            <div class="product-name">{{ formatProductName(goods.name) }}</div>
            <div class="product-price">¥{{ goods.price }}</div>
            <div class="product-other">
              <span class="product-seller">卖家: {{ goods.sellerName || '匿名' }}</span>
            </div>
          </div>
        </div>
      </template>
    </div>

    <!-- 4. 分页组件 -->
    <div class="pagination" v-if="total > 0">
      <el-pagination
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
        :current-page="pageNum"
        :page-sizes="[10, 20, 30]"
        :page-size="pageSize"
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
      />
    </div>

    <!-- 筛选抽屉弹窗 -->
    <el-drawer
      v-model="showFilterDrawer"
      title="筛选器"
      size="28%"
      direction="rtl"
      :close-on-click-modal="true"
      @close="handleDrawerClose"
    >
      <!-- 引入筛选组件 -->
      <FilterComponent
        :main-category="selectedMainCategory"
        :filter-params="filterParams"
        @update:filter-params="updateFilterParams"
        @reset="resetFilters"
        @confirm="confirmFilters"
      />
    </el-drawer>

    <!-- 分割线 -->
    <div class="divider" style="margin: 20px 0;"><el-divider /></div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import axios from '@/axios';
import { useRouter, useRoute } from 'vue-router';
import { ElMessageBox ,ElEmpty} from 'element-plus';
// 导入筛选组件
import FilterComponent from '@/components/FilterComponent.vue';
// 导入分类数据组件
import CategoryDataComponent from '@/components/CategoryDataComponent.vue';

// 创建 router 实例
const router = useRouter();
const route = useRoute();

// 分类数据组件引用
const categoryDataRef = ref(null);

// 添加格式化产品名称的方法
const formatProductName = (name) => {
  // 去掉产品名称前面的数字编号（如去掉"12 "、"11 "等）
  // 使用正则表达式匹配开头的数字和空格，然后去掉
  return name.replace(/^\d+\s*/, '');
};

// 跳转到商品详情页
const goToProductDetail = (productId) => {
  console.log('跳转到商品详情页，商品ID：', productId);

  // 检查商品ID是否有效
  if (!productId || productId === 'undefined' || productId === 'null') {
    console.error('商品ID无效：', productId);
    console.log('当前商品列表：', goodsList.value);
    return;
  }

  router.push(`/product/${productId}`);
};
// 1. 摄影器材分类数据（从组件中获取）
const categoryList = computed(() => {
  return categoryDataRef.value?.categoryList || [];
});

// 添加菜单激活状态变量
const activeMenuIndex = ref("all"); // 默认选中"热门商品"

// 2. 筛选/分页参数
const selectedCategory = ref(""); // 选中的子分类
const selectedMainCategory = ref("all"); // 选中的主分类（用于动态显示品牌和类型）
const selectedBrand = ref(""); // 品牌
const selectedType = ref(""); // 器材类型
const searchKeyword = ref(""); // 搜索关键词
const sortType = ref(""); // 排序方式
const pageNum = ref(1); // 当前页
const pageSize = ref(10); // 每页条数
const total = ref(0); // 总商品数
const goodsList = ref([]); // 商品列表
const loading = ref(false); // 加载状态

// 3. 根据选中的主分类动态获取当前可用的品牌
const currentBrands = ref([]);

// 添加获取品牌列表的方法
const loadBrandsByCategory = async () => {
 // 1. 当选中"热门商品"（all）时，显示"不限"
  if (selectedMainCategory.value === "all") {
    currentBrands.value = [{ label: "不限", value: "" }];
    return;
  }

  try {
    // 2. 从主分类列表中找到当前选中主分类的category_id（parentId）
    const currentMainCategory = categoryList.value.find(
      item => item.value === selectedMainCategory.value
    );
    if (!currentMainCategory) {
      console.warn("未找到选中的主分类");
      currentBrands.value = [{ label: "不限", value: "" }];
      return;
    }
    const parentId = currentMainCategory.id; // 主分类的category_id作为父ID
    console.log("查询子类分类，父ID：", parentId);

    // 3. 调用后端接口获取子类（注意：接口参数是parentId，对应后端的Integer类型）
    const res = await axios.get("/shop/brands", {
      params: { parentId: parentId }
    });

    // 4. 检查接口返回格式是否正确
    if (res && res.brands) {
      // 拼接"不限"选项
      currentBrands.value = [
        { label: "不限", value: "" },
        ...res.brands
      ];
      console.log("加载品牌成功：", currentBrands.value);
    } else {
      currentBrands.value = [{ label: "不限", value: "" }];
      console.warn("接口返回格式不正确，缺少brands字段");
    }
  } catch (err) {
    console.error("获取品牌失败：", err.response?.data || err.message);
    currentBrands.value = [{ label: "不限", value: "" }];
  }
};

// 4. 根据选中的主分类动态获取当前可用的类型
const currentTypes = ref([]); // 存储从后端获取的子类列表

// 加载器材类型（子类分类）
const loadSubCategories = async () => {
  // 1. 当选中"热门商品"（all）时，显示"不限"
  if (selectedMainCategory.value === "all") {
    currentTypes.value = [{ label: "不限", value: "" }];
    return;
  }

  try {
    // 2. 从主分类列表中找到当前选中主分类的category_id（parentId）
    const currentMainCategory = categoryList.value.find(
      item => item.value === selectedMainCategory.value
    );
    if (!currentMainCategory) {
      console.warn("未找到选中的主分类");
      currentTypes.value = [{ label: "不限", value: "" }];
      return;
    }
    const parentId = currentMainCategory.id; // 主分类的category_id作为父ID
    console.log("查询子类分类，父ID：", parentId);

    // 3. 调用后端接口获取子类（注意：接口参数是parentId，对应后端的Integer类型）
    const res = await axios.get("/shop/sub-categories", {
      params: { parentId: parentId }
    });

    // 4. 检查接口返回格式
    if (res && res.subCategories) {
      // 拼接"不限"选项
      currentTypes.value = [
        { label: "不限", value: "" },
        ...res.subCategories
      ];
      console.log("加载子类分类成功：", currentTypes.value);
    } else {
      currentTypes.value = [{ label: "不限", value: "" }];
      console.warn("接口返回格式不正确，缺少subCategories字段");
    }
  } catch (err) {
    console.error("获取器材类型失败：", err.response?.data || err.message);
    currentTypes.value = [{ label: "不限", value: "" }];
  }
};

// 5. 分类选中事件
const handleCategorySelect = (menuIndex) => {
  activeMenuIndex.value = menuIndex;

  if (menuIndex === "all") {
    selectedCategory.value = "";
    selectedMainCategory.value = "all";
    selectedBrand.value = "";
    selectedType.value = "";
  } else {
    selectedMainCategory.value = menuIndex;
    selectedCategory.value = menuIndex;
    selectedBrand.value = "";
    selectedType.value = "";
  }

  // 先加载品牌，再加载商品列表
  loadBrandsByCategory().then(() => {
    loadSubCategories();
    pageNum.value = 1;
    loadGoodsList();
  });
};


// 6. 加载商品列表
const loadGoodsList = async () => {
  try {
    loading.value = true;
    // 准备筛选参数
    const params = {
      category: selectedCategory.value || "",
      brand: selectedBrand.value || "",
      type: selectedType.value || "",
      keyword: searchKeyword.value || "",
      sort: sortType.value || "",
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      quality: "brand_new"
    };

    // 移除值为空的参数
    Object.keys(params).forEach(key => {
      if (params[key] === null || params[key] === undefined || params[key] === "") {
        delete params[key];
      }
    });

    const res = await axios.get("/shop/random-products", {
      params
    });

    // 添加调试信息，检查商品数据结构和ID字段
    console.log('商品列表数据：', res);

    // 检查数据结构，处理可能的嵌套情况
    const data = res.data || res;
    goodsList.value = data.list || [];
    total.value = data.total || 0;

  } catch (err) {
    console.error("加载摄影器材失败：", err);
    goodsList.value = [];
    total.value = 0;
  } finally {
    loading.value = false;
  }
};
//7. 分页事件
const handleSizeChange = (val) => {
  pageSize.value = val;
  loadGoodsList();
};
const handleCurrentChange = (val) => {
  pageNum.value = val;
  loadGoodsList();
};

// 8. 筛选抽屉相关
const showFilterDrawer = ref(false);
// 添加标志位区分确认关闭和取消关闭
const isConfirmClose = ref(false);

// 筛选参数
const filterParams = ref({
  priceMin: null,
  priceMax: null,
  priceRange: null,
  scenes: [],
  videoAbilities: [],
  stabilizations: [],
  positions: [],
  sensors: [],
  series: [],
  expandedSections: {
    scene: true,
    video: true,
    stabilization: true,
    position: true,
    sensor: true,
    series: true
  }
});

// 更新筛选参数
const updateFilterParams = (newParams) => {
  filterParams.value = newParams;
};

// 切换展开/收起
const toggleSection = (section) => {
  filterParams.value.expandedSections[section] = !filterParams.value.expandedSections[section];
};

// 重置筛选
const resetFilters = () => {
  filterParams.value = {
    priceMin: null,
    priceMax: null,
    priceRange: null,
    scenes: [],
    videoAbilities: [],
    stabilizations: [],
    positions: [],
    sensors: [],
    series: [],
    expandedSections: {
      scene: true,
      video: true,
      stabilization: true,
      position: true,
      sensor: true,
      series: true
    }
  };
};

// 确认筛选
const confirmFilters = () => {
  // 这里可以处理筛选逻辑
  console.log('筛选参数:', filterParams.value);
  // 设置确认关闭标志位
  isConfirmClose.value = true;
  showFilterDrawer.value = false;
};

// 处理抽屉关闭
const handleDrawerClose = () => {
  // 如果是确认关闭，直接关闭抽屉
  if (isConfirmClose.value) {
    isConfirmClose.value = false;
    return;
  }

  // 否则显示取消筛选确认对话框
  ElMessageBox.confirm('是否取消筛选，已选条件将清除？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning',
    center: true
  })
    .then(() => {
      showFilterDrawer.value = false;
    })
    .catch(() => {
      // 取消关闭抽屉
      showFilterDrawer.value = true;
    });
};

// 页面加载时调用
onMounted(() => {
  // 直接加载热门商品，避免重复调用handleCategorySelect
  selectedMainCategory.value = "all";
  selectedCategory.value = "";
  selectedBrand.value = "";
  selectedType.value = "";

  // 处理URL参数中的搜索关键词
  if (route.query.keyword) {
    searchKeyword.value = route.query.keyword;
  }

  loadBrandsByCategory();
  loadSubCategories(); // 加载热门商品的器材类型（子类分类）
  loadGoodsList();

  // 调试信息保留
  setTimeout(() => {
    console.log("主分类列表：", categoryList.value);
    console.log('categoryDataRef:', categoryDataRef.value);
    console.log('currentBrands:', currentBrands.value);
    console.log('URL搜索关键词:', route.query.keyword);
  }, 100);
});

</script>

<style scoped>
.goods-market-page {
  padding: 0 20px;
  max-width: 95%;
  margin: 0 auto;
  min-width: 320px; /* 添加最小宽度，防止页面过度挤压 */
}

/* 分类导航样式 - 核心修改 */
.category-nav {
  margin-bottom: 20px;
  width: 100%;
  padding: 0 20px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(137, 207, 240, 0.2);
}



/* 关键修复：强制 el-menu-item 内部完全居中 */
:deep(.el-menu-item) {
  text-align: center;
  font-size: 14px;
  color: #fff !important;
  height: 48px !important;
  line-height: 48px !important;
  /* 1. 重置 flex 布局，确保整体居中 */
  display: flex;
  justify-content: center !important; /* 提高优先级 */
  align-items: center !important;
  /* 2. 清除原生的左右 padding 导致的偏移 */
  padding: 0 15px !important;
  /* 3. 固定菜单项最小宽度，避免窄屏挤压 */
  min-width: 100px;
}

/* 修复图标和文字的间距，避免文字被挤右 */
:deep(.el-menu-item i) {
  margin-right: 6px !important; /* 固定图标右侧间距 */
  flex-shrink: 0; /* 防止图标被压缩 */
}

/* 修复图标+文字容器的居中 */
:deep(.el-menu-item .el-menu-item__content) {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%; /* 占满父容器宽度，确保文字居中 */
}

/* 明确的选中状态样式 */
:deep(.el-menu-item.is-active) {
  background-color: #5CACEE !important;
  color: #fff !important;
}

:deep(.el-menu-item:hover) {
  background-color: #7CB3E9 !important;
  color: #fff !important;
}

/* 筛选栏样式 */
.filter-bar {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  flex-wrap: wrap;
  gap: 15px; /* 使用gap替代margin，提高布局稳定性 */
  justify-content: flex-end;
  background-color: #fff;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* .filter-bar > * {
  margin-right: 15px;
  margin-bottom: 10px;
}
 */

.filter-btn {
  background-color: #f0f0f0;
  color: #333;
}

.filter-btn:hover {
  background-color: #409EFF;
  color: white;
}

/* 商品列表容器样式 */
.products-container {
  display: grid; /* 使用Grid布局替代Flexbox，提高布局稳定性 */
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); /* 自动填充列，每列最小宽度250px */
  gap: 20px;
  margin-bottom: 30px;
  width: 90%;
  margin-left: 5%;
  margin-right: 5%;
  /* 设置最小高度，确保无数据时也有足够高度 */
  min-height: 200px;
  /* 移除align-items: center，确保网格布局正常排列 */
  align-items: start;
}

/* 空提示容器 - 完全居中核心样式 */
.empty-tip {
  /* 占满整个products-container的网格/容器 */
  grid-column: 1 / -1; /* 关键：跨所有列，水平居中 */
  display: flex;
  justify-content: center; /* 水平居中 */
  align-items: center; /* 垂直居中 */
  height: 400px; /* 与容器最小高度一致，垂直居中 */
  width: 100%;
}


/* 商品项样式 */
.product-item {
  display: flex;
  flex-direction: column;
  background-color: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  cursor: pointer;
  min-width: 200px; /* 添加最小宽度 */
  width: 100%; /* 确保占满网格列宽 */
}

.product-item:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(137, 207, 240, 0.5); /* 使用导航栏背景色作为阴影颜色 */
}

/* 商品图片容器 */
.product-image {
  width: 100%;
  height: 200px; /* 固定图片高度 */
  overflow: hidden;
  background-color: #f5f5f5;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 商品图片 */
.product-image img {
  width: 100%;
  height: 100%;
  object-fit: contain; /* 保持图片比例 */
  transition: transform 0.3s ease;
}

.product-item:hover .product-image img {
  transform: scale(1.05);
}

/* 商品信息 */
.product-info {
  padding: 10px;
  display: flex;
  flex-direction: column;
  position: relative;
  min-height: 80px;
  text-align: right;
}

/* 商品名称 */
.product-name {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 10px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: #333;
  text-align: left;
}

/* 商品价格 */
.product-price {
  font-size: 18px;
  font-weight: bold;
  color: #ff4d4f;
  margin-bottom: 8px;
  text-align: right;
}

/* 商品其他信息 */
.product-other {
  font-size: 12px;
  color: #999;
  display: flex;
  justify-content: flex-end;
  align-items: flex-end;
  flex-wrap: wrap;
  margin-top: auto;
}

.product-seller {
  color: #666;
  text-align: right;
  width: 100%;
}

/* 分页样式 */
.pagination {
  margin: 20px 0;
  display: flex;
  width: 90%;
  margin-left: 5%;
  margin-right: 5%;
  justify-content: flex-end; /* 在大屏幕下靠右显示 */
  margin-top: 20px; /* 在大屏幕下添加顶部间距 */
}

/* 响应式设计优化 */
@media (max-width: 1200px) {
  .goods-market-page {
    max-width: 100%;
  }

  .filter-bar {
    justify-content: center;
  }
}

@media (max-width: 992px) {
  .category-nav {
    padding: 0 10px;
    overflow-x: auto;
  }

  :deep(.el-menu-item) {
    min-width: 80px;
    padding: 0 10px !important;
    font-size: 12px;
  }

  :deep(.el-menu-item img) {
    height: 24px !important;
    margin-right: 4px !important;
  }

  .filter-bar {
    padding: 10px;
    gap: 10px;
  }

  .filter-bar .el-input {
    width: 180px !important;
  }

  .filter-bar .el-select {
    width: 100px !important;
  }
}

@media (max-width: 768px) {
  .goods-market-page {
    padding: 0 5px;
  }

  .category-nav {
    margin-bottom: 10px;
    border-radius: 4px;
  }

  :deep(.el-menu-item) {
    min-width: 70px;
    height: 40px !important;
    line-height: 40px !important;
    font-size: 11px;
  }

  .filter-bar {
    padding: 8px;
    margin-bottom: 10px;
  }

  .filter-bar .el-input {
    width: 150px !important;
  }

  .filter-bar .el-button {
    padding: 8px 12px;
  }

  .products-container {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 10px;
    width: 100%;
    margin-left: 0;
    margin-right: 0;
  }

  .product-item {
    min-width: 140px;
  }

  .product-image {
    height: 140px;
  }

  .product-name {
    font-size: 12px;
  }

  .product-price {
    font-size: 14px;
  }

  .pagination {
    width: 100%;
    margin-left: 0;
    margin-right: 0;
    justify-content: center;
  }

  :deep(.el-pagination) {
    justify-content: center;
  }
}

@media (max-width: 480px) {
  .category-nav {
    padding: 0 5px;
  }

  :deep(.el-menu-item) {
    min-width: 60px;
    padding: 0 8px !important;
    font-size: 10px;
  }

  :deep(.el-menu-item img) {
    height: 20px !important;
  }

  .filter-bar .el-input {
    width: 120px !important;
  }

  .filter-bar .el-select {
    width: 80px !important;
  }

  .filter-bar .el-button span {
    font-size: 12px;
  }

  .products-container {
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .product-item {
    min-width: auto;
  }

  .product-image {
    height: 100px;
  }

  .product-info {
    padding: 6px;
    min-height: 60px;
  }

  .product-name {
    font-size: 11px;
    margin-bottom: 4px;
  }

  .product-price {
    font-size: 12px;
    margin-bottom: 4px;
  }

  .product-other {
    font-size: 10px;
  }

  .pagination {
    margin: 10px 0;
  }

  :deep(.el-pagination) {
    padding: 0;
    font-size: 12px;
  }
}
</style>
