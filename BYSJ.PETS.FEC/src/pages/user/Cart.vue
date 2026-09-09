<template>
  <div class="cart-page">
    <div class="cart-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <h1>购物车</h1>
      <div class="header-actions">
        <el-button type="text" @click="clearCart" :disabled="selectedItems.length === 0">
          清空购物车
        </el-button>
      </div>
    </div>

    <!-- 购物车商品类型标签页 -->
    <div class="cart-tabs">
      <el-tabs v-model="activeTab" size="large" @tab-change="handleTabChange">
        <el-tab-pane label="全部商品" name="all" />
        <el-tab-pane label="全新商品" name="new" />
        <el-tab-pane label="二手商品" name="second_hand" />
        <el-tab-pane label="租赁商品" name="rental" />
      </el-tabs>
    </div>

    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="5" animated />
    </div>

    <div v-else-if="cartItems.length === 0" class="empty-cart">
      <el-empty description="购物车为空" :image-size="200" />
      <el-button type="primary" @click="$router.push('/shop')">去购物</el-button>
    </div>

    <div v-else class="cart-content">
      <!-- 全选操作 -->
      <div class="cart-actions">
        <el-checkbox v-model="selectAll" @change="handleSelectAll"> 全选 </el-checkbox>
        <span class="selected-count">已选 {{ selectedItems.length }} 件商品</span>
      </div>

      <!-- 购物车商品列表 -->
      <div class="cart-items">
        <div v-for="item in filteredCartItems" :key="item.id" class="cart-item">
          <div class="item-checkbox">
            <el-checkbox v-model="item.selected" @change="updateSelectedItems" />
          </div>
          <div class="item-info" @click="goToProductDetail(item)">
            <div class="item-image-wrapper">
              <!-- 二手商品显示成色标签 -->
              <el-tag
                v-if="item.productType === 'second-hand' || item.product_type === 2"
                :type="item.quality === 'excellent' ? 'success' : item.quality === 'good' ? 'warning' : 'info'"
                class="item-quality-tag"
              >
                {{ qualityLabelMap[item.quality as keyof typeof qualityLabelMap] || '二手' }}
              </el-tag>
              <img :src="item.productImage" :alt="item.productName" class="item-image" />
            </div>
            <div class="item-details">
              <div class="item-name-wrapper">
                <h3 class="item-name">{{ item.productName }}</h3>
                <el-tag v-if="item.productType === 'rental' || item.product_type === 3" type="success" size="small" class="rental-tag">
                  租赁
                </el-tag>
                <el-tag v-else-if="item.productType === 'second-hand' || item.product_type === 2" type="warning" size="small" class="second-hand-tag">
                  二手
                </el-tag>
              </div>
              <div class="item-brand" v-if="item.brandName">品牌：{{ item.brandName }}</div>
              <!-- 二手商品显示成色和卖家 -->
              <div class="item-quality" v-if="item.productType === 'second-hand' || item.product_type === 2">
                成色：{{ qualityLabelMap[item.quality as keyof typeof qualityLabelMap] || '二手' }}
              </div>
              <div class="item-seller" v-if="(item.productType === 'second-hand' || item.product_type === 2) && item.sellerName">
                卖家：{{ item.sellerName }}
              </div>
            </div>
          </div>
          <div class="item-price">¥{{ item.price }}</div>
          <div class="item-quantity">
            <el-button
              size="small"
              :disabled="item.quantity <= 1"
              @click="updateQuantity(item.id, item.quantity - 1)"
            >
              -
            </el-button>
            <span class="quantity-number">{{ item.quantity }}</span>
            <el-button
              size="small"
              :disabled="item.quantity >= item.stock"
              @click="updateQuantity(item.id, item.quantity + 1)"
            >
              +
            </el-button>
          </div>
          <div class="item-total">¥{{ (item.price * item.quantity).toFixed(2) }}</div>
          <div class="item-actions">
            <el-button type="danger" size="small" @click="removeItem(item.id)">
              <el-icon><Delete /></el-icon>
              删除
            </el-button>
          </div>
        </div>
      </div>

      <!-- 购物车底部结算 -->
      <div class="cart-footer">
        <div class="footer-left">
          <span>共 {{ selectedItems.length }} 件商品</span>
        </div>
        <div class="footer-right">
          <div class="total-section">
            <span class="total-label">合计：</span>
            <span class="total-price">¥{{ totalPrice.toFixed(2) }}</span>
          </div>
          <el-button
            type="primary"
            size="large"
            :disabled="selectedItems.length === 0"
            @click="checkout"
          >
            去结算 ({{ selectedItems.length }})
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, ArrowLeft } from '@element-plus/icons-vue'
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

