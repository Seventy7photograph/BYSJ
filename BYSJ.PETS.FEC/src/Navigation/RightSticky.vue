<template>
  <div class="right-sticky">
    <!-- 功能按钮列表 -->
    <div class="sticky-item" @click="handleCart" title="购物车">
      <el-icon><ShoppingCart /></el-icon>
      <span class="sticky-text">购物车</span>
    </div>

    <div class="sticky-item" @click="handleOrder" title="我的订单">
      <el-icon><Document /></el-icon>
      <span class="sticky-text">订单</span>
    </div>

    <div class="sticky-item" @click="handleFavorites" title="我的收藏">
      <el-icon><Star /></el-icon>
      <span class="sticky-text">收藏</span>
    </div>

    <div class="sticky-item" @click="handleMessage" title="消息中心">
      <el-icon><Message /></el-icon>
      <span class="sticky-text">消息</span>
      <!-- 未读消息红点提示 -->
      <div class="unread-badge" v-if="unreadCount > 0">
        <span class="unread-dot"></span>
      </div>
    </div>

    <div class="sticky-item" @click="handleService" title="在线客服">
      <el-icon><Headset /></el-icon>
      <span class="sticky-text">客服</span>
    </div>

    <div class="sticky-item" @click="handleTop" title="回到顶部">
      <el-icon><Top /></el-icon>
      <span class="sticky-text">顶部</span>
    </div>
  </div>

  <!-- 消息抽屉组件，只有当drawerVisible为true时才渲染 -->
  <MessageDrawer
    v-if="drawerVisible"
    v-model:visible="drawerVisible"
    @update:unread-count="handleUnreadCountUpdate"
  />
</template>

<script lang="ts" setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ShoppingCart,
  Star,
  Message,
  Headset,
  Top,
  Document
} from '@element-plus/icons-vue'
import MessageDrawer from '../components/MessageDrawer.vue'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

// 抽屉相关状态
const drawerVisible = ref(false)

// 未读消息数量（使用ref而不是computed）
const unreadCount = ref(0)

// 处理未读消息数量更新
const handleUnreadCountUpdate = (count: number) => {
  unreadCount.value = count
}

// 购物车功能
const handleCart = () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  router.push('/cart')
}

// 我的订单
const handleOrder = () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  router.push('/orders')
}

// 我的收藏
const handleFavorites = () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  router.push('/favorites')
}

// 消息中心
const handleMessage = () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  // 显示消息抽屉
  drawerVisible.value = true
}

// 在线客服
const handleService = () => {
  ElMessage.info('在线客服功能开发中...')
}

// 回到顶部
const handleTop = () => {
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  })
}
</script>

<style scoped>
.right-sticky {
  position: fixed;
  top: 55%;
  right: 10px;
  transform: translateY(-50%);
  z-index: 999;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.sticky-item {
  width: 50px;
  height: 50px;
  background-color: #ffffff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  position: relative;
  font-size: 20px;
  color: #606266;
}

.sticky-item:hover {
  background-color: #409EFF;
  color: #ffffff;
  transform: translateY(-3px);
  box-shadow: 0 4px 16px 0 rgba(0, 0, 0, 0.15);
}

/* 悬停显示文字 */
.sticky-text {
  position: absolute;
  right: 60px;
  background-color: #303133;
  color: #ffffff;
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 14px;
  white-space: nowrap;
  opacity: 0;
  visibility: hidden;
  transition: all 0.3s ease;
  z-index: 1000;
}

.sticky-item:hover .sticky-text {
  opacity: 1;
  visibility: visible;
}

/* 响应式设计 */
@media (max-width: 992px) {
  .right-sticky {
    right: 5px;
    gap: 8px;
  }

  .sticky-item {
    width: 44px;
    height: 44px;
    font-size: 18px;
  }

  .sticky-text {
    right: 54px;
    padding: 4px 10px;
    font-size: 12px;
  }
}

@media (max-width: 576px) {
  .right-sticky {
    right: 8px;
    bottom: 20px;
    top: auto;
    transform: none;
    flex-direction: row;
    flex-wrap: wrap;
    width: auto;
    max-width: 50px;
    gap: 6px;
  }

  .sticky-item {
    width: 38px;
    height: 38px;
    font-size: 16px;
    border-radius: 8px;
  }

  .sticky-text {
    display: none;
  }
}

/* 未读消息红点提示 */
.unread-badge {
  position: absolute;
  top: -2px;
  right: -2px;
  z-index: 1001;
}

.unread-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  background-color: #f56c6c;
  border-radius: 50%;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.2);
    opacity: 0.7;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
</style>
