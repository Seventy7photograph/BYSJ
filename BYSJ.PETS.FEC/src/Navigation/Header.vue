<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { useMessageStore } from '@/stores/message'
import Footer from '@/Navigation/Footer.vue'
import RightSticky from '@/Navigation/RightSticky.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import { getCategories } from '@/api/user/shop'

/**
 * 前台商城的框架。
 *
 * 原实现把 Element 的水平菜单当导航用，并把「关于与支持」整个子树挂到了一
 * 批并不存在的路由上（/support/*、/logout、/profile/vip），点下去就是 404。
 * 这里换成真实导航：主导航是三条交易线，分类来自后端，搜索进商城。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const messageStore = useMessageStore()

const PRIMARY_NAV = [
  { label: '首页', to: '/index' },
  { label: '器材商城', to: '/shop' },
  { label: '二手交易', to: '/second-hand' },
  { label: '租赁中心', to: '/rental' },
  { label: '社区订阅', to: '/community' },
] as const

const isLoggedIn = computed(() => userStore.isLoggedIn)
const displayName = computed(
  () => userStore.userInfo?.nickname || userStore.userInfo?.username || '账户',
)
const unreadCount = computed(() => messageStore.unreadCount)

const keyword = ref('')
const mobileOpen = ref(false)
/** 返回顶栏：向下滚动时收起，向上滚动立刻回来。 */
const condensed = ref(false)
const categories = ref<{ code: string; name: string }[]>([])

let lastY = 0
function onScroll() {
  const y = window.scrollY
  condensed.value = y > 96 && y > lastY
  lastY = y
}

onMounted(async () => {
  window.addEventListener('scroll', onScroll, { passive: true })
  try {
    const res = await getCategories()
    // 后端 /shop/categories 返回 { categoryList, categoryTree }，两组都要兼容：
    // 之前这里按 data / list / 自身数组去找，永远拿不到 categoryList，分类条一直是空的。
    const list = res?.categoryList ?? res?.data?.categoryList ?? res?.data ?? res
    if (Array.isArray(list)) {
      categories.value = list
        .map((c: any) => ({ code: c.value ?? c.categoryCode, name: c.name ?? c.categoryName }))
        .filter((c: any) => c.code && c.name)
        .slice(0, 7)
    }
  } catch {
    // 分类拿不到就不显示分类条，主导航仍然可用。
  }
})

onUnmounted(() => window.removeEventListener('scroll', onScroll))

function submitSearch() {
  const q = keyword.value.trim()
  router.push({ path: '/shop', query: q ? { keyword: q } : {} })
  mobileOpen.value = false
}

/** 后端按分类编码筛选（product_category.category_code），所以传 code 而不是主键。 */
function goCategory(code: string) {
  router.push({ path: '/shop', query: { category: code } })
}

function go(path: string) {
  mobileOpen.value = false
  router.push(path)
}

function handleLogout() {
  try {
    userStore.logout()
    mobileOpen.value = false
  } catch {
    ElMessage.error('退出登录失败，请重试')
  }
}
</script>

