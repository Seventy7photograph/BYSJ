<template>
  <div class="product-detail-page" :key="route.params.id">
    <!-- 面包屑导航 -->
    <div class="breadcrumb">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
        <el-breadcrumb-item :to="{ path: '/second-hand' }">二手交易</el-breadcrumb-item>
        <el-breadcrumb-item>{{ product.brandName }}</el-breadcrumb-item>
        <el-breadcrumb-item>{{ product.name }}</el-breadcrumb-item>
      </el-breadcrumb>
    </div>

    <!-- 商品详情主体 -->
    <div class="product-main" v-loading="loading">
      <!-- 商品图片 -->
      <div class="product-gallery">
        <div class="main-image">
          <el-carousel :interval="0" :autoplay="false" height="400px" :show-arrow="allImages.length > 1 ? 'hover' : false">
            <el-carousel-item v-for="(image, index) in allImages" :key="index">
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

        <!-- 二手商品特有信息 -->
        <div class="product-specs">
          <div class="spec-item">
            <span class="spec-label">成色：</span>
            <span class="spec-value">{{ getConditionLabel(product.condition) }}</span>
          </div>
          <div class="spec-item">
            <span class="spec-label">使用时长：</span>
            <span class="spec-value">{{ product.usedTime || '未填写' }}</span>
          </div>
          <div class="spec-item">
            <span class="spec-label">卖家类型：</span>
            <span class="spec-value">{{ product.sellerType === 1 ? '个人闲置' : '企业商家' }}</span>
          </div>
          <div class="spec-item">
            <span class="spec-label">卖家：</span>
            <span class="spec-value">{{ product.sellerName || '匿名' }}</span>
          </div>
          <div v-if="product.qualityReport" class="spec-item">
            <span class="spec-label">质检报告：</span>
            <a :href="product.qualityReport" target="_blank" class="spec-value" style="color: #409eff; cursor: pointer;">查看报告</a>
          </div>
          <div v-if="product.warrantyInfo" class="spec-item">
            <span class="spec-label">保修信息：</span>
            <span class="spec-value">{{ product.warrantyInfo }}</span>
          </div>
        </div>



        <!-- 瑕疵描述 -->
        <div v-if="product.defectDesc" class="defect-section">
          <h3 style="margin-bottom: 10px; font-size: 16px; color: #333;">瑕疵描述</h3>
          <div class="defect-desc">{{ product.defectDesc }}</div>
        </div>

        <!-- 瑕疵图片 -->
        <div v-if="product.defectImg && product.defectImg.length > 0" class="defect-images">
          <h3 style="margin-bottom: 10px; font-size: 16px; color: #333;">瑕疵图片</h3>
          <div class="defect-img-list">
            <img
              v-for="(img, index) in product.defectImg"
              :key="index"
              :src="img"
              :alt="`瑕疵图片${index + 1}`"
              class="defect-img-item"
            >
          </div>
        </div>

        <!-- 议价功能 -->
        <div class="negotiate-section">
          <h3 style="margin-bottom: 10px; font-size: 16px; color: #333;">议价</h3>
          <div v-if="isNegotiable" class="negotiate-form">
            <el-input-number
              v-model="negotiatePrice"
              :min="1"
              :max="product.price > 0 ? product.price : 10000"
              :step="100"
              style="width: 200px; margin-right: 10px;"
              placeholder="输入议价金额"
              :disabled="product.price <= 0"
            />
            <el-button type="primary" @click="submitNegotiate" :disabled="product.price <= 0">提交议价</el-button>
          </div>
          <div v-else class="negotiate-status">
            <el-tag :type="getNegotiateStatusType(product.negotiateStatus)">
              {{ getNegotiateStatusText(product.negotiateStatus) }}
            </el-tag>
            <span v-if="product.finalPrice && product.finalPrice < product.price" class="final-price">
              议价达成价格：¥{{ product.finalPrice }}
            </span>
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
            @click="checkNewProduct"
          >
            <el-icon><Search /></el-icon>
            看看全新
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
            <!-- 专业参数 -->
            <el-descriptions :column="2" border style="margin-bottom: 20px;">
              <el-descriptions-item
                v-for="(value, key) in product.parameters"
                :key="key"
                :label="key"
              >
                {{ value }}
              </el-descriptions-item>
            </el-descriptions>

            <!-- 规格参数 -->
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
        <el-tab-pane label="商品实拍图" name="images">
          <div class="product-images">
            <!-- 所有图片集合：主图 + 实拍图 -->
            <div v-if="allImages && allImages.length > 0" class="all-images-section">
              <div class="image-grid">
                <div
                  class="image-item"
                  v-for="(img, index) in allImages"
                  :key="index"
                >
                  <img :src="img" :alt="`商品实拍图${index + 1}`" class="gallery-image" />
                </div>
              </div>
            </div>

            <!-- 瑕疵图片 -->
            <div class="defect-images-section" v-if="product.defectImg && product.defectImg.length > 0">
              <h3 style="margin: 20px 0 15px 0; font-size: 16px; color: #333;">瑕疵图片</h3>
              <div class="image-grid">
                <div
                  class="image-item"
                  v-for="(img, index) in product.defectImg"
                  :key="index"
                >
                  <img :src="img" :alt="`瑕疵图片${index + 1}`" class="gallery-image" />
                </div>
              </div>
            </div>

            <!-- 空状态提示：当没有主图、没有实拍图、没有瑕疵图片时才显示 -->
            <div v-if="!product.imageUrl && (!product.img_url || product.img_url.length === 0) && (!product.defectImg || product.defectImg.length === 0)" class="empty-images">
              <el-empty description="暂无商品实拍图" />
            </div>
          </div>
        </el-tab-pane>
        <el-tab-pane label="质检报告" name="quality-report">
          <div class="quality-report-section">
            <!-- 质检报告图片 -->
            <div v-if="product.qualityReport" class="quality-report-content">
              <div class="image-grid">
                <div class="image-item">
                  <img :src="product.qualityReport" :alt="'质检报告'" class="gallery-image" />
                </div>
              </div>
            </div>
            <!-- 空状态提示 -->
            <div v-else class="empty-images">
              <el-empty description="未有相关报告" />
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

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();

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
  // 二手商品特有字段
  qualityReport: '',
  usedTime: '',
  defectDesc: '',
  defectImg: [],
  sellerType: 1,
  negotiateStatus: 0,
  finalPrice: 0,
  // 新增字段
  parameters: {}, // 专业参数
  warrantyInfo: '', // 保修信息
  img_url: [] // 商品实拍图（后端返回字段名）
});

