<template>
  <div class="rental-detail-page" :key="route.params.id">
    <!-- 面包屑导航 -->
    <div class="breadcrumb">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/rental' }">租赁市场</el-breadcrumb-item>
        <el-breadcrumb-item>{{ product.name }}</el-breadcrumb-item>
      </el-breadcrumb>
    </div>

    <!-- 商品详情主体 -->
    <div class="product-main" v-loading="loading">
      <!-- 左侧：商品图片 -->
      <div class="product-gallery">
        <div class="main-image">
          <el-carousel :interval="0" :autoplay="false" height="350px" :show-arrow="productImages.length > 1 ? 'hover' : false">
            <el-carousel-item v-for="(image, index) in productImages" :key="index">
              <img :src="image" :alt="`${product.name} 图片${index + 1}`" @error="handleImageError" />
            </el-carousel-item>
          </el-carousel>
        </div>
      </div>

      <!-- 右侧：商品基本信息 -->
      <div class="product-info">
        <h1 class="product-title">{{ product.name }}</h1>
        <div class="product-price-section">
          <span class="current-price">¥{{ product.price }}/天</span>
        </div>

        <!-- 租赁基本信息 -->
        <div class="rental-basic-info">
          <div class="info-item">
            <span class="info-label">押金：</span>
            <span class="info-value deposit">¥{{ product.deposit }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">起租天数：</span>
            <span class="info-value">{{ product.minRentalDays }}天</span>
          </div>
          <div class="info-item">
            <span class="info-label">最长租赁：</span>
            <span class="info-value">{{ product.maxRentalDays }}天</span>
          </div>
          <div class="info-item">
            <span class="info-label">保险费用：</span>
            <span class="info-value">{{ product.insuranceFee > 0 ? `¥${product.insuranceFee}/天` : '免费' }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">配送费用：</span>
            <span class="info-value">{{ product.deliveryFee > 0 ? `¥${product.deliveryFee}` : '免费配送' }}</span>
          </div>
        </div>

        <!-- 商品规格 -->
        <div class="product-specs">
          <div class="spec-item" v-for="(value, key) in product.specifications" :key="key">
            <span class="spec-label">{{ key }}：</span>
            <span class="spec-value">{{ value }}</span>
          </div>
        </div>

        <!-- 操作按钮 -->
        <div class="action-buttons">
          <el-button
            type="primary"
            size="large"
            :disabled="product.stock <= 0"
            @click="addToCart"
          >
            <el-icon><ShoppingCart /></el-icon>
            加入购物车
          </el-button>
          <el-button
            type="success"
            size="large"
            :disabled="product.stock <= 0"
            @click="rentNow"
          >
            <el-icon><CreditCard /></el-icon>
            立即租赁
          </el-button>
          <el-button
            :type="isFavorited ? 'danger' : 'default'"
            size="large"
            @click="toggleFavorite"
          >
            <el-icon><Star /></el-icon>
            {{ isFavorited ? '已收藏' : '收藏' }}
          </el-button>
        </div>
      </div>
    </div>

    <!-- 商品图片下方：租赁信息和规则水平排列，宽度适合容器左右边 -->
    <div class="rental-info-full-width">
      <!-- 租赁时间选择 -->
      <div class="rental-time-section">
        <h3 class="section-title">选择租赁时间</h3>
        <div class="time-selector">
          <el-date-picker
            v-model="rentalDateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            :disabled-date="disabledDate"
            @change="onRentalDateChange"
            style="width: 100%; margin-bottom: 12px;"
          />
          <div class="rental-days-display" style="font-size: 14px; color: #606266; margin-bottom: 15px;">
            <span>租赁天数：</span>
            <span class="days-value" style="font-weight: 600; color: #303133;">{{ rentalDays }}天</span>
          </div>
        </div>

        <!-- 费用明细 -->
        <div class="fee-details">
          <div class="fee-item">
            <span>租金：</span>
            <span class="fee-value">¥{{ totalRentalFee }}</span>
          </div>
          <div class="fee-item">
            <span>押金：</span>
            <span class="fee-value">¥{{ product.deposit }}</span>
          </div>
          <div class="fee-item">
            <span>保险：</span>
            <span class="fee-value">¥{{ totalInsuranceFee }}</span>
          </div>
          <div class="fee-item">
            <span>配送：</span>
            <span class="fee-value">¥{{ product.deliveryFee }}</span>
          </div>
          <div class="fee-item total">
            <span>总计：</span>
            <span class="fee-value total-value">¥{{ totalAmount }}</span>
          </div>
        </div>
      </div>

      <!-- 租赁规则 -->
      <div class="rental-rules">
        <h3 class="section-title">租赁规则</h3>
        <div class="rule-content">
          <div class="rule-item">
            <h4>通用规则</h4>
            <p>1. 租客需年满18周岁，持有有效身份证件</p>
            <p>2. 租赁前需缴纳押金，押金将在归还器材且验收无误后3-5个工作日内退还</p>
            <p>3. 租赁期间，器材损坏或丢失需按损坏赔偿规则进行赔偿</p>
            <p>4. 逾期归还将收取逾期违约金</p>
          </div>
          <div class="rule-item">
            <h4>损坏赔偿规则</h4>
            <p>{{ product.damageFeeRule || '请联系客服了解详细赔偿规则' }}</p>
          </div>
          <div class="rule-item">
            <h4>逾期规则</h4>
            <p>1. 逾期1-3天：每天收取租金的5%作为违约金</p>
            <p>2. 逾期4-7天：每天收取租金的10%作为违约金</p>
            <p>3. 逾期超过7天：视为违约，将收取押金的50%作为违约金，并保留追究法律责任的权利</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 商品描述 -->
    <div class="product-description">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="商品详情" name="detail">
          <div class="description-content" v-html="product.description"></div>
        </el-tab-pane>
        <el-tab-pane label="规格参数" name="specs">
          <div class="specs-content">
            <el-descriptions :column="2" border>
              <el-descriptions-item
                v-for="(value, key) in product.specifications"
                :key="key"
                :label="key"
              >
                {{ value }}
              </el-descriptions-item>
            </el-descriptions>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>

    <!-- 相关推荐 -->
    <div class="related-products">
      <h3>相关推荐</h3>
      <div class="related-list">
        <div
            class="related-item"
            v-for="item in relatedProducts"
            :key="item.id || item.productId"
            @click="goToRentalDetail(item.id || item.productId, item)"
          >
            <img :src="item.imageUrl" :alt="item.name" />
            <div class="related-info">
              <div class="related-name">{{ item.name }}</div>
              <div class="related-price">¥{{ item.price }}/天</div>
            </div>
          </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ElMessage, ElMessageBox } from 'element-plus';
import { ShoppingCart, CreditCard, Star } from '@element-plus/icons-vue';
import axios from '@/axios';
import { useUserStore } from '@/stores/user';

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();

// 商品数据
const product = ref({
  id: 0,
  name: '',
  brandName: '',
  price: 0,
  originalPrice: 0,
  stock: 0,
  imageUrl: '',
  description: '',
  specifications: {},
  categoryId: null,
  condition: 0,
  sellerId: 0,
  sellerName: '',
  sellerType: 1,
  imageUrls: [],
  // 租赁特有字段
  deposit: 0,
  maxRentalDays: 90,
  minRentalDays: 1,
  insuranceFee: 0,
  lateFeeRate: 0.05,
  damageFeeRule: '',
  pickupMethods: 'delivery',
  deliveryFee: 0
});

// 租赁天数选择
const rentalDays = ref(1);
// 租赁日期范围
const rentalDateRange = ref([]);

// 计算的费用
const totalRentalFee = ref(0);
const totalInsuranceFee = ref(0);
const totalAmount = ref(0);

const loading = ref(true);
const activeTab = ref('detail');
const isFavorited = ref(false);
const relatedProducts = ref([]);

// 计算属性：商品图片列表
const productImages = computed(() => {
  const images = [];
  // 添加主图
  if (product.value.imageUrl) {
    images.push(product.value.imageUrl);
  }
  // 添加其他图片
  if (product.value.imageUrls && Array.isArray(product.value.imageUrls)) {
    product.value.imageUrls.forEach(img => {
      if (img && !images.includes(img)) {
        images.push(img);
      }
    });
  }
  // 如果没有图片，添加一个默认图片
  if (images.length === 0) {
    images.push('/images/default-product.png');
  }
  return images;
});

// 禁用日期（今天之前的日期）
const disabledDate = (time) => {
  return time.getTime() < Date.now() - 8.64e7;
};

// 租赁日期范围变化处理
const onRentalDateChange = (dateRange) => {
  if (dateRange && dateRange.length === 2) {
    const startDate = dateRange[0];
    const endDate = dateRange[1];

    // 计算租赁天数
    const diffTime = endDate.getTime() - startDate.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    // 确保租赁天数在允许范围内
    rentalDays.value = Math.max(product.value.minRentalDays, Math.min(diffDays, product.value.maxRentalDays));
    calculateTotal();
  }
};

// 获取商品详情
const fetchProductDetail = async () => {
  try {
    loading.value = true;
    const productId = route.params.id;
    console.log('当前租赁商品ID:', productId);
    const res = await axios.get(`/shop/products/${productId}`);
    console.log('商品详情数据:', res);

    // 处理后端返回的数据
    const productData = (res && res.data) || {};
    console.log('productData:', productData);

    product.value = {
      id: productData.id || productId,
      name: productData.name || '商品名称',
      brandName: productData.brandName || '品牌',
      price: productData.price || 0,
      originalPrice: productData.originalPrice || 0,
      stock: productData.stock || 0,
      categoryId: productData.categoryId || null,
      imageUrl: productData.imageUrl,
      description: productData.description || '暂无商品描述',
      specifications: productData.specifications || {},
      condition: productData.condition || 0,
      sellerId: productData.sellerId || 0,
      sellerName: productData.sellerName || '匿名',
      sellerType: productData.sellerType || 1,
      imageUrls: productData.imageUrls || [],
      // 租赁特有字段
      deposit: productData.deposit || 0,
      maxRentalDays: productData.maxRentalDays || 90,
      minRentalDays: productData.minRentalDays || 1,
      insuranceFee: productData.insuranceFee || 0,
      lateFeeRate: productData.lateFeeRate || 0.05,
      damageFeeRule: productData.damageFeeRule || '',
      pickupMethods: productData.pickupMethods || 'delivery',
      deliveryFee: productData.deliveryFee || 0
    };

    // 初始化租赁天数为最小租赁天数
    rentalDays.value = product.value.minRentalDays;
    calculateTotal();

    // 检查是否已收藏
    if (userStore.isLoggedIn) {
      try {
        const favoriteRes = await axios.get(`/favorites/check?productId=${productId}`);
        isFavorited.value = (favoriteRes && favoriteRes.isFavorited) || false;
      } catch (error) {
        console.error('检查收藏状态失败:', error);
      }
    }

    // 获取相关商品推荐
    if (product.value.categoryId) {
      try {
        const relatedRes = await axios.get(`/shop/related`, {
          params: {
            categoryId: product.value.categoryId,
            limit: 4,
            productId: product.value.id
          }
        });
        relatedProducts.value = (relatedRes && relatedRes.data) || [];
      } catch (error) {
        console.error('获取相关商品失败:', error);
        relatedProducts.value = [];
      }
    }
  } catch (error) {
    console.error('获取商品详情失败:', error);
    ElMessage.error('获取商品详情失败');
  } finally {
    loading.value = false;
  }
};

// 计算总费用
const calculateTotal = () => {
  // 计算租金
  totalRentalFee.value = product.value.price * rentalDays.value;
  // 计算保险费用
  totalInsuranceFee.value = product.value.insuranceFee * rentalDays.value;
  // 计算总金额
  totalAmount.value = totalRentalFee.value + product.value.deposit + totalInsuranceFee.value + product.value.deliveryFee;
};

// 加入购物车
const addToCart = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    await axios.post('/cart/add', {
      productId: product.value.id,
      quantity: 1,
      leaseTerm: rentalDays.value
    });
    ElMessage.success('已加入购物车');
  } catch (error) {
    console.error('加入购物车失败:', error);
    ElMessage.error('加入购物车失败');
  }
};

