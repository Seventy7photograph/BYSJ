<template>
  <div class="product-detail-page" :key="route.params.id">
    <!-- 面包屑导航 -->
    <div class="breadcrumb">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/shop' }">器材商城</el-breadcrumb-item>
        <el-breadcrumb-item>{{ product.brandName }}</el-breadcrumb-item>
        <el-breadcrumb-item>{{ product.name }}</el-breadcrumb-item>
      </el-breadcrumb>
    </div>

    <!-- 商品详情主体 -->
    <div class="product-main" v-loading="loading">
      <!-- 商品图片 -->
      <div class="product-gallery">
        <div class="main-image">
          <el-carousel :interval="0" :autoplay="false" height="400px" :show-arrow="productImages.length > 1 ? 'hover' : false">
            <el-carousel-item v-for="(image, index) in productImages" :key="index">
              <img :src="image" :alt="`${product.name} 图片${index + 1}`" @error="handleImageError" />
            </el-carousel-item>
          </el-carousel>
        </div>
      </div>

      <!-- 商品信息 -->
      <div class="product-info">
        <h1 class="product-title">{{ product.brandName }} {{ product.name }}</h1>
        <div class="product-price-section">
          <span class="current-price">¥{{ product.price }}</span>
          <span v-if="product.originalPrice" class="original-price">¥{{ product.originalPrice }}</span>
        </div>

        <!-- 规格信息 -->
        <div class="product-specs">
          <div class="spec-item">
            <span class="spec-label">品牌：</span>
            <span class="spec-value">{{ product.brandName }}</span>
          </div>
          <div class="spec-item">
            <span class="spec-label">卖家：</span>
            <span class="spec-value">{{ product.sellerName || '匿名' }}</span>
          </div>
        </div>

        <!-- 操作按钮 -->
        <div class="action-buttons">
          <el-button
            type="primary"
            size="large"
            @click="addToCart"
          >
            <el-icon><ShoppingCart /></el-icon>
            加入购物车
          </el-button>
          <el-button
            type="success"
            size="large"
            @click="buyNow"
          >
            <el-icon><CreditCard /></el-icon>
            立即购买
          </el-button>
          <el-button
            :type="isFavorited ? 'danger' : 'default'"
            size="large"
            @click="toggleFavorite"
          >
            <el-icon><Star /></el-icon>
            {{ isFavorited ? '已收藏' : '收藏' }}
          </el-button>
          <el-button
            type="info"
            size="large"
            @click="checkSecondHand"
          >
            <el-icon><Search /></el-icon>
            看看二手
          </el-button>
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
        <el-tab-pane label="用户评价" name="evaluations">
          <div class="evaluations-content">
            <div v-if="evaluations.length > 0">
              <div class="evaluation-summary">
                <div class="average-score">
                  <div class="score-number">{{ averageScore.toFixed(1) }}</div>
                  <div class="score-stars">
                    <RateComponent :value="averageScore" :readonly="true" />
                  </div>
                  <div class="score-count">{{ evaluations.length }}条评价</div>
                </div>
                <div class="score-distribution">
                  <div v-for="(count, star) in scoreDistribution" :key="star" class="score-item">
                    <span class="star-label">{{ star }}星</span>
                    <div class="score-bar">
                      <div class="score-fill" :style="{ width: (count / evaluations.length) * 100 + '%' }"></div>
                    </div>
                    <span class="score-count">{{ count }}</span>
                  </div>
                </div>
              </div>
              <div class="evaluation-list">
                <div v-for="evaluationItem in evaluations" :key="evaluationItem.evalId" class="evaluation-item">
                  <div class="evaluation-header">
                    <div class="user-info">
                      <span class="user-name">{{ evaluationItem.userName || '匿名用户' }}</span>
                      <RateComponent :value="evaluationItem.score" :readonly="true" />
                    </div>
                    <div class="evaluation-time">{{ formatDate(evaluationItem.createTime) }}</div>
                  </div>
                  <div class="evaluation-content">{{ evaluationItem.content }}</div>
                  <div class="evaluation-scores" v-if="evaluationItem.qualityScore || evaluationItem.serviceScore">
                    <span v-if="evaluationItem.qualityScore">质量：{{ evaluationItem.qualityScore }}星</span>
                    <span v-if="evaluationItem.serviceScore">服务：{{ evaluationItem.serviceScore }}星</span>
                    <span v-if="evaluationItem.logisticsScore">物流：{{ evaluationItem.logisticsScore }}星</span>
                  </div>
                  <div class="evaluation-reply" v-if="evaluationItem.replyContent">
                    <div class="reply-label">商家回复：</div>
                    <div class="reply-content">{{ evaluationItem.replyContent }}</div>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="no-evaluations">
              <el-empty description="暂无评价" />
            </div>
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
            @click="goToProductDetail(item.id || item.productId, item)"
          >
            <img :src="item.imageUrl" :alt="item.name" />
            <div class="related-info">
              <div class="related-name">{{ item.brandName }} {{ item.name }}</div>
              <div class="related-price">¥{{ item.price }}</div>
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
import { user } from '@/api';
import RateComponent from '@/components/RateComponent.vue';

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();