const loading = ref(true);
const activeTab = ref('detail');
const isFavorited = ref(false);
const relatedProducts = ref([]);

// 议价相关状态
const negotiatePrice = ref(1);

// 计算属性：是否可以议价
const isNegotiable = computed(() => {
  return product.value.negotiateStatus === null || product.value.negotiateStatus === 0;
});

// 计算属性：所有图片集合（主图 + 实拍图）
const allImages = computed(() => {
  const images = new Set();

  // 添加主图
  if (product.value.imageUrl) {
    images.add(product.value.imageUrl);
  }

  // 添加实拍图
  if (product.value.img_url && Array.isArray(product.value.img_url)) {
    product.value.img_url.forEach(img => {
      if (img) {
        images.add(img);
      }
    });
  }

  return Array.from(images);
});

// 获取议价状态文本
const getNegotiateStatusText = (status) => {
  const statusMap = {
    0: '未议价',
    1: '议价中',
    2: '议价达成',
    3: '议价失败'
  };
  return statusMap[status] || '未议价';
};

// 获取议价状态类型
const getNegotiateStatusType = (status) => {
  const typeMap = {
    0: 'info',
    1: 'warning',
    2: 'success',
    3: 'danger'
  };
  return typeMap[status] || 'info';
};

// 提交议价
const submitNegotiate = async () => {
  if (!negotiatePrice.value || negotiatePrice.value <= 0 || negotiatePrice.value >= product.value.price) {
    ElMessage.warning('请输入有效的议价金额');
    return;
  }

  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    await axios.post('/second-hand/negotiate', {
      productId: product.value.id,
      negotiatePrice: negotiatePrice.value
    });
    ElMessage.success('议价请求已提交');
    // 更新议价状态
    product.value.negotiateStatus = 1;
    negotiatePrice.value = 0;
  } catch (error) {
    console.error('提交议价失败:', error);
    ElMessage.error('提交议价失败');
  }
};

