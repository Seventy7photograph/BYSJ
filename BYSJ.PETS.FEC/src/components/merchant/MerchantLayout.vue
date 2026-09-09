<template>
  <div class="merchant-layout">
    <el-container class="common-layout">
      <!-- 头部 -->
      <el-header class="dashboard-header">
        <div class="header-content">
          <div class="logo">
            <h1>摄影器材交易系统</h1>
            <span class="subtitle">商家后台</span>
          </div>
          <div class="header-actions">
            <!-- 消息中心 -->
            <div class="message-info">
              <el-dropdown @command="handleMessageCommand">
                <div class="message-icon-container" @click="toggleMessageDrawer">
                  <el-icon class="message-icon"><Message /></el-icon>
                  <el-badge v-if="messageStore.unreadCount > 0" :value="messageStore.unreadCount" type="danger" class="message-badge" />
                </div>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="system">系统消息</el-dropdown-item>
                    <el-dropdown-item command="audit">审核通知</el-dropdown-item>
                    <el-dropdown-item command="inventory">库存预警</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
            <!-- 用户信息 -->
            <div class="user-info">
              <el-dropdown>
                <span class="user-name">
                  <el-icon class="avatar"><User /></el-icon>
                  {{ currentUser?.username || '商家用户' }}
                  <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </span>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item @click="handleProfile">个人中心</el-dropdown-item>
                    <el-dropdown-item @click="handleShopSettings">店铺设置</el-dropdown-item>
                    <el-dropdown-item divided @click="handleLogout">退出登录</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>
        </div>
      </el-header>

      <!-- 消息中心抽屉 -->
      <MerchantMessageDrawer
        v-model:visible="messageDrawerVisible"
      />

      <el-container>
        <!-- 左侧菜单 -->
        <el-aside :width="isCollapsed ? '64px' : '200px'" class="dashboard-aside">
          <!-- 菜单折叠/展开按钮 -->
          <div class="menu-toggle-container">
            <el-button
              type="primary"
              circle
              size="small"
              @click="toggleCollapse"
              class="menu-toggle-btn"
            >
              <el-icon v-if="isCollapsed"><Expand /></el-icon>
              <el-icon v-else><Fold /></el-icon>
            </el-button>
          </div>
          <el-menu
            :default-active="defaultActive"
            class="el-menu-vertical-demo"
            background-color="#304156"
            text-color="#bfcbd9"
            active-text-color="#409EFF"
            router
            :collapse="isCollapsed"
            :unique-opened="true"
          >
            <el-menu-item index="/merchant-dashboard">
              <el-icon><House /></el-icon>
              <template #title>商家首页</template>
            </el-menu-item>
            <el-sub-menu index="1">
              <template #title>
                <el-icon><Menu /></el-icon>
                <span>商品管理</span>
              </template>
              <el-menu-item index="/merchant-dashboard/product-management?type=new">全新商品</el-menu-item>
              <el-menu-item index="/merchant-dashboard/product-management?type=used">二手商品</el-menu-item>
              <el-menu-item index="/merchant-dashboard/product-management?type=rental">租赁商品</el-menu-item>
            </el-sub-menu>
            <el-menu-item index="/merchant-dashboard/product-add">
              <el-icon><Goods /></el-icon>
              <template #title>商品发布</template>
            </el-menu-item>
            <el-sub-menu index="3">
              <template #title>
                <el-icon><ShoppingCart /></el-icon>
                <span>订单管理</span>
              </template>
              <el-menu-item index="/merchant-dashboard/order-management?type=new">全新订单</el-menu-item>
              <el-menu-item index="/merchant-dashboard/order-management?type=used">二手订单</el-menu-item>
              <el-menu-item index="/merchant-dashboard/order-management?type=rental">租赁订单</el-menu-item>
              <el-menu-item index="/merchant-dashboard/order-management?type=refund">退款管理</el-menu-item>
            </el-sub-menu>
            <el-menu-item index="/merchant-dashboard/inventory-management">
              <el-icon><Box /></el-icon>
              <template #title>库存管理</template>
            </el-menu-item>
            <el-menu-item index="/merchant-dashboard/shop-management">
              <el-icon><OfficeBuilding /></el-icon>
              <template #title>店铺管理</template>
            </el-menu-item>
          </el-menu>
        </el-aside>

        <!-- 主内容区容器 -->
        <el-container>
          <!-- 主内容区 -->
          <el-main class="dashboard-main">
            <!-- 路由视图：渲染子路由内容 -->
            <router-view />
          </el-main>

          <!-- 页脚 -->
          <el-footer class="dashboard-footer">
            <div class="footer-content">
              <p>© 2025 摄影器材交易系统 商家后台</p>
              <p>技术支持：摄影器材交易系统开发团队</p>
            </div>
          </el-footer>
        </el-container>
      </el-container>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute, type NavigationGuardNext } from 'vue-router'
import {
  User, ArrowDown, Menu, Goods, ShoppingCart, Box,
  OfficeBuilding, House, Fold, Expand, Message
} from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import { useMessageStore } from '@/stores/message'
import MerchantMessageDrawer from './MerchantMessageDrawer.vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const messageStore = useMessageStore()

// 本地状态管理
const isCollapsed = ref(false)
// 消息中心相关状态
const messageDrawerVisible = ref(false)

// 菜单折叠/展开方法
const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
}

// 退出登录
const handleLogout = () => {
  userStore.logout()
  router.push('/login')
}

// 个人中心
const handleProfile = () => {
  router.push('/merchant-dashboard/profile')
}

// 店铺设置
const handleShopSettings = () => {
  router.push('/merchant-dashboard/shop-management')
}

