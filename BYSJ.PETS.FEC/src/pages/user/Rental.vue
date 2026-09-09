<template>
  <div class="rental-page">


    <!-- 顶部摄影器材分类导航 -->
    <div class="category-nav">
      <el-menu
        mode="horizontal"
        trigger="hover"
        @select="handleCategorySelect"
        background-color="#67c23a"
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

    <!-- 筛选区域 -->
    <div class="filter-section">
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

        <!-- 搜索框 -->
        <div style="display: flex; align-items: center;">
          <el-input
            v-model="searchKeyword"
            placeholder="输入器材名称"
            size="small"
            style="width: 250px;"
            @keyup.enter="loadGoodsList"
            clearable
          />
          <el-button type="primary" size="small" @click="loadGoodsList" style="margin-left: 5px;">搜索</el-button>
        </div>

        <!-- 排序方式 -->
        <el-select v-model="sortType" placeholder="排序" size="small" @change="loadGoodsList" style="width: 100px;">
          <el-option label="默认排序" value="default" />
          <el-option label="租金从低到高" value="price_asc" />
          <el-option label="租金从高到低" value="price_desc" />
        </el-select>



        <!-- 租金范围筛选 -->
        <el-select v-model="selectedPriceRange" placeholder="租金范围" size="small" @change="handlePriceRangeChange" style="width: 120px;">
          <el-option label="不限" value="" />
          <el-option label="0-50元/天" value="0-50" />
          <el-option label="50-100元/天" value="50-100" />
          <el-option label="100-200元/天" value="100-200" />
          <el-option label="200元/天以上" value="200+" />
        </el-select>
      </div>
    </div>

    <!-- 分割线 -->
    <div class="divider" style="margin: 20px 0;"><el-divider /></div>

    <!-- 商品列表 -->
    <div class="products-container">
      <!-- 空数据提示 -->
      <div v-if="goodsList.length === 0 && !loading" class="empty-tip">
        <el-empty description="暂无相关租赁器材，换个关键词试试吧～" />
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
        <div class="product-item" v-for="(goods, index) in goodsList" :key="`product-${index}`" @click="goToDetail(goods.productId)">
          <div class="product-image">
            <!-- 租赁标签 -->
            <el-tag
              type="warning"
              style="position: absolute; top: 10px; left: 10px;"
            >
              租赁
            </el-tag>
            <img
              :src="goods.imageUrl || '/images/default-product.png'"
              :alt="goods.name"
            />
          </div>
          <div class="product-info">
            <div class="product-name">{{ goods.name }}</div>
            <div class="product-price">¥{{ goods.price }}/天</div>
            <div class="rental-info">
              <span class="deposit">押金: ¥{{ goods.deposit }}</span>
              <span class="min-days">起租: {{ goods.minRentalDays }}天</span>
            </div>
            <div class="product-other">
              <span class="product-seller">卖家: {{ goods.sellerName || '匿名' }}</span>
            </div>
          </div>
        </div>
      </template>
    </div>

    <!-- 分页组件 -->
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { Search } from '@element-plus/icons-vue';
import axios from '@/axios';
// 导入分类数据组件
import CategoryDataComponent from '@/components/CategoryDataComponent.vue';

const route = useRoute();
const router = useRouter();

// 分类数据组件引用
const categoryDataRef = ref(null);

// 顶部导航栏激活索引
const activeMenuIndex = ref("all"); // 默认选中"热门商品"

// 搜索和筛选参数
const searchKeyword = ref('');
const selectedMainCategory = ref("all"); // 选中的主分类
const selectedCategory = ref('');
const selectedBrand = ref('');
const selectedType = ref('');
const selectedPriceRange = ref('');
const sortType = ref('default'); // 默认排序

// 分页参数
const pageNum = ref(1);
const pageSize = ref(10); // 默认每页10条
const total = ref(0);

// 商品数据
const goodsList = ref([]);
const loading = ref(false);

// 从分类数据组件获取主分类列表
const categoryList = computed(() => {
  return categoryDataRef.value?.categoryList || [];
});

// 根据选中的主分类动态获取当前可用的品牌
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
    console.log("查询品牌列表，父ID：", parentId);

    // 3. 调用后端接口获取品牌列表
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

// 根据选中的主分类动态获取当前可用的器材类型（子类）
const currentTypes = ref([]);

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

    // 3. 调用后端接口获取子类
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

// 分类选中事件
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

  // 先加载品牌，再加载器材类型，最后加载商品列表
  loadBrandsByCategory().then(() => {
    loadSubCategories();
    pageNum.value = 1;
    loadGoodsList();
  });
};

// 获取租赁商品列表
const loadGoodsList = async () => {
  try {
    loading.value = true;
    const res = await axios.get('/shop/random-products', {
      params: {
        category: selectedCategory.value,
        brand: selectedBrand.value,
        type: selectedType.value || null,
        keyword: searchKeyword.value,
        sort: sortType.value,
        pageNum: pageNum.value,
        pageSize: pageSize.value,
        productType: 3, // 3表示租赁专用器材
        priceRange: selectedPriceRange.value
      }
    });
    // 检查数据结构，处理可能的嵌套情况
    const data = res.data || res;
    goodsList.value = data.list || [];
    total.value = data.total || 0;
  } catch (error) {
    console.error('获取租赁器材失败:', error);
    ElMessage.error('获取租赁器材失败，请稍后重试');
    goodsList.value = [];
    total.value = 0;
  } finally {
    loading.value = false;
  }
};