// 获取成色标签的函数
const getConditionLabel = (condition) => {
  // 确保condition是字符串或数字类型
  const conditionKey = String(condition);

  // 成色映射表
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

  return conditionMap[conditionKey] || '未知';
};

// 获取商品详情
const fetchProductDetail = async () => {
  try {
    loading.value = true;
    // 使用响应式的route.params.id确保每次路由变化都能获取最新ID
    const productId = route.params.id;
    console.log('当前二手商品ID:', productId);
    // 使用现有的通用商品详情接口
    const res = await axios.get(`/shop/products/${productId}`);
    console.log('商品详情数据:', res);

    // 处理后端返回的数据，处理null值
    // API返回的数据结构是{msg: "获取商品详情成功", data: {...}}
    // 确保res不是undefined，才访问res.data
    const productData = (res && res.data) || {};
    console.log('productData:', productData);
    console.log('API返回的所有字段:', Object.keys(productData));

    // 调试secondHandImgUrls字段
    console.log('secondHandImgUrls:', productData.secondHandImgUrls);
    console.log('img_urls:', productData.img_urls);
    console.log('img_url:', productData.img_url);

    // 处理商品实拍图
    let imgUrls = [];
    // 首先尝试从secondHandImgUrls获取
    if (productData.secondHandImgUrls) {
      if (Array.isArray(productData.secondHandImgUrls)) {
        imgUrls = productData.secondHandImgUrls;
      } else {
        // 如果是字符串，尝试解析为JSON数组
        try {
          imgUrls = JSON.parse(productData.secondHandImgUrls);
          if (!Array.isArray(imgUrls)) {
            imgUrls = [];
          }
        } catch (e) {
          console.error('解析secondHandImgUrls失败:', e);
          imgUrls = [];
        }
      }
    }
    // 然后尝试从img_urls获取
    else if (productData.img_urls) {
      if (Array.isArray(productData.img_urls)) {
        imgUrls = productData.img_urls;
      } else {
        // 如果是字符串，尝试解析为JSON数组
        try {
          imgUrls = JSON.parse(productData.img_urls);
          if (!Array.isArray(imgUrls)) {
            imgUrls = [];
          }
        } catch (e) {
          console.error('解析img_urls失败:', e);
          imgUrls = [];
        }
      }
    }
    // 最后尝试从img_url获取
    else if (productData.img_url) {
      if (Array.isArray(productData.img_url)) {
        imgUrls = productData.img_url;
      } else {
        // 如果是字符串，尝试解析为JSON数组
        try {
          imgUrls = JSON.parse(productData.img_url);
          if (!Array.isArray(imgUrls)) {
            imgUrls = [];
          }
        } catch (e) {
          console.error('解析img_url失败:', e);
          imgUrls = [];
        }
      }
    }

    console.log('处理后的imgUrls:', imgUrls);

    product.value = {
      id: productData.id || productId, // 使用URL参数中的productId作为备用
      name: productData.name || '商品名称',
      brandName: productData.brandName || '品牌',
      price: productData.price || 0,
      originalPrice: productData.originalPrice || 0,
      stock: productData.stock || 0,
      categoryId: productData.categoryId || null,
      imageUrl: productData.imageUrl,
      description: productData.secondHandDescription || productData.description || productData.second_hand_description || '暂无商品描述',
      specifications: productData.specifications || {},
      condition: productData.condition || 0,
      sellerId: productData.sellerId || 0,
      sellerName: productData.sellerName || '匿名',
      // 二手商品特有字段
      qualityReport: productData.qualityReport || '',
      usedTime: productData.usedTime || '',
      defectDesc: productData.defectDesc || '',
      defectImg: productData.defectImg || [],
      sellerType: productData.sellerType || 1,
      negotiateStatus: productData.negotiateStatus || 0,
      finalPrice: productData.finalPrice || 0,
      // 新增字段
      parameters: productData.parameters || {},
      warrantyInfo: productData.warrantyInfo || '',
      img_url: imgUrls // 商品实拍图
    };

    console.log('处理后的商品数据:', product.value);
    console.log('处理后的img_url:', product.value.img_url);

    // 检查是否已收藏
    if (userStore.isLoggedIn) {
      try {
        const favoriteRes = await axios.get(`/favorites/check?productId=${productId}`);
        // 确保favoriteRes不是undefined，才访问favoriteRes.isFavorited
        isFavorited.value = (favoriteRes && favoriteRes.isFavorited) || false;
      } catch (error) {
        console.error('检查收藏状态失败:', error);
        // 检查收藏状态失败不影响页面正常显示，所以不需要弹出错误提示
      }
    }

    // 获取相关商品推荐，处理categoryId为null的情况
    if (product.value.categoryId) {
      try {
        // 使用现有的通用相关商品推荐接口
        const relatedRes = await axios.get(`/shop/related`, {
          params: {
            categoryId: product.value.categoryId,
            limit: 4,
            productId: product.value.id
          }
        });
        console.log('相关推荐完整响应:', relatedRes);
        // 确保relatedRes不是undefined，才访问relatedRes.data
        relatedProducts.value = (relatedRes && relatedRes.data) || [];
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
  } catch (error) {
    console.error('获取商品详情失败:', error);
    ElMessage.error('获取商品详情失败');
  } finally {
    loading.value = false;
  }
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

// 监听路由变化，重新获取商品详情
watch(() => route.params.id, () => {
  fetchProductDetail();
});

// 收藏/取消收藏
const toggleFavorite = async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录');
    router.push('/login');
    return;
  }

  try {
    if (isFavorited.value) {
      // 当点击取消收藏时，重新调用API检查收藏状态，获取favoriteId
      const favoriteRes = await axios.get(`/favorites/check?productId=${product.value.id}`);
      if (favoriteRes.isFavorited) {
        // 这里假设API支持通过productId取消收藏
        await axios.delete(`/favorites`, {
          params: { productId: product.value.id }
        });
        isFavorited.value = false;
        ElMessage.success('取消收藏成功');
      }
    } else {
      await axios.post('/favorites', { productId: product.value.id });
      isFavorited.value = true;
      ElMessage.success('收藏成功');
    }
  } catch (error) {
    console.error('操作失败:', error);
    ElMessage.error('操作失败');
  }
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
      quantity: 1
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
      query: { productIds: product.value.id }
    });
  } catch (error) {
    console.error('创建订单失败:', error);
    ElMessage.error('创建订单失败');
  }
};