// 计算当前激活的菜单项
const defaultActive = computed(() => {
  // 使用完整路径（包含查询参数）作为默认激活项
  return route.fullPath
})

// 计算当前用户信息
const currentUser = computed(() => {
  return userStore.userInfo
})

// 消息中心相关方法
// 切换消息抽屉显示
const toggleMessageDrawer = () => {
  messageDrawerVisible.value = !messageDrawerVisible.value
}

// 处理消息命令
const handleMessageCommand = (command: string) => {
  // 这里可以根据命令类型切换消息中心的标签页
  // 目前通过消息抽屉组件内部处理
  toggleMessageDrawer()
}

// 组件挂载时加载未读消息数量
onMounted(() => {
  // 只有登录后才加载未读消息数量
  if (userStore.isLoggedIn) {
    messageStore.loadMessages()
    // 定时刷新未读消息数量，每30秒刷新一次
    const interval = setInterval(() => {
      messageStore.loadMessages()
    }, 30000)

    // 组件卸载时清除定时器
    onUnmounted(() => clearInterval(interval))
  }
})

// 导航守卫，防止意外退到系统首页
router.beforeEach((to, from, next) => {
  // 检查用户是否在商家后台页面
  const isInMerchantDashboard = from.path.startsWith('/merchant-dashboard')
  // 检查目标页面是否不是商家后台页面
  const isNotMerchantDashboard = !to.path.startsWith('/merchant-dashboard')
  // 检查用户是否仍然登录
  const isLoggedIn = userStore.isLoggedIn
  // 检查目标页面是否是其他管理后台页面
  const isOtherDashboard = to.path.startsWith('/admin-dashboard') || to.path.startsWith('/super-admin-dashboard')

  // 如果用户在商家后台页面，且目标页面不是商家后台页面，且用户仍然登录，且目标页面不是其他管理后台页面
  if (isInMerchantDashboard && isNotMerchantDashboard && isLoggedIn && !isOtherDashboard) {
    // 阻止导航，重定向到商家后台首页
    next('/merchant-dashboard')
  } else {
    // 允许正常导航
    next()
  }
})
</script>

<style scoped>
/* 商家后台布局 */
.merchant-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.common-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

/* 头部样式 */
.dashboard-header {
  background-color: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 0;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 60px;
  padding: 0 20px;
}

.logo {
  display: flex;
  align-items: center;
}

.logo h1 {
  font-size: 20px;
  margin: 0;
  color: #304156;
}

.logo .subtitle {
  font-size: 14px;
  color: #409EFF;
  margin-left: 10px;
}

.header-actions {
  display: flex;
  align-items: center;
}

/* 消息中心样式 */
.message-info {
  margin-right: 20px;
}

.message-icon-container {
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  transition: all 0.3s ease;
}

.message-icon-container:hover {
  background-color: rgba(64, 158, 255, 0.1);
}

.message-icon {
  font-size: 20px;
  color: #606266;
  transition: color 0.3s ease;
}

.message-icon-container:hover .message-icon {
  color: #409EFF;
}

.message-badge {
  position: absolute;
  top: 5px;
  right: 5px;
  transform: scale(0.8);
}

/* 用户信息样式 */
.user-info {
  margin-left: 10px;
}

.user-name {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.avatar {
  margin-right: 5px;
}

/* 左侧菜单样式 */
.dashboard-aside {
  background-color: #304156;
  overflow: hidden;
  transition: width 0.3s ease;
  position: sticky;
  top: 0;
  height: calc(100vh - 60px);
  display: flex;
  flex-direction: column;
  z-index: 10;
}

/* 菜单切换容器 */
.menu-toggle-container {
  position: relative;
  display: flex;
  justify-content: flex-end;
  padding: 10px;
  z-index: 100;
}

/* 菜单切换按钮 */
.menu-toggle-btn {
  width: 36px !important;
  height: 36px !important;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50% !important;
  background-color: #409EFF !important;
  border: none !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  transition: all 0.3s ease;
}

.menu-toggle-btn:hover {
  background-color: #66b1ff !important;
  transform: scale(1.05);
}

/* 菜单内容 */
.el-menu-vertical-demo {
  overflow-y: auto;
  overflow-x: hidden;
  flex: 1;
  width: 100%;
  border-right: none;
}

/* 确保子菜单正常显示 */
.el-menu--collapse .el-menu-item,
.el-menu--collapse .el-sub-menu__title {
  padding: 0 20px !important;
}

/* 修复折叠状态下的样式 */
.el-menu--collapse {
  width: 64px;
}

.el-menu--collapse .el-menu-item span,
.el-menu--collapse .el-sub-menu__title span {
  display: none;
}

.el-menu--collapse .el-menu-item,
.el-menu--collapse .el-sub-menu__title {
  width: 64px;
  text-align: center;
  padding: 0 !important;
  justify-content: center;
}

.el-menu--collapse .el-sub-menu__icon-arrow {
  display: none;
}

/* 修复子菜单展开问题 */
.el-sub-menu .el-menu {
  background-color: #263445;
}

/* 修复菜单点击区域 */
.el-menu-item,
.el-sub-menu__title {
  width: 100%;
}

/* 主内容区样式 */
.dashboard-main {
  background-color: #f0f2f5;
  padding: 20px;
  overflow-y: auto;
  overflow-x: hidden;
  flex: 1;
  min-height: 0;
}



/* 底部页脚 */
.dashboard-footer {
  background-color: #fff;
  text-align: center;
  padding: 15px;
  color: #606266;
  font-size: 14px;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.05);
  margin-top: auto;
}

.footer-content {
  display: flex;
  justify-content: space-around;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.footer-content p {
  margin: 0;
}
</style>
