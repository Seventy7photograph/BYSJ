<template>
  <div class="goods-market-page">
    <!-- 1. 顶部摄影器材分类导航 -->
    <div class="category-nav">
      <el-menu
        mode="horizontal"
        trigger="hover"
        @select="handleCategorySelect"
        background-color="#ffa726"
        text-color="#333"
        active-text-color="#fff"
        style="border-bottom: 1px solid #e6e6e6; height: 48px; line-height: 48px;"
        v-model:default-active="activeMenuIndex"
      >
        <!-- 热门二手 -->
        <el-menu-item index="all">
          <img src="/public/热门.png" alt="热门二手" style="height: 32px; margin-right: 6px;">
          <span>热门二手</span>
        </el-menu-item>

        <!-- 摄影器材主分类 -->
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

    <!-- 2. 筛选栏 -->
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

      <!-- 成色筛选 -->
      <el-select v-model="selectedCondition" placeholder="成色" size="small" @change="loadGoodsList" style="width: 120px;">
        <el-option label="全部" value="" />
        <el-option label="99新" value="99" />
        <el-option label="95新" value="95" />
        <el-option label="90新" value="90" />
        <el-option label="80新" value="80" />
      </el-select>

      <!-- 搜索框 -->
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

    <!-- 3. 商品卡片列表 -->
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
        <div class="product-item" v-for="(goods, index) in goodsList" :key="`product-${index}`" @click="goToDetail(goods.productId)">
          <div class="product-image">
            <!-- 商品标签（显示二手） -->
            <el-tag
              type="info"
              style="position: absolute; top: 10px; left: 10px;"
            >
              二手
            </el-tag>
            <img
              :src="goods.imageUrl || '/images/default-product.png'"
              :alt="goods.name"
            >
          </div>
          <div class="product-info">
            <div class="product-name">{{ formatProductName(goods.name) }}</div>
            <div class="product-price">¥{{ goods.price }}</div>
            <div class="product-condition">成色: {{ getConditionLabel(goods.condition) }}</div>
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import axios from '@/axios';
// 导入分类数据组件
import CategoryDataComponent from '@/components/CategoryDataComponent.vue';

// 路由实例
const router = useRouter();
const route = useRoute();

// 分类数据组件引用
const categoryDataRef = ref(null);

// 获取成色标签的函数，确保能正确处理各种类型的condition值
const getConditionLabel = (condition) => {
  // 确保condition是字符串或数字类型
  const conditionKey = String(condition);

  // 成色映射表，支持两种编码方式
  const conditionMap = {
    // 前端筛选使用的编码（1-4）
    '1': '99新',
    '2': '95新',
    '3': '90新',
    '4': '80新',
    1: '99新',
    2: '95新',
    3: '90新',
    4: '80新',
    // 后端返回的实际成色值
    '99': '99新',
    '95': '95新',
    '90': '90新',
    '80': '80新',
    99: '99新',
    95: '95新',
    90: '90新',
    80: '80新'
  };

  // 如果直接映射不存在，尝试从数值中提取规律
  if (!conditionMap[conditionKey]) {
    // 检查是否是数字格式
    const num = parseInt(conditionKey);
    if (!isNaN(num)) {
      // 如果是数字，直接返回如"80新"的格式
      return `${num}新`;
    }
  }

  return conditionMap[conditionKey] || '未知';
};

// 获取成色标签类型的函数
const getConditionType = (condition) => {
  const conditionKey = String(condition);

  // 成色类型映射表，支持两种编码方式
  const typeMap = {
    // 前端筛选使用的编码（1-4）
    '1': 'success', // 99新 - 成功色
    '2': 'warning', // 95新 - 警告色
    '3': 'info',    // 90新 - 信息色
    '4': 'info',     // 80新 - 信息色
    1: 'success',
    2: 'warning',
    3: 'info',
    4: 'info',
    // 后端返回的实际成色值
    '99': 'success',
    '95': 'warning',
    '90': 'info',
    '80': 'info',
    99: 'success',
    95: 'warning',
    90: 'info',
    80: 'info'
  };

  return typeMap[conditionKey] || 'info';
};

// 添加格式化产品名称的方法
const formatProductName = (name) => {
  // 去掉产品名称前面的数字编号（如去掉"12 "、"11 "等）
  // 使用正则表达式匹配开头的数字和空格，然后去掉
  return name.replace(/^\d+\s*/, '');
};

// 商品详情跳转
const goToDetail = (goodsId) => {
  router.push(`/second-hand/detail/${goodsId}`);
};

// 1. 摄影器材分类数据（从组件中获取，并过滤掉存储设备）
const categoryList = computed(() => {
  const list = categoryDataRef.value?.categoryList || [];
  // 过滤掉存储设备分类（id: 6）
  return list.filter(item => item.id !== 6);
});

// 添加菜单激活状态变量
const activeMenuIndex = ref("all"); // 默认选中"热门二手"