// 搜索功能
const handleSearch = () => {
  pageNum.value = 1;
  loadGoodsList();
};

// 租金范围变化处理
const handlePriceRangeChange = (value) => {
  console.log('租金范围变化:', value);
  console.log('selectedPriceRange:', selectedPriceRange.value);
  pageNum.value = 1;
  loadGoodsList();
};

// 分页变化
const handleSizeChange = (size) => {
  pageSize.value = size;
  loadGoodsList();
};

const handleCurrentChange = (current) => {
  pageNum.value = current;
  loadGoodsList();
};

// 跳转到商品详情页
const goToDetail = (productId) => {
  router.push(`/rental/detail/${productId}`);
};

// 初始化数据
onMounted(() => {
  // 加载热门商品
  selectedMainCategory.value = "all";
  selectedCategory.value = "";
  selectedBrand.value = "";
  selectedType.value = "";

  // 处理URL参数中的搜索关键词
  if (route.query.keyword) {
    searchKeyword.value = route.query.keyword;
  }

  loadBrandsByCategory();
  loadSubCategories();
  loadGoodsList();
});

// 监听路由变化
watch(() => route.params, () => {
  // 重置筛选条件
  searchKeyword.value = '';
  selectedMainCategory.value = "all";
  selectedCategory.value = '';
  selectedBrand.value = '';
  selectedType.value = '';
  selectedPriceRange.value = '';
  sortType.value = 'default';
  activeMenuIndex.value = "all";
  pageNum.value = 1;
  loadBrandsByCategory();
  loadSubCategories();
  loadGoodsList();
});
</script>

<style scoped>
.rental-page {
  padding: 0 20px;
  max-width: 95%;
  margin: 0 auto;
  min-width: 320px;
}

.breadcrumb {
  margin-bottom: 20px;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #333;
}

/* 分类导航样式 - 核心修改 */
.category-nav {
  margin-bottom: 20px;
  width: 100%;
  padding: 0 20px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(103, 194, 58, 0.2);
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
  background-color: #4CAF50 !important;
  color: #fff !important;
}

:deep(.el-menu-item:hover) {
  background-color: #85CE61 !important;
  color: #fff !important;
}

/* 筛选栏样式 */
.filter-section {
  margin-bottom: 20px;
  width: 90%;
  margin-left: 5%;
  margin-right: 5%;
}

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

.products-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
  width: 90%;
  margin-left: 5%;
  margin-right: 5%;
  /* 设置最小高度，确保无数据时也有足够高度居中 */
  min-height: 200px;
  align-items: center;
}

.product-item {
  background-color: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  cursor: pointer;
  min-width: 200px;
  width: 100%;
}

.product-item:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(103, 194, 58, 0.5); /* 使用导航栏背景色作为阴影颜色 */
}

.product-image {
  width: 100%;
  height: 200px;
  position: relative;
  overflow: hidden;
  background-color: #f5f5f5;
  display: flex;
  align-items: center;
  justify-content: center;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  transition: transform 0.3s ease;
}

.product-item:hover .product-image img {
  transform: scale(1.05);
}

.product-info {
  padding: 10px;
  display: flex;
  flex-direction: column;
  text-align: right;
  position: relative;
  min-height: 80px;
}

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

.product-price {
  font-size: 18px;
  font-weight: bold;
  color: #ff4d4f;
  margin-bottom: 8px;
  text-align: right;
}

.rental-info {
  font-size: 12px;
  color: #666;
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
  text-align: right;
}

.deposit {
  color: #409eff;
}

.min-days {
  color: #67c23a;
}

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

.empty-tip {
  grid-column: 1 / -1;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 400px;
  background-color: #fafafa;
  border-radius: 8px;
  width: 100%;
}

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
  .rental-page {
    max-width: 100%;
  }

  .filter-bar {
    justify-content: center; /* 在大屏幕下居中显示 */
  }
}

@media (max-width: 768px) {
  .rental-page {
    padding: 0 10px;
  }

  .products-container {
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); /* 小屏幕下减小列宽 */
    gap: 15px;
  }

  .product-item {
    min-width: 160px;
  }

  .product-image {
    height: 160px; /* 小屏幕下减小图片高度 */
  }

  .empty-tip {
    height: 300px;
  }
}

@media (max-width: 480px) {
  .filter-section,
  .products-container,
  .pagination {
    width: 100%;
    margin-left: 0;
    margin-right: 0;
  }

  .products-container {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); /* 超小屏幕下进一步减小列宽 */
    gap: 10px;
  }

  .product-item {
    min-width: 140px;
  }

  .product-image {
    height: 160px; /* 小屏幕下减小图片高度 */
  }

  .empty-tip {
    height: 250px;
  }
}
</style>