<template>
  <div class="shell-root">
    <a class="skip" href="#main">跳到主要内容</a>

    <header class="topbar" :class="{ 'is-condensed': condensed }">
      <div class="shell topbar__inner">
        <RouterLink to="/index" class="brand" aria-label="摄影器材交易系统 首页">
          <img class="brand__mark" src="/相机.png" alt="" width="30" height="30" />
          <span class="brand__name">摄影器材交易系统</span>
        </RouterLink>

        <nav class="nav" aria-label="主导航">
          <RouterLink
            v-for="item in PRIMARY_NAV"
            :key="item.to"
            class="nav__link"
            :class="{ 'is-active': route.path === item.to }"
            :to="item.to"
          >
            {{ item.label }}
          </RouterLink>
        </nav>

        <form class="search" role="search" @submit.prevent="submitSearch">
          <AppIcon name="search" size="15" />
          <input
            v-model="keyword"
            class="search__input"
            type="search"
            placeholder="搜索机身、镜头、品牌"
            aria-label="搜索商品"
          />
          <button class="search__go" type="submit">搜索</button>
        </form>

        <div class="actions">
          <RouterLink class="icon-btn" to="/favorites" title="我的收藏" aria-label="我的收藏">
            <AppIcon name="star" size="17" />
          </RouterLink>
          <RouterLink class="icon-btn" to="/cart" title="购物车" aria-label="购物车">
            <AppIcon name="cart" size="17" />
          </RouterLink>

          <template v-if="isLoggedIn">
            <RouterLink class="icon-btn" to="/messages" title="消息" aria-label="消息中心">
              <AppIcon name="bell" size="17" />
              <span v-if="unreadCount > 0" class="dot">{{ unreadCount > 99 ? '99+' : unreadCount }}</span>
            </RouterLink>
            <el-dropdown trigger="click" placement="bottom-end">
              <button class="account" type="button">
                <span class="account__avatar">{{ displayName.slice(0, 1) }}</span>
                <span class="account__name">{{ displayName }}</span>
                <AppIcon name="chevron-down" size="13" />
              </button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item @click="go('/profile')">个人资料</el-dropdown-item>
                  <el-dropdown-item @click="go('/orders')">我的订单</el-dropdown-item>
                  <el-dropdown-item @click="go('/address')">收货地址</el-dropdown-item>
                  <el-dropdown-item @click="go('/favorites')">我的收藏</el-dropdown-item>
                  <el-dropdown-item divided @click="handleLogout">退出登录</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
          <template v-else>
            <RouterLink class="auth-link" to="/login">登录</RouterLink>
            <RouterLink class="auth-link auth-link--solid" to="/register">注册</RouterLink>
          </template>

          <button
            class="icon-btn burger"
            type="button"
            aria-label="打开菜单"
            @click="mobileOpen = true"
          >
            <AppIcon name="menu" size="18" />
          </button>
        </div>
      </div>

      <div v-if="categories.length" class="shell catbar">
        <span class="catbar__label">分类</span>
        <button
          v-for="cat in categories"
          :key="cat.code"
          class="catbar__item"
          type="button"
          @click="goCategory(cat.code)"
        >
          {{ cat.name }}
        </button>
        <RouterLink class="catbar__item catbar__item--all" to="/shop">全部商品</RouterLink>
      </div>
    </header>

    <main id="main" class="main">
      <RouterView />
    </main>

    <RightSticky />
    <Footer />

    <!-- 移动端抽屉 -->
    <div v-if="mobileOpen" class="scrim" @click="mobileOpen = false" />
    <aside class="drawer" :class="{ 'is-open': mobileOpen }" :aria-hidden="!mobileOpen">
      <div class="drawer__head">
        <span class="drawer__title">
          {{ isLoggedIn ? displayName : '未登录' }}
        </span>
        <button class="icon-btn" type="button" aria-label="关闭菜单" @click="mobileOpen = false">
          <AppIcon name="close" size="18" />
        </button>
      </div>

      <form class="drawer__search" @submit.prevent="submitSearch">
        <AppIcon name="search" size="15" />
        <input v-model="keyword" class="search__input" type="search" placeholder="搜索商品" />
      </form>

      <nav class="drawer__nav">
        <button v-for="item in PRIMARY_NAV" :key="item.to" class="drawer__item" type="button" @click="go(item.to)">
          {{ item.label }}
        </button>
      </nav>

      <nav class="drawer__nav drawer__nav--sub">
        <template v-if="isLoggedIn">
          <button class="drawer__item" type="button" @click="go('/profile')">个人资料</button>
          <button class="drawer__item" type="button" @click="go('/orders')">我的订单</button>
          <button class="drawer__item" type="button" @click="go('/cart')">购物车</button>
          <button class="drawer__item" type="button" @click="go('/favorites')">我的收藏</button>
          <button class="drawer__item" type="button" @click="go('/address')">收货地址</button>
          <button class="drawer__item drawer__item--danger" type="button" @click="handleLogout">
            退出登录
          </button>
        </template>
        <template v-else>
          <button class="drawer__item" type="button" @click="go('/login')">登录</button>
          <button class="drawer__item" type="button" @click="go('/register')">注册</button>
        </template>
      </nav>
    </aside>
  </div>
</template>

<style scoped>
.shell-root {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.skip {
  position: absolute;
  left: -9999px;
  top: 0;
  z-index: 2000;
  padding: 8px 14px;
  background: var(--ink-0);
  color: var(--paper-0);
}

.skip:focus {
  left: 8px;
  top: 8px;
}

/* --- top bar ------------------------------------------------------------- */

.topbar {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--paper-0);
  border-bottom: 1px solid var(--line-2);
  transition: transform 220ms var(--ease-out);
}

.topbar.is-condensed {
  transform: translateY(-4px);
}

.topbar__inner {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  height: 64px;
}

.brand {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-shrink: 0;
}

.brand:hover {
  text-decoration: none;
}

.brand__mark {
  width: 30px;
  height: 30px;
  object-fit: contain;
}

.brand__name {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
  letter-spacing: -0.02em;
  white-space: nowrap;
}

.nav {
  display: flex;
  align-items: center;
  gap: 2px;
  flex-shrink: 0;
}

.nav__link {
  padding: 6px 10px;
  border-radius: var(--radius-sm);
  font-size: var(--text-base);
  color: var(--ink-2);
  white-space: nowrap;
  transition: color var(--dur-state) ease, background-color var(--dur-state) ease;
}

.nav__link:hover {
  text-decoration: none;
  color: var(--ink-0);
  background: var(--paper-2);
}

.nav__link.is-active {
  color: var(--ink-0);
  font-weight: 600;
}