// 立即租赁
const rentNow = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    // 跳转到订单确认页，携带productIds参数
    const queryParams = {
      productIds: product.value.id,
      leaseTerm: rentalDays.value
    };

    // 如果用户选择了租赁日期范围，也携带日期参数
    if (rentalDateRange.value && rentalDateRange.value.length === 2) {
      queryParams.startDate = rentalDateRange.value[0].toISOString().split('T')[0];
      queryParams.endDate = rentalDateRange.value[1].toISOString().split('T')[0];
    }

    router.push({
      path: '/order/confirm',
      query: queryParams
    });
  } catch (error) {
    console.error('创建订单失败:', error);
    ElMessage.error('创建订单失败');
  }
};

// 收藏/取消收藏
const toggleFavorite = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    if (isFavorited.value) {
      // 取消收藏
      await axios.delete(`/favorites`, {
        params: { productId: product.value.id }
      });
      isFavorited.value = false;
      ElMessage.success('取消收藏成功');
    } else {
      // 添加收藏
      await axios.post('/favorites', { productId: product.value.id });
      isFavorited.value = true;
      ElMessage.success('收藏成功');
    }
  } catch (error) {
    console.error('操作失败:', error);
    ElMessage.error('操作失败');
  }
};

// 跳转到租赁商品详情页
const goToRentalDetail = (productId, item) => {
  router.push(`/rental/detail/${productId}`);
};

