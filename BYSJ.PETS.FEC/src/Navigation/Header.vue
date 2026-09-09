<template>
  <div class="app-container">
    <!-- 顶部导航栏（全局复用） -->
    <div class="header" :class="{ 'header-hidden': isHidden }">
      <!-- 移动端顶部栏 -->
      <div class="mobile-header">
        <el-icon class="menu-icon" @click="toggleMobileMenu"><Menu /></el-icon>
        <img class="mobile-logo" src="../../public/相机.png" alt="logo" @click="goIndex" />
        <div class="mobile-user" @click="handleUserClick">
          <el-icon><User /></el-icon>
        </div>
      </div>

      <!-- 桌面端导航菜单 -->
      <el-menu
        :default-active="activeIndex"
        class="el-menu-demo desktop-menu"
        mode="horizontal"
        router
        @select="handleSelect"
      >
        <!-- Logo项 -->
        <el-menu-item index="/index" class="logo-item" style="margin-left: 3%; cursor: pointer">
          <img style="width: 80px" src="../../public/相机.png" alt="logo" />
          <h2 style="margin: 1px">摄影器材交易系统</h2>
        </el-menu-item>

        <!-- 导航项：index 直接绑定路由路径 -->
        <el-menu-item index="/index">首页</el-menu-item>
        <el-menu-item index="/shop">器材商城</el-menu-item>
        <el-menu-item index="/second-hand">二手交易</el-menu-item>
        <el-menu-item index="/rental">租赁中心</el-menu-item>
        <el-menu-item index="/community">社区订阅</el-menu-item>

        <el-sub-menu index="/support">
          <template #title>关于与支持</template>
          <el-menu-item index="/support/app">APP下载</el-menu-item>
          <el-menu-item index="/support/faq">帮助中心</el-menu-item>
          <el-menu-item index="/support/help">以旧换新</el-menu-item>
          <el-menu-item index="/support/feedback">反馈建议</el-menu-item>
          <el-sub-menu index="/support/about">
            <template #title>关于我们</template>
            <el-menu-item index="/support/about/website">我们的故事</el-menu-item>
            <el-menu-item index="/support/about/contact">联系我们</el-menu-item>
            <el-menu-item index="/support/about/join">加入我们</el-menu-item>
            <el-menu-item index="/support/about/plan">计划</el-menu-item>
          </el-sub-menu>
        </el-sub-menu>

        <!-- 根据登录状态显示不同的用户菜单 -->
        <template v-if="isLoggedIn">
          <el-sub-menu index="/profile">
            <template #title>
              <el-icon><User /></el-icon>
              个人中心
            </template>
            <el-menu-item index="/profile">个人信息</el-menu-item>
            <el-menu-item index="/address">地址管理</el-menu-item>
            <el-menu-item index="/orders">我的订单</el-menu-item>
            <el-menu-item index="/favorites">我的收藏</el-menu-item>
            <el-menu-item index="/cart">购物车</el-menu-item>
            <el-menu-item index="/profile/vip">VIP</el-menu-item>
            <el-menu-item index="/logout" @click="handleLogout">安全退出</el-menu-item>
          </el-sub-menu>
        </template>
        <template v-else>
          <el-sub-menu index="/auth">
            <template #title>
              <el-icon><User /></el-icon>
              登录|注册
            </template>
            <el-menu-item index="/login">登录</el-menu-item>
            <el-menu-item index="/register">注册</el-menu-item>
          </el-sub-menu>
        </template>
      </el-menu>
    </div>

    <!-- 移动端菜单遮罩层 -->
    <div class="mobile-overlay" v-if="showMobileMenu" @click="toggleMobileMenu"></div>

    <!-- 移动端菜单抽屉 -->
    <div class="mobile-menu" :class="{ 'mobile-menu-open': showMobileMenu }">
      <div class="mobile-menu-header">
        <img src="../../public/相机.png" alt="logo" class="mobile-menu-logo" />
        <span>摄影器材交易系统</span>
        <el-icon class="close-icon" @click="toggleMobileMenu"><Close /></el-icon>
      </div>

      <!-- 移动端用户区域 -->
      <div class="mobile-user-area" v-if="isLoggedIn">
        <div class="user-info">
          <el-icon :size="40"><User /></el-icon>
          <span>个人中心</span>
        </div>
        <div class="user-actions">
          <div class="action-item" @click="goTo('/profile')">
            <el-icon><User /></el-icon>
            <span>个人信息</span>
          </div>
          <div class="action-item" @click="goTo('/orders')">
            <el-icon><Document /></el-icon>
            <span>我的订单</span>
          </div>
          <div class="action-item" @click="goTo('/favorites')">
            <el-icon><Star /></el-icon>
            <span>我的收藏</span>
          </div>
          <div class="action-item" @click="goTo('/cart')">
            <el-icon><ShoppingCart /></el-icon>
            <span>购物车</span>
          </div>
          <div class="action-item" @click="handleLogout">
            <el-icon><SwitchButton /></el-icon>
            <span>安全退出</span>
          </div>
        </div>
      </div>
      <div class="mobile-user-area" v-else @click="goTo('/login')">
        <div class="user-info">
          <el-icon :size="40"><User /></el-icon>
          <span>点击登录 / 注册</span>
        </div>
      </div>

      <el-menu
        :default-active="activeIndex"
        class="mobile-nav-menu"
        router
        @select="handleMobileSelect"
      >
        <el-menu-item index="/index">
          <el-icon><HomeFilled /></el-icon>
          <span>首页</span>
        </el-menu-item>
        <el-menu-item index="/shop">
          <el-icon><ShoppingCart /></el-icon>
          <span>器材商城</span>
        </el-menu-item>
        <el-menu-item index="/second-hand">
          <el-icon><Goods /></el-icon>
          <span>二手交易</span>
        </el-menu-item>
        <el-menu-item index="/rental">
          <el-icon><Timer /></el-icon>
          <span>租赁中心</span>
        </el-menu-item>
        <el-menu-item index="/community">
          <el-icon><ChatLineRound /></el-icon>
          <span>社区订阅</span>
        </el-menu-item>

        <el-sub-menu index="/support">
          <template #title>
            <el-icon><InfoFilled /></el-icon>
            <span>关于与支持</span>
          </template>
          <el-menu-item index="/support/app">APP下载</el-menu-item>
          <el-menu-item index="/support/faq">帮助中心</el-menu-item>
          <el-menu-item index="/support/help">以旧换新</el-menu-item>
          <el-menu-item index="/support/feedback">反馈建议</el-menu-item>
          <el-sub-menu index="/support/about">
            <template #title>关于我们</template>
            <el-menu-item index="/support/about/website">我们的故事</el-menu-item>
            <el-menu-item index="/support/about/contact">联系我们</el-menu-item>
            <el-menu-item index="/support/about/join">加入我们</el-menu-item>
            <el-menu-item index="/support/about/plan">计划</el-menu-item>
          </el-sub-menu>
        </el-sub-menu>
      </el-menu>
    </div>

    <!-- 内容区域（动态切换） -->
    <div class="main-content">
      <RouterView />
    </div>
    <!-- 右 sticky 导航栏（全局复用） -->
    <RightSticky />
  </div>
  <!-- 页脚（全局复用） -->
  <Footer />