const product = ref({
  id: 0,
  name: '',
  brandName: '',
  price: 0,
  originalPrice: 0,
  imageUrl: '',
  description: '',
  specifications: {},
  categoryId: null,
  imageUrls: [],
  productType: 1
});



const loading = ref(true);
const activeTab = ref('detail');
const isFavorited = ref(false);
const relatedProducts = ref([]);

// 评价相关状态
const evaluations = ref([]);
const averageScore = ref(0);
const scoreDistribution = ref({
  5: 0,
  4: 0,
  3: 0,
  2: 0,
  1: 0
});

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

// 获取商品详情
const fetchProductDetail = async () => {
  try {
    loading.value = true;
    // 恢复登录状态，确保isLoggedIn正确
    userStore.checkLoginStatus();
    console.log('登录状态检查结果:', userStore.isLoggedIn);
    console.log('用户信息:', userStore.userInfo);

    // 使用响应式的route.params.id确保每次路由变化都能获取最新ID
    const productId = route.params.id;
    console.log('当前商品ID:', productId);

    // 初始化商品数据，确保页面不会空白
    product.value = {
      id: productId,
      name: '商品名称',
      brandName: '品牌',
      price: 0,
      originalPrice: 0,
      categoryId: null,
      imageUrl: '',
      description: '暂无商品描述',
      specifications: {},
      sellerName: '匿名',
      imageUrls: [],
      productType: 1
    };

    try {
      const productData = await user.product.getProductDetail(Number(productId));
      console.log('商品详情数据:', productData);

      // 处理后端返回的数据，处理null值
      if (productData) {
        product.value = {
          id: productData.id || productId, // 使用URL参数中的productId作为备用
          name: productData.name || '商品名称',
          brandName: productData.brandName || '品牌',
          price: productData.price || 0,
          originalPrice: productData.originalPrice || 0,
          categoryId: productData.categoryId || null,
          imageUrl: productData.imageUrl,
          description: productData.description || '暂无商品描述',
          specifications: productData.specifications || {},
          sellerName: productData.sellerName || '匿名',
          imageUrls: productData.imageUrls || [],
          productType: productData.productType || 1
        };
      }
    } catch (error) {
      console.error('获取商品详情失败:', error);
      // 保持默认商品数据，确保页面不会空白
    }

    // 检查是否已收藏
    console.log('开始检查收藏状态，登录状态:', userStore.isLoggedIn);
    if (userStore.isLoggedIn) {
      try {
        // 使用路由参数中的productId确保获取正确的收藏状态
        console.log('检查收藏状态，商品ID:', productId);

        // 直接使用axios调用API，与二手交易模块保持一致的处理方式
        const favoriteRes = await axios.get(`/favorites/check`, {
          params: { productId: Number(productId) }
        });

        console.log('收藏状态检查响应:', favoriteRes);
        console.log('favoriteRes.isFavorited:', favoriteRes.isFavorited);

        // 确保favoriteRes不是undefined，才访问favoriteRes.isFavorited
        isFavorited.value = (favoriteRes && favoriteRes.isFavorited) || false;
        console.log('设置收藏状态为:', isFavorited.value);

      } catch (error) {
        console.error('检查收藏状态失败:', error);
        // 检查收藏状态失败不影响页面正常显示，所以不需要弹出错误提示
        isFavorited.value = false;
      }
    } else {
      // 未登录时，收藏状态默认为false
      console.log('用户未登录，设置收藏状态为false');
      isFavorited.value = false;
    }
    console.log('最终收藏状态:', isFavorited.value);

    // 获取相关商品推荐，处理categoryId为null的情况
if (product.value.categoryId) {
  try {
    // 使用现有的通用相关商品推荐接口
    const relatedProductsData = await user.product.getRelatedProducts({
      categoryId: product.value.categoryId,
      limit: 4,
      productId: product.value.id
    });
    console.log('相关推荐完整响应:', relatedProductsData);
    // 确保relatedProductsData是数组
    if (Array.isArray(relatedProductsData)) {
      relatedProducts.value = relatedProductsData;
    } else if (relatedProductsData && relatedProductsData.list) {
      relatedProducts.value = relatedProductsData.list;
    } else {
      relatedProducts.value = [];
    }
    console.log('相关推荐数据:', relatedProducts.value);
    // 添加详细调试信息
    console.log('相关推荐数据长度:', relatedProducts.value.length);
    if (relatedProducts.value.length > 0) {
      console.log('第一个相关推荐商品的所有字段:', Object.keys(relatedProducts.value[0]));
      console.log('第一个相关推荐商品的详细信息:', relatedProducts.value[0]);
    }
  } catch (error) {
    console.error('获取相关商品失败:', error);
    // 获取相关商品失败不影响页面正常显示，所以不需要弹出错误提示
    relatedProducts.value = [];
  }
} else {
  relatedProducts.value = [];
}

    // 获取商品评价
    try {
      await fetchProductEvaluations(Number(productId));
    } catch (error) {
      console.error('获取商品评价失败:', error);
      // 获取评价失败不影响页面正常显示
    }
  } catch (error) {
    console.error('获取商品详情失败:', error);
    // 保持默认商品数据，确保页面不会空白
  } finally {
    loading.value = false;
  }
};