// 图片错误处理函数
  const handleImageError = (e) => {
    // 移除error事件监听器，避免无限循环
    e.target.removeEventListener('error', handleImageError);
    // 设置一个简单的背景色和文字，而不是使用不存在的占位图
    e.target.style.backgroundColor = '#f5f7fa';
    e.target.style.color = '#909399';
    e.target.style.display = 'flex';
    e.target.style.alignItems = 'center';
    e.target.style.justifyContent = 'center';
    e.target.style.fontSize = '12px';
    e.target.alt = '图片加载失败';
  };

// 监听路由变化
watch(() => route.params.id, () => {
  fetchProductDetail();
});

// 初始化数据
onMounted(() => {
  fetchProductDetail();
});
</script>

<style scoped>
.rental-detail-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 15px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

/* 面包屑导航 */
.breadcrumb {
  margin-bottom: 15px;
  font-size: 14px;
}

/* 商品主体 */
.product-main {
  display: flex;
  gap: 30px;
  margin-bottom: 30px;
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

/* 商品图片 */
.product-gallery {
  flex: 0 0 400px;
}

.main-image {
  width: 100%;
  height: 350px;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  overflow: hidden;
  background: #fafafa;
}

.main-image :deep(.el-carousel__item) {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  background: #f5f7fa;
}

.main-image :deep(.el-carousel__item img) {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  transition: transform 0.3s ease;
}

.main-image :deep(.el-carousel__item:hover img) {
  transform: scale(1.02);
}

.main-image :deep(.el-carousel__button) {
  background-color: rgba(0, 0, 0, 0.3);
}

.main-image :deep(.is-active .el-carousel__button) {
  background-color: #409eff;
}

/* 商品信息 */
.product-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

/* 商品标题 */
.product-title {
  font-size: 22px;
  font-weight: 600;
  margin-bottom: 15px;
  color: #303133;
  line-height: 1.3;
}

/* 价格区域 */
.product-price-section {
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #f0f0f0;
}

.current-price {
  font-size: 26px;
  color: #ff4d4f;
  font-weight: 700;
  margin-right: 10px;
}

/* 基本信息区域 */
.rental-basic-info {
  background: #f5f7fa;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 15px;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

.info-item {
  display: flex;
  align-items: center;
}

.info-label {
  color: #606266;
  min-width: 80px;
  font-size: 14px;
}

.info-value {
  color: #303133;
  font-weight: 500;
  font-size: 14px;
}

.deposit {
  color: #409eff;
}

/* 规格信息 */
.product-specs {
  margin-bottom: 15px;
  padding: 15px;
  background: #f5f7fa;
  border-radius: 8px;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
}

.spec-item {
  display: flex;
  align-items: center;
  font-size: 14px;
}

.spec-label {
  color: #606266;
  min-width: 70px;
}

.spec-value {
  color: #303133;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 租赁时间选择 */
.rental-time-section {
  margin-bottom: 15px;
  padding: 15px;
  background: #ecf5ff;
  border-radius: 8px;
  border: 1px solid #d9ecff;
}

.section-title {
  font-size: 15px;
  margin-bottom: 12px;
  color: #303133;
  font-weight: 600;
}

.time-selector {
  margin-bottom: 15px;
}

/* 费用明细 */
.fee-details {
  background: #fff;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #ebeef5;
}

.fee-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 14px;
}

.fee-item.total {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #ebeef5;
  font-weight: 600;
  font-size: 15px;
}

.fee-value {
  color: #ff4d4f;
}

.fee-value.total-value {
  font-size: 18px;
  font-weight: 700;
}

/* 租赁信息和规则水平排列容器 */
.rental-info-full-width {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

/* 租赁规则 */
.rental-rules {
  flex: 1;
  padding: 15px;
  background: #fef0f0;
  border-radius: 8px;
  border: 1px solid #fee2e2;
  min-height: 300px;
}

/* 租赁时间选择 */
.rental-time-section {
  flex: 1;
  padding: 15px;
  background: #ecf5ff;
  border-radius: 8px;
  border: 1px solid #d9ecff;
  min-height: 300px;
}

.rule-content {
  background: #fff;
  padding: 12px;
  border-radius: 6px;
  font-size: 14px;
}

.rule-item {
  margin-bottom: 15px;
}

.rule-item:last-child {
  margin-bottom: 0;
}

.rule-item h4 {
  color: #e6a23c;
  margin-bottom: 8px;
  font-size: 14px;
  font-weight: 600;
}

.rule-item p {
  margin: 4px 0;
  line-height: 1.4;
  color: #606266;
  font-size: 13px;
}

/* 操作按钮 */
.action-buttons {
  display: flex;
  gap: 12px;
  margin-top: auto;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
}

.action-buttons .el-button {
  flex: 1;
  height: 42px;
  font-weight: 600;
  border-radius: 8px;
  border: none;
  transition: all 0.3s ease;
}

.action-buttons .el-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.action-buttons .el-button--primary {
  background: #409eff;
}

.action-buttons .el-button--primary:hover {
  background: #66b1ff;
}

.action-buttons .el-button--success {
  background: #67c23a;
}

.action-buttons .el-button--success:hover {
  background: #85ce61;
}

/* 商品描述 */
.product-description {
  margin-bottom: 30px;
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

.product-description :deep(.el-tabs__header) {
  margin-bottom: 20px;
}

.product-description :deep(.el-tabs__nav-wrap) {
  padding-left: 0;
}

.product-description :deep(.el-tabs__item) {
  font-size: 15px;
  color: #606266;
  padding: 0 20px;
  height: 40px;
  line-height: 40px;
}

.product-description :deep(.el-tabs__item.is-active) {
  color: #409eff;
  font-weight: 600;
}

.product-description :deep(.el-tabs__active-bar) {
  height: 3px;
  background: #409eff;
}

.description-content {
  line-height: 1.6;
  color: #303133;
  font-size: 14px;
}

/* 规格参数 */
.specs-content :deep(.el-descriptions) {
  margin: 0;
}

.specs-content :deep(.el-descriptions__header) {
  display: none;
}

.specs-content :deep(.el-descriptions__table) {
  width: 100%;
}

.specs-content :deep(.el-descriptions__label) {
  color: #606266;
  font-weight: 500;
  width: 120px;
  padding: 10px 15px;
  background: #f5f7fa;
  border-right: 1px solid #ebeef5;
}

.specs-content :deep(.el-descriptions__content) {
  color: #303133;
  padding: 10px 15px;
  border-right: 1px solid #ebeef5;
}

.specs-content :deep(.el-descriptions__row:last-child .el-descriptions__content) {
  border-bottom: none;
}

.specs-content :deep(.el-descriptions__row:last-child .el-descriptions__label) {
  border-bottom: none;
}

/* 相关推荐 */
.related-products {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.05);
}

.related-products h3 {
  margin-bottom: 18px;
  font-size: 16px;
  color: #303133;
  font-weight: 600;
  padding-bottom: 10px;
  border-bottom: 2px solid #f0f0f0;
}

.related-list {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 15px;
}

.related-item {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  background: #fff;
}

.related-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: #409eff;
}

.related-item img {
  width: 100%;
  height: 100px;
  object-fit: contain;
  margin-bottom: 8px;
  background: #fafafa;
  border-radius: 6px;
}

.related-name {
  font-size: 13px;
  margin-bottom: 5px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: #303133;
  line-height: 1.3;
}

.related-price {
  font-size: 15px;
  color: #ff4d4f;
  font-weight: 600;
}

/* 响应式设计 */
@media (max-width: 1024px) {
  .product-gallery {
    flex: 0 0 350px;
  }

  .main-image {
    height: 300px;
  }

  .related-list {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .rental-detail-page {
    padding: 10px;
  }

  .product-main {
    flex-direction: column;
    gap: 20px;
    padding: 15px;
  }

  .product-gallery {
    flex: none;
    width: 100%;
  }

  .main-image {
    height: 250px;
  }

  /* 小屏幕下租赁信息和规则垂直排列 */
  .rental-info-row {
    flex-direction: column;
  }

  /* 小屏幕下每个卡片的最小高度调整 */
  .rental-time-section,
  .rental-rules {
    min-height: auto;
  }

  .rental-basic-info,
  .product-specs {
    grid-template-columns: 1fr;
  }

  .related-list {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }

  .action-buttons {
    flex-direction: column;
  }

  .action-buttons .el-button {
    height: 38px;
  }

  .product-title {
    font-size: 20px;
  }

  .current-price {
    font-size: 24px;
  }
}

@media (max-width: 480px) {
  .related-list {
    grid-template-columns: 1fr;
  }

  .product-main {
    padding: 12px;
  }

  .product-description,
  .related-products {
    padding: 15px;
  }
}
</style>