</template>

<script lang="ts" setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import Footer from '@/Navigation/Footer.vue'
import RightSticky from '@/Navigation/RightSticky.vue'
import {
  User,
  Menu,
  Close,
  HomeFilled,
  ShoppingCart,
  Goods,
  Timer,
  ChatLineRound,
  InfoFilled,
  Document,
  Star,
  SwitchButton
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const isLoggedIn = computed(() => userStore.isLoggedIn)
const activeIndex = computed(() => route.path)
const isHidden = ref(false)
const showMobileMenu = ref(false)
let lastScrollTop = 0

const handleScroll = () => {
  const scrollTop = window.pageYOffset || document.documentElement.scrollTop
  if (scrollTop > 100) {
    if (scrollTop > lastScrollTop) {
      isHidden.value = true
    } else {
      isHidden.value = false
    }
  } else {
    isHidden.value = false
  }
  lastScrollTop = scrollTop
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

const toggleMobileMenu = () => {
  showMobileMenu.value = !showMobileMenu.value
}

const handleUserClick = () => {
  showMobileMenu.value = true
}

const goIndex = () => {
  router.push('/index')
}

const goTo = (path: string) => {
  showMobileMenu.value = false
  router.push(path)
}

const handleSelect = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}

const handleMobileSelect = () => {
  showMobileMenu.value = false
}

const handleLogout = () => {
  try {
    userStore.logout()
    showMobileMenu.value = false
  } catch (error) {
    console.error('退出登录失败:', error)
    ElMessage.error('退出登录失败，请重试')
  }
}
</script>

<style scoped>
.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  background: #fff;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease;
  transform: translateY(0);
}