// 获取商品评价
const fetchProductEvaluations = async (productId) => {
  try {
    const evaluationsData = await user.evaluation.getProductEvaluations(productId);
    evaluations.value = evaluationsData || [];

    // 计算平均评分和评分分布
    if (evaluations.value.length > 0) {
      const totalScore = evaluations.value.reduce((sum, evalItem) => sum + evalItem.score, 0);
      averageScore.value = totalScore / evaluations.value.length;

      // 初始化评分分布
      scoreDistribution.value = {
        5: 0,
        4: 0,
        3: 0,
        2: 0,
        1: 0
      };

      // 统计各评分的数量
      evaluations.value.forEach(evalItem => {
        const score = Math.round(evalItem.score);
        if (scoreDistribution.value[score] !== undefined) {
          scoreDistribution.value[score]++;
        }
      });
    } else {
      averageScore.value = 0;
      scoreDistribution.value = {
        5: 0,
        4: 0,
        3: 0,
        2: 0,
        1: 0
      };
    }
  } catch (error) {
    console.error('获取商品评价失败:', error);
    console.error('错误详情:', error.message);
    console.error('错误响应:', error.response);
    evaluations.value = [];
    averageScore.value = 0;
    scoreDistribution.value = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0
    };
  }
};

// 格式化日期
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
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





// 加入购物车
const addToCart = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    await user.cart.addToCart({
      productId: product.value.id,
      quantity: 1,
      leaseTerm: product.value.productType === 3 ? 1 : 1
    });
    ElMessage.success('已加入购物车');
  } catch (error) {
    console.error('加入购物车失败:', error);
    ElMessage.error('加入购物车失败');
  }
};

// 立即购买
const buyNow = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    // 跳转到订单确认页，携带productIds参数，使用与购物车相同的订单创建流程
    router.push({
      path: '/order/confirm',
      query: {
        productIds: product.value.id
      }
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
      await user.favorite.removeFavorite(product.value.id);
      isFavorited.value = false;
      ElMessage.success('取消收藏成功');
    } else {
      // 添加收藏
      await user.favorite.addFavorite({ productId: product.value.id });
      isFavorited.value = true;
      ElMessage.success('收藏成功');
    }
  } catch (error) {
    console.error('操作失败:', error);
    ElMessage.error('操作失败');
  }
};

// 跳转到商品详情的方法
const goToProductDetail = (productId, item) => {
  console.log('跳转函数被调用了！');
  console.log('传递的productId:', productId);
  console.log('传递的item:', item);
  console.log('item的所有字段:', Object.keys(item || {}));

  // 从item中获取正确的商品ID
  const actualProductId = item.productId || item.id || productId;
  console.log('实际使用的商品ID:', actualProductId);

  // 根据商品类型判断跳转路径
  if (item && (item.productType === 3 || item.productType === 'rental' || item.deposit || item.minRentalDays)) {
    console.log('跳转到租赁商品详情页:', `/rental/detail/${actualProductId}`);
    router.push(`/rental/detail/${actualProductId}`);
  } else if (item && (item.condition !== undefined && item.condition !== null)) {
    console.log('跳转到二手商品详情页:', `/second-hand/detail/${actualProductId}`);
    router.push(`/second-hand/detail/${actualProductId}`);
  } else {
    console.log('跳转到普通商品详情页:', `/product/${actualProductId}`);
    router.push(`/product/${actualProductId}`); // 这里的 router 必须是上面初始化的实例
  }
};

// 跳转到二手市场并搜索当前商品
const checkSecondHand = () => {
  router.push({
    path: '/second-hand',
    query: {
      keyword: product.value.name
    }
  });
};

