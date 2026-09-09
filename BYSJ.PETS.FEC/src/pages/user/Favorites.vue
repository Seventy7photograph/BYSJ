<template>
  <div class="favorites-page">
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <h1>我的收藏</h1>
      <div class="header-actions">
        <el-button
          type="danger"
          :disabled="selectedItems.length === 0"
          @click="batchRemove"
        >
          批量删除
        </el-button>
        <el-button
          type="primary"
          :disabled="selectedItems.length === 0"
          @click="batchAddToCart"
        >
          批量加入购物车
        </el-button>
      </div>
    </div>

    <!-- 收藏商品类型标签页 -->
    <div class="favorites-tabs">
      <el-tabs v-model="activeTab" size="large" @tab-change="handleTabChange">
        <el-tab-pane label="全部收藏" name="all" />
        <el-tab-pane label="全新商品" name="new" />
        <el-tab-pane label="二手商品" name="second_hand" />
        <el-tab-pane label="租赁商品" name="rental" />
      </el-tabs>
    </div>

    <div class="favorites-content">
      <!-- 骨架屏（加载中显示） -->
      <div v-if="loading" class="skeleton-container">
        <div class="skeleton-item" v-for="index in pageSize" :key="index">
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
      </div>

      <!-- 空状态 -->
      <div v-else-if="filteredFavorites.length === 0" class="empty-favorites">
        <el-empty description="暂无收藏商品" :image-size="200" />
        <el-button type="primary" @click="$router.push('/shop')">去逛逛</el-button>
      </div>

      <!-- 收藏商品列表 -->
      <div v-else class="favorites-list">
        <!-- 全选操作 -->
        <div class="list-actions">
          <el-checkbox v-model="selectAll" @change="handleSelectAll">
            全选
          </el-checkbox>
          <span class="selected-count">已选 {{ selectedItems.length }} 件商品</span>
        </div>

        <!-- 收藏商品列表 -->
        <div class="products-grid">
          <div
            v-for="item in filteredFavorites"
            :key="item.id"
            class="favorite-item"
            :class="{ selected: item.selected }"
          >
            <div class="item-checkbox">
              <el-checkbox v-model="item.selected" />
            </div>
            <div class="item-content" @click="goToProductDetail(item.productId)">
              <div class="item-image">
                <!-- 商品标签（二手商品显示成色） -->
                <el-tag
                  v-if="item.productType == 3 || item.product_type == 3"
                  type="success"
                  style="position: absolute; top: 10px; left: 10px; z-index: 1;"
                >
                  租赁
                </el-tag>
                <el-tag
                  v-else-if="item.productType == 2 || item.product_type == 2"
                  :type="item.quality === 'excellent' ? 'success' : item.quality === 'good' ? 'warning' : 'info'"
                  style="position: absolute; top: 10px; left: 10px; z-index: 1;"
                >
                  {{ qualityLabelMap[item.quality] || '二手' }}
                </el-tag>
                <el-tag
                  v-else
                  type="primary"
                  style="position: absolute; top: 10px; left: 10px; z-index: 1;"
                >
                  全新
                </el-tag>
                <img :src="item.productImage" :alt="item.productName" />
                <div class="item-actions">
                  <el-button
                    type="primary"
                    size="small"
                    @click.stop="addToCart(item)"
                  >
                    <el-icon><ShoppingCart /></el-icon>
                    加入购物车
                  </el-button>
                  <el-button
                    type="danger"
                    size="small"
                    @click.stop="removeFavorite(item.id)"
                  >
                    <el-icon><Delete /></el-icon>
                    取消收藏
                  </el-button>
                </div>
              </div>
              <div class="item-info">
                <div class="item-name-wrapper">
                <h3 class="item-name">{{ item.productName }}</h3>
                <el-tag v-if="item.productType == 3 || item.product_type == 3" type="success" size="small" class="rental-tag">
                  租赁
                </el-tag>
                <el-tag v-else-if="item.productType == 2 || item.product_type == 2" type="warning" size="small" class="second-hand-tag">
                  二手
                </el-tag>
                <el-tag v-else type="primary" size="small" class="new-tag">
                  全新
                </el-tag>
                </div>
                <div class="item-brand" v-if="item.brandName">品牌：{{ item.brandName }}</div>
                <!-- 租赁商品显示租金 -->
                <div v-if="item.productType == 3 || item.product_type == 3" class="item-price">租金：¥{{ item.price }}/天</div>
                <!-- 其他商品显示价格 -->
                <div v-else class="item-price">¥{{ item.price }}</div>
                <!-- 二手商品显示成色 -->
                <div class="item-quality" v-if="item.productType == 2 || item.product_type == 2">
                  成色：{{ qualityLabelMap[item.quality] || '二手' }}
                </div>
                <!-- 二手商品显示卖家 -->
                <div class="item-seller" v-if="(item.productType == 2 || item.product_type == 2) && item.sellerName">
                  卖家：{{ item.sellerName }}
                </div>
                <div class="item-time">收藏时间：{{ formatTime(item.createdAt) }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 分页 -->
        <div class="pagination" v-if="total > pageSize">
          <el-pagination
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[12, 24, 36, 48]"
            :total="total"
            layout="total, sizes, prev, pager, next, jumper"
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ShoppingCart, Delete, ArrowLeft } from '@element-plus/icons-vue'
import axios from '@/axios'
import { useUserStore } from '@/stores/user'
import { user } from '@/api'