interface CartItem {
  id: number
  productId: number
  productName: string
  productImage: string
  price: number
  quantity: number
  stock: number
  selected: boolean
  brandName?: string
  specifications?: Record<string, any>
  // 新增商品类型字段
  productType?: 'new' | 'second-hand' | 'second_hand' | 'rental'
  product_type?: number
  condition?: number | string
  quality?: 'excellent' | 'good' | 'fair' | 'poor'
  sellerName?: string
}

const cartItems = ref<CartItem[]>([])
const activeTab = ref('all') // 活动标签页

// 处理标签页切换
const handleTabChange = (tab: string) => {
  activeTab.value = tab
  // 可以在这里添加根据标签页过滤商品的逻辑
}
const loading = ref(true)
const selectAll = ref(false)

// 计算属性
const selectedItems = computed(() => filteredCartItems.value.filter((item) => item.selected))
const totalPrice = computed(() => {
  return selectedItems.value.reduce((total, item) => total + item.price * item.quantity, 0)
})

// 根据标签页过滤商品
const filteredCartItems = computed(() => {
  if (activeTab.value === 'all') {
    return cartItems.value
  } else if (activeTab.value === 'new') {
    return cartItems.value.filter(item => item.productType !== 'second-hand' && item.product_type !== 2 && item.productType !== 'rental' && item.product_type !== 3)
  } else if (activeTab.value === 'second_hand') {
    return cartItems.value.filter(item => item.productType === 'second-hand' || item.product_type === 2)
  } else if (activeTab.value === 'rental') {
    return cartItems.value.filter(item => item.productType === 'rental' || item.product_type === 3)
  }
  return cartItems.value
})

// 获取购物车数据
const fetchCartItems = async () => {
  try {
    loading.value = true
    const cartData = await user.cart.getCartList()
    console.log('购物车数据:', cartData)
      cartItems.value = cartData.map((item: any) => ({
        ...item,
        selected: false, // 默认不选中
      }))
  } catch (error) {
    console.error('获取购物车失败:', error)
    ElMessage.error('获取购物车失败')
  } finally {
    loading.value = false
  }
}

// 更新商品数量
const updateQuantity = async (cartItemId: number, newQuantity: number) => {
  if (newQuantity < 1) return

  try {
    await user.cart.updateCartItem(cartItemId, {
      quantity: newQuantity,
    })

    const item = cartItems.value.find((item) => item.id === cartItemId)
    if (item) {
      item.quantity = newQuantity
    }
  } catch (error) {
    console.error('更新数量失败:', error)
    ElMessage.error('更新数量失败')
  }
}