// 监听路由变化，重新获取商品详情
watch(() => route.params.id, () => {
  fetchProductDetail();
});

// 初始化数据
onMounted(() => {
  fetchProductDetail();
});
</script>

<style scoped>
.product-detail-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.breadcrumb {
  margin-bottom: 20px;
}

.product-main {
  display: flex;
  gap: 40px;
  margin-bottom: 40px;
}

.product-gallery {
  flex: 1;
}

.main-image {
  width: 100%;
  height: 400px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
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
}

.main-image :deep(.el-carousel__button) {
  background-color: rgba(0, 0, 0, 0.3);
}

.main-image :deep(.is-active .el-carousel__button) {
  background-color: #409eff;
}

.product-info {
  flex: 1;
}

.product-title {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 20px;
  color: #333;
}

.product-price-section {
  margin-bottom: 20px;
}

.current-price {
  font-size: 28px;
  color: #ff4d4f;
  font-weight: bold;
  margin-right: 10px;
}

.original-price {
  font-size: 16px;
  color: #999;
  text-decoration: line-through;
}

.product-specs {
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 4px;
}

.spec-item {
  margin-bottom: 8px;
  display: flex;
}

.spec-label {
  color: #666;
  min-width: 80px;
}

.spec-value {
  color: #333;
}



.action-buttons {
  display: flex;
  gap: 15px;
}

.action-buttons .el-button {
  flex: 1;
}

.product-description {
  margin-bottom: 40px;
}

.description-content {
  line-height: 1.6;
}

.related-products h3 {
  margin-bottom: 20px;
  font-size: 18px;
  color: #333;
}

.related-list {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.related-item {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 15px;
  cursor: pointer;
  transition: all 0.3s;
}

.related-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.related-item img {
  width: 100%;
  height: 120px;
  object-fit: contain;
  margin-bottom: 10px;
}

.related-name {
  font-size: 14px;
  margin-bottom: 5px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.related-price {
  font-size: 16px;
  color: #ff4d4f;
  font-weight: bold;
}

/* 评价相关样式 */
.evaluations-content {
  padding: 20px;
}

.evaluation-summary {
  display: flex;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e0e0e0;
}

.average-score {
  flex: 1;
  text-align: center;
}

.score-number {
  font-size: 36px;
  font-weight: bold;
  color: #ffc107;
  margin-bottom: 10px;
}

.score-stars {
  margin-bottom: 10px;
}

.score-count {
  color: #999;
  font-size: 14px;
}

.score-distribution {
  flex: 2;
  padding-left: 30px;
}

.score-item {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.star-label {
  width: 40px;
  font-size: 14px;
  color: #666;
}

.score-bar {
  flex: 1;
  height: 8px;
  background: #f0f0f0;
  border-radius: 4px;
  margin: 0 10px;
  overflow: hidden;
}

.score-fill {
  height: 100%;
  background: #ffc107;
  border-radius: 4px;
}

.evaluation-list {
  margin-top: 20px;
}

.evaluation-item {
  padding: 20px;
  border-bottom: 1px solid #f0f0f0;
  transition: all 0.3s ease;
  border-radius: 8px;
  margin-bottom: 15px;
  background: #fff;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.evaluation-item:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.evaluation-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.evaluation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.user-name {
  font-weight: 500;
  color: #333;
  font-size: 14px;
  background: #f5f7fa;
  padding: 4px 12px;
  border-radius: 12px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 120px;
}

.evaluation-time {
  color: #999;
  font-size: 14px;
}

.evaluation-content {
  margin-bottom: 10px;
  line-height: 1.6;
  color: #333;
  font-size: 14px;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 4px;
}

.evaluation-scores {
  margin-bottom: 10px;
  font-size: 14px;
  color: #666;
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.evaluation-scores span {
  padding: 2px 8px;
  background: #f0f0f0;
  border-radius: 10px;
  font-size: 12px;
}

.evaluation-reply {
  padding: 12px;
  background: #f0f9ff;
  border-radius: 4px;
  margin-top: 10px;
  border-left: 3px solid #409eff;
}

.reply-label {
  font-weight: 500;
  margin-bottom: 5px;
  color: #409eff;
  font-size: 14px;
}

.reply-content {
  color: #333;
  line-height: 1.4;
  font-size: 13px;
}

.no-evaluations {
  padding: 40px 0;
  text-align: center;
}

@media (max-width: 768px) {
  .product-main {
    flex-direction: column;
  }

  .related-list {
    grid-template-columns: repeat(2, 1fr);
  }

  .action-buttons {
    flex-direction: column;
  }

  .evaluation-summary {
    flex-direction: column;
  }

  .score-distribution {
    padding-left: 0;
    margin-top: 20px;
  }
}

</style>