/* --- search -------------------------------------------------------------- */

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 1;
  min-width: 160px;
  max-width: 420px;
  height: 36px;
  padding-left: 10px;
  background: var(--paper-1);
  border: 1px solid var(--line-2);
  border-radius: var(--radius-xs);
  color: var(--ink-3);
  transition: border-color var(--dur-state) ease;
}

.search:focus-within {
  border-color: var(--ink-0);
  background: var(--paper-0);
}

.search__input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  font-size: var(--text-base);
  color: var(--ink-0);
}

.search__input::placeholder {
  color: var(--ink-4);
}

.search__go {
  height: 100%;
  padding-inline: 14px;
  border: none;
  border-left: 1px solid var(--line-2);
  background: transparent;
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.search__go:hover {
  background: var(--paper-2);
}

/* --- actions ------------------------------------------------------------- */

.actions {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  margin-left: auto;
  flex-shrink: 0;
}

.icon-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-2);
  cursor: pointer;
  transition: background-color var(--dur-state) ease, color var(--dur-state) ease;
}

.icon-btn:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

.dot {
  position: absolute;
  top: 2px;
  right: 2px;
  min-width: 15px;
  height: 15px;
  padding-inline: 3px;
  border-radius: var(--radius-pill);
  background: var(--signal-vermilion);
  color: #fff;
  font-size: 10px;
  font-weight: 600;
  line-height: 15px;
  text-align: center;
}

.account {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 8px 0 4px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-1);
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.account:hover {
  background: var(--paper-2);
}

.account__avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border-radius: var(--radius-pill);
  background: var(--ink-0);
  color: var(--paper-0);
  font-size: var(--text-xs);
  font-weight: 600;
}

.account__name {
  max-width: 96px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--text-sm);
}

.auth-link {
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--ink-1);
  white-space: nowrap;
}

.auth-link:hover {
  text-decoration: none;
  background: var(--paper-2);
}

.auth-link--solid {
  background: var(--ink-0);
  color: var(--paper-0);
  font-weight: 500;
}

.auth-link--solid:hover {
  background: #262d33;
}

.burger {
  display: none;
}

/* --- category bar -------------------------------------------------------- */

.catbar {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  height: 38px;
  overflow-x: auto;
  scrollbar-width: none;
}

.catbar::-webkit-scrollbar {
  display: none;
}

.catbar__label {
  flex-shrink: 0;
  margin-right: var(--space-1);
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.catbar__item {
  flex-shrink: 0;
  padding: 4px 9px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-2);
  cursor: pointer;
  white-space: nowrap;
  transition: background-color var(--dur-state) ease, color var(--dur-state) ease;
}

.catbar__item:hover {
  text-decoration: none;
  background: var(--paper-2);
  color: var(--ink-0);
}

.catbar__item--all {
  margin-left: auto;
  color: var(--ink-3);
  font-weight: 500;
}

/* --- main & drawer ------------------------------------------------------- */

.main {
  flex: 1;
  padding-block: var(--space-6) var(--space-16);
}

.drawer__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  border-bottom: var(--hairline);
}

.drawer__title {
  font-weight: 600;
  color: var(--ink-0);
}

.drawer__search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin: 16px;
  padding: 0 10px;
  height: 38px;
  background: var(--paper-1);
  border: 1px solid var(--line-2);
  border-radius: var(--radius-xs);
  color: var(--ink-3);
}

.drawer__nav {
  display: flex;
  flex-direction: column;
  padding: 4px 8px 12px;
}

.drawer__nav--sub {
  border-top: var(--hairline);
  padding-top: 12px;
}

.drawer__item {
  padding: 11px 10px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  text-align: left;
  font-size: var(--text-base);
  color: var(--ink-1);
  cursor: pointer;
}

.drawer__item:hover {
  background: var(--paper-2);
}

.drawer__item--danger {
  color: var(--signal-vermilion-deep);
}

.drawer {
  display: none;
}

@media (max-width: 1080px) {
  .search {
    max-width: 240px;
  }
  .brand__name {
    display: none;
  }
}

@media (max-width: 900px) {
  .nav,
  .search,
  .catbar {
    display: none;
  }

  .burger {
    display: inline-flex;
  }

  .topbar__inner {
    height: 56px;
    gap: var(--space-2);
  }

  .brand__name {
    display: inline;
    font-size: var(--text-base);
  }

  .account__name {
    display: none;
  }

  .scrim {
    position: fixed;
    inset: 0;
    z-index: 199;
    background: rgb(13 17 20 / 45%);
  }

  .drawer {
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    width: min(300px, 84vw);
    z-index: 200;
    background: var(--paper-0);
    box-shadow: var(--lift);
    transform: translateX(-100%);
    transition: transform 240ms var(--ease-out);
    overflow-y: auto;
  }

  .drawer.is-open {
    transform: none;
  }

  .main {
    padding-block: var(--space-4) var(--space-12);
  }
}
</style>