const router = useRouter()
const userStore = useUserStore()

// 成色标签映射，直接使用condition值作为key
const qualityLabelMap = {
  '99': '99新',
  '95': '95新',
  '90': '90新',
  '80': '80新'
};

// 收藏数据
const favorites = ref([])
const loading = ref(true)
const selectAll = ref(false)
const currentPage = ref(1)
const pageSize = ref(12)
const total = ref(0)
const activeTab = ref('all') // 活动标签页

// 处理标签页切换
const handleTabChange = (tab) => {
  activeTab.value = tab
  // 重置分页
  currentPage.value = 1
}

// 计算属性
const selectedItems = computed(() => filteredFavorites.value.filter(item => item.selected))

// 根据标签页过滤收藏
const filteredFavorites = computed(() => {
  if (activeTab.value === 'all') {
    return favorites.value
  } else if (activeTab.value === 'new') {
    return favorites.value.filter(item => {
      const type = item.productType || item.product_type
      return Number(type) === 1
    })
  } else if (activeTab.value === 'second_hand') {
    return favorites.value.filter(item => {
      const type = item.productType || item.product_type
      return Number(type) === 2
    })
  } else if (activeTab.value === 'rental') {
    return favorites.value.filter(item => {
      const type = item.productType || item.product_type
      return Number(type) === 3
    })
  }
  return favorites.value
})

// 获取收藏列表
const fetchFavorites = async () => {
  try {
    loading.value = true
    console.log('开始获取收藏列表，当前标签:', activeTab.value)
    const res = await user.favorite.getFavoriteList({
      pageNum: currentPage.value,
      pageSize: pageSize.value
    })
    console.log('收藏列表数据:', res)
    // 处理后端返回的数据结构
    const data = res.data || res
    const list = data.list || []
    console.log('原始收藏列表:', list)
    // 为每个商品添加明确的类型标识
    favorites.value = list.map(item => {
      // 检查商品类型，根据不同字段确定类型
      let productType = item.productType || item.product_type
      // 如果没有明确的类型字段，根据其他字段推断
      if (!productType) {
        if (item.deposit || item.minRentalDays || item.priceUnit === 'day' || item.price.includes('/天')) {
          productType = 3 // 租赁商品
        } else if (item.condition) {
          productType = 2 // 二手商品
        } else {
          productType = 1 // 全新商品
        }
      }
      return {
        ...item,
        productType,
        selected: false
      }
    })
    // 打印处理后的数据，查看类型是否正确
    console.log('处理后的收藏列表数据:', favorites.value)
    total.value = data.total || 0
  } catch (error) {
    console.error('获取收藏列表失败:', error)
    ElMessage.error('获取收藏列表失败')
  } finally {
    loading.value = false
  }
}

// 全选/取消全选
const handleSelectAll = (checked) => {
  filteredFavorites.value.forEach(item => {
    item.selected = checked
  })
}

// 单个商品加入购物车
const addToCart = async (item) => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }

  try {
    await user.cart.addToCart({
      productId: item.productId,
      quantity: 1
    })
    ElMessage.success('已加入购物车')
  } catch (error) {
    console.error('加入购物车失败:', error)
    ElMessage.error('加入购物车失败')
  }
}

// 批量加入购物车
const batchAddToCart = async () => {
  try {
    const productIds = selectedItems.value.map(item => item.productId)

    await user.cart.batchAddToCart({
      productIds: productIds
    })

    ElMessage.success(`成功将 ${productIds.length} 件商品加入购物车`)

    // 清空选中状态
    favorites.value.forEach(item => {
      item.selected = false
    })
    selectAll.value = false
  } catch (error) {
    console.error('批量加入购物车失败:', error)
    ElMessage.error('批量加入购物车失败')
  }
}

// 取消收藏
const removeFavorite = async (favoriteId) => {
  try {
    await ElMessageBox.confirm('确定要取消收藏吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    await user.favorite.removeFavoriteById(favoriteId)
    ElMessage.success('取消收藏成功')
    fetchFavorites() // 重新加载列表
  } catch (error) {
    if (error !== 'cancel') {
      console.error('取消收藏失败:', error)
      ElMessage.error('取消收藏失败')
    }
  }
}

// 批量删除
const batchRemove = async () => {
  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${selectedItems.value.length} 件商品吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    const favoriteIds = selectedItems.value.map(item => item.id)
    await user.favorite.batchRemoveFavorites(favoriteIds)

    ElMessage.success(`成功删除 ${favoriteIds.length} 件商品`)
    fetchFavorites() // 重新加载列表
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量删除失败:', error)
      ElMessage.error('批量删除失败')
    }
  }
}