// 删除商品
const removeItem = async (cartItemId: number) => {
  try {
    await ElMessageBox.confirm('确定要删除该商品吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })

    await user.cart.deleteCartItem(cartItemId)
    cartItems.value = cartItems.value.filter((item) => item.id !== cartItemId)
    ElMessage.success('删除成功')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 清空购物车
const clearCart = async () => {
  try {
    await ElMessageBox.confirm('确定要清空购物车吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })

    await user.cart.clearCart()
    cartItems.value = []
    ElMessage.success('清空成功')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('清空失败:', error)
      ElMessage.error('清空失败')
    }
  }
}

// 全选/取消全选
const handleSelectAll = (checked: boolean) => {
  filteredCartItems.value.forEach((item) => {
    item.selected = checked
  })
}

// 更新选中状态
const updateSelectedItems = () => {
  selectAll.value = filteredCartItems.value.length > 0 && filteredCartItems.value.every((item) => item.selected)
}

// 格式化规格参数
const formatSpecifications = (specs: Record<string, any>) => {
  return Object.entries(specs)
    .map(([key, value]) => `${key}: ${value}`)
    .join(' | ')
}

// 跳转到商品详情
const goToProductDetail = (item: CartItem) => {
  // 根据商品类型判断跳转路径
  if (item.productType === 'second-hand' || item.product_type === 2) {
    router.push(`/second-hand/detail/${item.productId}`);
  } else if (item.productType === 'rental' || item.product_type === 3) {
    router.push(`/rental/detail/${item.productId}`);
  } else {
    router.push(`/product/${item.productId}`);
  }
}

// 结算
const checkout = () => {
  const selectedProductIds = selectedItems.value.map((item) => item.productId)

  if (selectedProductIds.length === 0) {
    ElMessage.warning('请选择要结算的商品')
    return
  }

  // 跳转到订单确认页，携带选中的商品ID，不提前创建订单
  router.push({
    path: '/order/confirm',
    query: { productIds: selectedProductIds.join(',') }
  })
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
  fetchCartItems()
})
</script>

<style scoped>
.cart-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.cart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #e0e0e0;
  position: relative;
}

.header-left {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
}

.back-button {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 16px;
  color: #666;
}

.cart-header h1 {
  margin: 0;
  color: #333;
  margin: 0 auto;
}

.loading-container {
  padding: 40px 0;
}

.empty-cart {
  text-align: center;
  padding: 100px 0;
}

.cart-actions {
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

.cart-items {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
}

.cart-item {
  display: flex;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #e0e0e0;
  background: white;
}

.cart-item:last-child {
  border-bottom: none;
}

.item-checkbox {
  margin-right: 15px;
}

.item-info {
  display: flex;
  align-items: center;
  flex: 1;
  cursor: pointer;
  margin-right: 20px;
}

.item-image-wrapper {
  position: relative;
  margin-right: 20px;
}

.item-image {
  width: 80px;
  height: 80px;
  object-fit: contain;
  border: 1px solid #f0f0f0;
  border-radius: 4px;
}

.item-quality-tag {
  position: absolute;
  top: -5px;
  left: -5px;
  z-index: 1;
  font-size: 12px;
  padding: 2px 6px;
}

.item-details {
  flex: 1;
}

.item-quality {
  margin: 0 0 8px 0;
  font-size: 12px;
  color: #409eff;
}

.item-seller {
  margin: 0 0 8px 0;
  font-size: 12px;
  color: #666;
}

.item-name-wrapper {
    display: flex;
    align-items: center;
    margin: 0 0 8px 0;
  }

  .item-name {
    margin: 0 8px 0 0;
    font-size: 16px;
    color: #333;
    font-weight: 500;
  }

  .second-hand-tag {
    margin-left: 8px;
  }

  .item-brand {
    margin: 0 0 8px 0;
    font-size: 12px;
    color: #666;
  }

  .item-specs {
  margin: 0;
  font-size: 12px;
  color: #666;
  line-height: 1.4;
}

.item-price {
  width: 100px;
  text-align: center;
  font-size: 16px;
  color: #ff4d4f;
  font-weight: bold;
}

.item-quantity {
  display: flex;
  align-items: center;
  width: 120px;
  justify-content: center;
}

.quantity-number {
  margin: 0 15px;
  font-size: 16px;
  min-width: 30px;
  text-align: center;
}

.item-total {
  width: 100px;
  text-align: center;
  font-size: 16px;
  color: #ff4d4f;
  font-weight: bold;
}

.item-actions {
  width: 80px;
  text-align: center;
}

.cart-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  margin-top: 20px;
}

.footer-left {
  color: #666;
}

.total-section {
  display: flex;
  align-items: center;
  margin-right: 20px;
}

.total-label {
  font-size: 16px;
  color: #333;
}

.total-price {
  font-size: 24px;
  color: #ff4d4f;
  font-weight: bold;
  margin-left: 10px;
}

.footer-right {
  display: flex;
  align-items: center;
}

@media (max-width: 768px) {
  .cart-item {
    flex-wrap: wrap;
    padding: 15px;
  }

  .item-info {
    order: 2;
    width: 100%;
    margin-top: 10px;
    margin-right: 0;
  }

  .item-price,
  .item-quantity,
  .item-total {
    order: 1;
    width: auto;
    margin: 0 10px;
  }

  .item-actions {
    order: 3;
    width: 100%;
    margin-top: 10px;
    text-align: right;
  }

  .cart-footer {
    flex-direction: column;
    gap: 15px;
  }

  .footer-right {
    width: 100%;
    justify-content: space-between;
  }
}
</style>