// 跳转到商品详情的方法
const goToProductDetail = (productId, item) => {
  console.log('二手详情页跳转函数被调用！');
  console.log('传递的productId:', productId);
  console.log('传递的item:', item);
  console.log('item的所有字段:', Object.keys(item || {}));

  // 详细日志，记录condition字段的值和类型
  if (item) {
    console.log('item.condition值:', item.condition);
    console.log('item.condition类型:', typeof item.condition);
    console.log('item.condition !== undefined:', item.condition !== undefined);
    console.log('item.condition !== null:', item.condition !== null);
    console.log('item.productType:', item.productType);
    console.log('item.deposit:', item.deposit);
    console.log('item.minRentalDays:', item.minRentalDays);
  }

  // 从item中获取正确的商品ID
  const actualProductId = item.productId || item.id || productId;
  console.log('实际使用的商品ID:', actualProductId);

  // 从当前页面判断是否为二手商品详情页
  const isFromSecondHandDetail = route.path.startsWith('/second-hand/detail');
  console.log('是否从二手商品详情页跳转:', isFromSecondHandDetail);

  // 根据商品类型判断跳转路径
  if (item) {
    // 1. 先判断是否为租赁商品
    if (item.productType === 3 || item.productType === 'rental' || item.deposit || item.minRentalDays) {
      console.log('跳转到租赁商品详情页:', `/rental/detail/${actualProductId}`);
      router.push(`/rental/detail/${actualProductId}`);
    }
    // 2. 如果当前在二手商品详情页，相关推荐也应该是二手商品
    else if (isFromSecondHandDetail) {
      console.log('从二手详情页跳转，相关推荐为二手商品:', `/second-hand/detail/${actualProductId}`);
      router.push(`/second-hand/detail/${actualProductId}`);
    }
    // 3. 再判断是否为二手商品
    else if (item.condition !== undefined && item.condition !== null) {
      console.log('跳转到二手商品详情页:', `/second-hand/detail/${actualProductId}`);
      router.push(`/second-hand/detail/${actualProductId}`);
    }
    // 4. 最后判断是否为普通商品
    else {
      console.log('跳转到普通商品详情页:', `/product/${actualProductId}`);
      router.push(`/product/${actualProductId}`);
    }
  } else {
    // 如果没有item信息，从当前页面判断是普通商品还是二手商品
    if (isFromSecondHandDetail) {
      console.log('无item信息，从二手详情页跳转，默认跳转到二手商品详情页:', `/second-hand/detail/${actualProductId}`);
      router.push(`/second-hand/detail/${actualProductId}`);
    } else {
      console.log('跳转到普通商品详情页:', `/product/${actualProductId}`);
      router.push(`/product/${actualProductId}`);
    }
  }
};

