<template>
  <div class="admin-layout">
    <el-container class="common-layout">
      <!-- 头部 -->
      <el-header class="dashboard-header">
        <div class="header-content">
          <div class="logo">
            <h1>摄影器材交易系统</h1>
            <span class="subtitle">管理员后台</span>
          </div>
          <div class="header-actions">
            <div class="user-info">
              <el-dropdown>
                <span class="user-name">
                  <el-icon class="avatar"><User /></el-icon>
                  {{ currentUser?.username || '管理员用户' }} 欢迎您
                  <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </span>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item @click="handleProfile">账户信息</el-dropdown-item>
                    <el-dropdown-item divided @click="handleLogout">安全退出</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>
        </div>
      </el-header>

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
            :default-openeds="defaultOpeneds"
            class="el-menu-vertical-demo"
            background-color="#304156"
            text-color="#bfcbd9"
            active-text-color="#409EFF"
            router
            :collapse="isCollapsed"
            :unique-opened="true"
          >
            <el-menu-item index="/admin-dashboard">
              <el-icon><House /></el-icon>
              <template #title>管理员首页</template>
            </el-menu-item>
            <el-menu-item index="/admin-dashboard/user-management">
              <el-icon><User /></el-icon>
              <template #title>普通用户管理</template>
            </el-menu-item>
            <el-sub-menu index="1">
              <template #title>
                <el-icon><OfficeBuilding /></el-icon>
                <span>商家管理</span>
              </template>
              <el-menu-item index="/admin-dashboard/merchant-management">账户管理</el-menu-item>
              <el-menu-item index="/admin-dashboard/merchant-audit">商家认证审核</el-menu-item>
            </el-sub-menu>
            <el-sub-menu index="2">
              <template #title>
                <el-icon><Goods /></el-icon>
                <span>商品管理</span>
              </template>
              <el-menu-item index="/admin-dashboard/product-audit">商品审核</el-menu-item>
              <el-menu-item index="/admin-dashboard/brand-management">品牌管理</el-menu-item>
              <el-menu-item index="/admin-dashboard/category-management">分类管理</el-menu-item>
            </el-sub-menu>
            <el-menu-item index="/admin-dashboard/notice-publish">
              <el-icon><Document /></el-icon>
              <template #title>公告发布</template>
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
              <p>© 2025 摄影器材交易系统 管理员后台</p>
            </div>
          </el-footer>
        </el-container>
      </el-container>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  User, ArrowDown, Menu, Goods, Document,
  OfficeBuilding, House, Fold, Expand
} from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

// 本地状态管理
const isCollapsed = ref(false)
const defaultOpeneds = ref([])

// 菜单折叠/展开方法
const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
}

// 退出登录
const handleLogout = () => {
  userStore.logout()
  router.push('/login')
}

// 账户信息
const handleProfile = () => {
  router.push('/admin-dashboard/profile')
}

// 计算当前激活的菜单项
const defaultActive = computed(() => {
  // 使用完整路径作为默认激活项
  return route.fullPath
})

// 计算当前用户信息
const currentUser = computed(() => {
  return userStore.userInfo
})

// 导航守卫，防止意外退到系统首页
router.beforeEach((to, from, next) => {
  // 检查用户是否在管理员后台页面
  const isInAdminDashboard = from.path.startsWith('/admin-dashboard')
  // 检查目标页面是否不是管理员后台页面
  const isNotAdminDashboard = !to.path.startsWith('/admin-dashboard')
  // 检查用户是否仍然登录
  const isLoggedIn = userStore.isLoggedIn
  // 检查目标页面是否是其他管理后台页面
  const isOtherDashboard = to.path.startsWith('/merchant-dashboard') || to.path.startsWith('/super-admin-dashboard')

  // 如果用户在管理员后台页面，且目标页面不是管理员后台页面，且用户仍然登录，且目标页面不是其他管理后台页面
  if (isInAdminDashboard && isNotAdminDashboard && isLoggedIn && !isOtherDashboard) {
    // 阻止导航，重定向到管理员后台首页
    next('/admin-dashboard')
  } else {
    // 允许正常导航
    next()
  }
})
</script>

<style scoped>
/* 管理员后台布局 */
.admin-layout {
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

.user-info {
  margin-left: 20px;
}

.user-name {
  display: flex;
  align-items: center;
  cursor: pointer;
  font-size: 14px;
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
  width: 64px;
  text-align: center;
  padding: 0 !important;
  justify-content: center;
}

.el-menu--collapse .el-menu-item span,
.el-menu--collapse .el-sub-menu__title span {
  display: none;
}

.el-menu--collapse .el-sub-menu__icon-arrow {
  display: none;
}

/* 修复子菜单展开问题 */
.el-sub-menu .el-menu {
  background-color: #263445;
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
  justify-content: center;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.footer-content p {
  margin: 0;
}
</style>