// 格式化规格参数
const formatSpecifications = (specs) => {
  return Object.entries(specs)
    .map(([key, value]) => `${key}: ${value}`)
    .join(' | ')
}

// 格式化时间
const formatTime = (timeStr) => {
  return new Date(timeStr).toLocaleDateString('zh-CN')
}

// 跳转到商品详情
const goToProductDetail = (productId) => {
  // 查找当前商品，确定商品类型
  const product = favorites.value.find(item => item.productId === productId);
  // 根据商品类型判断跳转路径
  if (product?.productType == 2 || product?.product_type == 2) {
    router.push(`/second-hand/detail/${productId}`);
  } else if (product?.productType == 3 || product?.product_type == 3) {
    router.push(`/rental/detail/${productId}`);
  } else {
    router.push(`/product/${productId}`);
  }
}

// 分页处理
const handleSizeChange = (size) => {
  pageSize.value = size
  currentPage.value = 1
  fetchFavorites()
}

const handleCurrentChange = (page) => {
  currentPage.value = page
  fetchFavorites()
}

// 返回上一页
const goBack = () => {
  router.back()
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  fetchFavorites()
})
</script>

<style scoped>
.favorites-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #e0e0e0;
}

.page-header h1 {
  margin: 0;
  color: #333;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.empty-favorites {
  text-align: center;
  padding: 100px 0;
}

.list-actions {
  display: flex;
  align-items: center;
  padding: 15px 20px;
  background: #f8f9fa;
  border-radius: 4px;
  margin-bottom: 20px;
}

.selected-count {
  margin-left: 20px;
  color: #666;
}

.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.favorite-item {
  position: relative;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s;
  background: white;
}

.favorite-item.selected {
  border-color: #409EFF;
  box-shadow: 0 2px 12px rgba(64, 158, 255, 0.1);
}

.favorite-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.item-checkbox {
      position: absolute;
      top: 10px;
      right: 10px;
      z-index: 2;
    }

.item-content {
  cursor: pointer;
}

.item-image {
  position: relative;
  width: 100%;
  height: 200px;
  overflow: hidden;
  background: #f8f9fa;
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  transition: transform 0.3s;
}

.item-image:hover img {
  transform: scale(1.05);
}

.item-actions {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0,0,0,0.7);
  padding: 10px;
  display: flex;
  gap: 5px;
  opacity: 0;
  transition: opacity 0.3s;
}

.item-image:hover .item-actions {
  opacity: 1;
}

.item-actions .el-button {
  flex: 1;
  padding: 5px 8px;
  font-size: 12px;
}

.item-info {
  padding: 15px;
}

.item-name-wrapper {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.item-name {
  margin: 0 8px 0 0;
  font-size: 16px;
  font-weight: 500;
  color: #333;
  line-height: 1.4;
  height: 44px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  flex: 1;
}

.second-hand-tag {
  margin-bottom: 4px;
}

.item-brand {
  font-size: 12px;
  color: #666;
  margin-bottom: 8px;
}

.item-price {
  font-size: 18px;
  color: #ff4d4f;
  font-weight: bold;
  margin-bottom: 8px;
}

.item-quality {
  font-size: 12px;
  color: #409eff;
  margin-bottom: 8px;
}

.item-seller {
  font-size: 12px;
  color: #666;
  margin-bottom: 8px;
}

.item-specs {
  font-size: 12px;
  color: #666;
  line-height: 1.4;
  margin-bottom: 8px;
  height: 34px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.item-stock {
  font-size: 12px;
  color: #666;
  margin-bottom: 5px;
}

.item-time {
  font-size: 12px;
  color: #999;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 30px;
}

/* 骨架屏样式 */
.skeleton-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.skeleton-item {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  background: white;
}

.skeleton-item-content {
  padding: 20px;
}

.skeleton-text {
  margin-top: 20px;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 15px;
    align-items: flex-start;
  }

  .header-actions {
    width: 100%;
    justify-content: flex-end;
  }

  .products-grid {
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 15px;
  }

  .item-actions {
    opacity: 1; /* 移动端始终显示操作按钮 */
    background: rgba(0,0,0,0.8);
  }
}

@media (max-width: 480px) {
  .products-grid {
    grid-template-columns: 1fr;
  }

  .header-actions {
    flex-direction: column;
  }

  .header-actions .el-button {
    width: 100%;
    margin-bottom: 10px;
  }
}
</style>