// 跳转到器材商城并搜索当前商品
const checkNewProduct = () => {
  router.push({
    path: '/shop',
    query: {
      keyword: product.value.name
    }
  });
};

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

.stock-info {
  margin-bottom: 30px;
  color: #666;
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

/* 瑕疵描述 */
.defect-section {
  margin: 20px 0;
  padding: 15px;
  background: #fff3f0;
  border-radius: 8px;
  border: 1px solid #ffccc7;
}

/* 瑕疵图片 */
.defect-images {
  margin: 20px 0;
}

.defect-img-list {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.defect-img-item {
  width: 100px;
  height: 100px;
  object-fit: cover;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  cursor: pointer;
  transition: transform 0.2s;
}

.defect-img-item:hover {
  transform: scale(1.1);
}

/* 议价功能 */
.negotiate-section {
  margin: 20px 0;
  padding: 15px;
  background: #f0f9ff;
  border-radius: 8px;
  border: 1px solid #91d5ff;
}

.negotiate-form {
  display: flex;
  align-items: center;
}

.negotiate-status {
  display: flex;
  align-items: center;
  gap: 10px;
}

.final-price {
  color: #ff4d4f;
  font-weight: bold;
}

/* 商品实拍图样式 */
.product-images {
  padding: 10px 0;
}

.main-image-section {
  margin-bottom: 20px;
}

.main-image-large {
  width: 100%;
  max-height: 500px;
  object-fit: contain;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 10px;
  background-color: #fafafa;
}

.image-gallery,
.defect-images-section {
  margin-bottom: 30px;
}

.image-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
}

.image-item {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  cursor: pointer;
}

.image-item:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.gallery-image {
  width: 100%;
  height: 200px;
  object-fit: cover;
}

.empty-images {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 300px;
  background-color: #fafafa;
  border-radius: 8px;
  margin: 20px 0;
}

/* 质检报告样式 */
.quality-report-section {
  padding: 10px 0;
}

.quality-report-content {
  margin-bottom: 30px;
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

  .negotiate-form {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .negotiate-status {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .image-grid {
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 10px;
  }

  .gallery-image {
    height: 150px;
  }
}
</style>