// 2. 筛选/分页参数
const selectedCategory = ref(""); // 选中的子分类
const selectedMainCategory = ref("all"); // 选中的主分类（用于动态显示品牌和类型）
const selectedBrand = ref(""); // 品牌
const selectedType = ref(""); // 器材类型
const selectedCondition = ref(""); // 成色筛选
const searchKeyword = ref(""); // 搜索关键词
const sortType = ref("price_asc"); // 排序方式
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
    selectedCondition.value = "";
  } else {
    selectedMainCategory.value = menuIndex;
    selectedCategory.value = menuIndex;
    selectedBrand.value = "";
    selectedType.value = "";
    selectedCondition.value = "";
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
      quality: "used",                 // 加载二手商品
      condition: selectedCondition.value || ""
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

    // 检查数据结构，处理可能的嵌套情况
    const data = res.data || res;
    goodsList.value = data.list || [];
    total.value = data.total || 0;

    // 详细调试信息：查看商品列表的结构和condition字段
    console.log('完整商品列表：', goodsList.value);
    if (goodsList.value.length > 0) {
      console.log('第一个商品详情：', goodsList.value[0]);
      console.log('第一个商品的condition字段：', goodsList.value[0].condition);
    }
  } catch (err) {
    console.error("加载二手商品失败：", err);
    goodsList.value = [];
    total.value = 0;
  } finally {
    loading.value = false;
  }
};

// 7. 分页事件
const handleSizeChange = (val) => {
  pageSize.value = val;
  loadGoodsList();
};
const handleCurrentChange = (val) => {
  pageNum.value = val;
  loadGoodsList();
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

  // 先加载品牌和分类，再加载商品列表
  loadBrandsByCategory()
    .then(() => loadSubCategories())
    .then(() => loadGoodsList());

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
  min-width: 320px;
  background-color: #f5f7fa; /* 二手交易专用背景色 */
}

/* 分类导航样式 - 二手交易专用配色 */
.category-nav {
  background-color: #ffa726; /* 橙色主题 */
  padding: 0 20px;
  margin-bottom: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(255, 167, 38, 0.2);
}

:deep(.el-menu) {
  background-color: transparent !important;
  text-color: #fff !important;
  active-text-color: #fff !important;
}

:deep(.el-menu-item) {
  color: #fff !important;
  height: 48px !important;
  line-height: 48px !important;
  text-align: center;
  font-size: 14px;
  display: flex;
  justify-content: center !important;
  align-items: center !important;
  padding: 0 15px !important;
  min-width: 100px;
}

:deep(.el-menu-item:hover) {
  background-color: #ff9800 !important; /* 深橙色 */
  color: #fff !important;
}

:deep(.el-menu-item.is-active) {
  background-color: #f57c00 !important; /* 更深的橙色 */
  color: #fff !important;
}

/* 筛选栏样式 */
.filter-bar {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  flex-wrap: wrap;
  gap: 15px;
  justify-content: flex-end;
  background-color: #fff;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.filter-btn {
  background-color: #f0f0f0;
  color: #333;
}

.filter-btn:hover {
  background-color: #ffa726;
  color: white;
}

/* 商品列表容器样式 */
.products-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
  width: 90%;
  margin-left: 5%;
  margin-right: 5%;
  min-height: 200px;
  align-items: center;
}

/* 空提示容器 */
.empty-tip {
  grid-column: 1 / -1;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 400px;
}

/* 商品项样式 */
.product-item {
  display: flex;
  flex-direction: column;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  min-width: 200px;
  width: 100%;
  background-color: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  position: relative;
}

.product-item:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(255, 167, 38, 0.3);
}

/* 商品图片容器 */
.product-image {
  width: 100%;
  height: 200px;
  overflow: hidden;
  background-color: #fafafa;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

/* 商品图片 */
.product-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
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
  text-align: right;
  position: relative;
  min-height: 80px;
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

/* 商品成色 */
.product-condition {
  font-size: 14px;
  color: #ffa726;
  margin-bottom: 8px;
  font-weight: 500;
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

.product-quality {
  color: #ffa726;
  font-weight: 500;
  margin-right: 8px;
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
  justify-content: flex-end;
  margin-top: 20px;
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

@media (max-width: 768px) {
  .goods-market-page {
    padding: 0 10px;
  }

  .products-container {
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 15px;
  }

  .product-item {
    min-width: 160px;
  }

  .product-image {
    height: 160px;
  }

  .products-container {
    min-height: 300px;
  }

  .empty-tip {
    height: 300px;
  }

  .filter-bar {
    flex-direction: column;
    align-items: stretch;
  }

  .filter-bar .el-select,
  .filter-bar .el-input {
    width: 100% !important;
    margin-left: 0 !important;
  }
}

@media (max-width: 480px) {
  .products-container {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 10px;
  }

  .product-item {
    min-width: 140px;
  }

  .product-image {
    height: 140px;
  }

  .products-container {
    min-height: 250px;
  }

  .empty-tip {
    height: 250px;
  }
}
</style>