.header.header-hidden {
  transform: translateY(-100%);
}

.main-content {
  flex: 1;
  padding: 20px;
  margin-top: 70px;
}

.el-menu--horizontal {
  --el-menu-horizontal-height: 70px;
  display: flex;
  width: 100%;
  align-items: center;
}

.el-menu--horizontal > .el-menu-item:nth-child(1) {
  margin-right: calc(10% - 27.5px);
  justify-content: center;
  flex-shrink: 0;
}

.el-menu--horizontal > .el-menu-item:not(:nth-child(1)) {
  font-size: 1rem !important;
  font-weight: 500;
  padding: 0 20px !important;
}

:deep(.el-menu--horizontal > .el-sub-menu > .el-sub-menu__title) {
  font-size: 1rem !important;
  font-weight: 500;
  padding: 0 32px !important;
}

:deep(.el-menu-item.logo-item:hover),
:deep(.el-menu-item.logo-item.is-active) {
  color: var(--el-menu-text-color) !important;
  background-color: transparent !important;
}

.mobile-header {
  display: none;
}

.mobile-overlay {
  display: none;
}

.mobile-menu {
  display: none;
}

.desktop-menu {
  display: flex;
}

@media (max-width: 992px) {
  .desktop-menu {
    display: none;
  }

  .mobile-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 15px;
    height: 60px;
  }

  .menu-icon {
    font-size: 24px;
    cursor: pointer;
    padding: 5px;
  }

  .mobile-logo {
    width: 40px;
    height: 40px;
    cursor: pointer;
  }

  .mobile-user {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: #409EFF;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    cursor: pointer;
  }

  .mobile-overlay {
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 1999;
  }

  .mobile-menu {
    display: block;
    position: fixed;
    top: 0;
    left: -280px;
    width: 280px;
    height: 100vh;
    background-color: #fff;
    z-index: 2000;
    transition: left 0.3s ease;
    overflow-y: auto;
  }

  .mobile-menu.mobile-menu-open {
    left: 0;
  }

  .mobile-menu-header {
    display: flex;
    align-items: center;
    padding: 15px;
    background-color: #409EFF;
    color: #fff;
  }

  .mobile-menu-logo {
    width: 40px;
    height: 40px;
    margin-right: 10px;
  }

  .mobile-menu-header span {
    flex: 1;
    font-size: 16px;
    font-weight: 600;
  }

  .close-icon {
    font-size: 20px;
    cursor: pointer;
  }

  .mobile-user-area {
    padding: 20px 15px;
    border-bottom: 1px solid #e4e7ed;
    cursor: pointer;
  }

  .user-info {
    display: flex;
    align-items: center;
    gap: 15px;
    margin-bottom: 15px;
  }

  .user-info span {
    font-size: 16px;
    font-weight: 500;
  }

  .user-actions {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
  }

  .action-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px;
    background-color: #f5f7fa;
    border-radius: 8px;
    cursor: pointer;
    font-size: 14px;
  }

  .action-item:hover {
    background-color: #e4e7ed;
  }

  .mobile-nav-menu {
    border-right: none;
  }

  .mobile-nav-menu .el-menu-item,
  .mobile-nav-menu .el-sub-menu__title {
    height: 50px;
    line-height: 50px;
  }

  .main-content {
    margin-top: 60px;
    padding: 15px;
  }
}

@media (max-width: 576px) {
  .main-content {
    padding: 10px;
  }
}
</style>
