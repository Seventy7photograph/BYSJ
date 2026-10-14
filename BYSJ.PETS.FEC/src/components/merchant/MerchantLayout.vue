<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppIcon, { type IconName } from '@/components/ui/AppIcon.vue'
import MerchantMessageDrawer from './MerchantMessageDrawer.vue'
import { useMessageStore } from '@/stores/message'
import { useUserStore } from '@/stores/user'

/**
 * 商家后台外壳。
 *
 * 后台要的是吞吐量：密度收紧一档（data-density="merchant" 把 --dense 定为 1.0、
 * 外壳放宽到 1600px），导航与正文同处一张灰底，只有表面边缘是 1px 描边。
 *
 * 原实现有三处结构性问题，这里一并修掉：
 *   1. 组件里注册了全局 router.beforeEach，每次进入商家后台都会再挂一个守卫，
 *      把整个应用的前进方向都锁死在 /merchant-dashboard 里，且永不卸载；
 *   2. 侧边栏颜色（#304156 / #409EFF）硬编码在模板属性里，绕开了整套设计令牌；
 *   3. ≤900px 时侧边栏仍固定占位，手机上正文被挤成一条。
 */

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const messageStore = useMessageStore()

interface NavItem {
  label: string
  to: string
  /** 同一路径下的多种模式，例如商品管理的全新 / 二手 / 租赁。 */
  type?: string
}

interface NavEntry {
  label: string
  icon: IconName
  to?: string
  items?: NavItem[]
}

const NAV: NavEntry[] = [
  { label: '商家首页', icon: 'home', to: '/merchant-dashboard' },
  {
    label: '商品管理',
    icon: 'goods',
    items: [
      { label: '全新商品', to: '/merchant-dashboard/product-management', type: 'new' },
      { label: '二手商品', to: '/merchant-dashboard/product-management', type: 'used' },
      { label: '租赁商品', to: '/merchant-dashboard/product-management', type: 'rental' },
    ],
  },
  { label: '商品发布', icon: 'sell', to: '/merchant-dashboard/product-add' },
  {
    label: '订单管理',
    icon: 'order',
    items: [
      { label: '全新订单', to: '/merchant-dashboard/order-management', type: 'new' },
      { label: '二手订单', to: '/merchant-dashboard/order-management', type: 'used' },
      { label: '租赁订单', to: '/merchant-dashboard/order-management', type: 'rental' },
      { label: '退款管理', to: '/merchant-dashboard/order-management', type: 'refund' },
    ],
  },
  { label: '库存管理', icon: 'box', to: '/merchant-dashboard/inventory-management' },
  { label: '店铺管理', icon: 'shop', to: '/merchant-dashboard/shop-management' },
]

/** 桌面端折叠侧栏；窄屏改用抽屉，两者互不干扰。 */
const collapsed = ref(false)
const drawerOpen = ref(false)
const narrow = ref(false)
const openGroups = ref<string[]>([])
const messageDrawerVisible = ref(false)

const username = computed(() => userStore.userInfo?.username || '商家')
const shopName = computed(() => userStore.userInfo?.shopName || userStore.userInfo?.nickname || '')
const unread = computed(() => messageStore.unreadCount)
const unreadLabel = computed(() => (unread.value > 99 ? '99+' : String(unread.value)))

function isActive(to: string | undefined, type?: string): boolean {
  if (!to || route.path !== to) return false
  const current = typeof route.query.type === 'string' ? route.query.type : ''
  if (type) return current === type
  return current === ''
}

/** 商品发布 / 编辑属于商品管理这一组，展开它让当前位置可见。 */
function groupHasRoute(entry: NavEntry): boolean {
  if (!entry.items) return false
  if (route.path === '/merchant-dashboard/product-add') return entry.label === '商品管理'
  return entry.items.some((item) => item.to === route.path)
}

function toggleGroup(label: string) {
  openGroups.value = openGroups.value.includes(label)
    ? openGroups.value.filter((item) => item !== label)
    : [...openGroups.value, label]
}

function onEntryClick(entry: NavEntry) {
  if (collapsed.value && entry.items) {
    collapsed.value = false
    if (!openGroups.value.includes(entry.label)) toggleGroup(entry.label)
    return
  }
  if (entry.items) toggleGroup(entry.label)
}

function handleLogout() {
  userStore.logout()
}

function openMessages() {
  messageDrawerVisible.value = true
  void messageStore.loadMessages(true)
}

function goProfile() {
  router.push('/merchant-dashboard/profile')
}

function goShopSettings() {
  router.push('/merchant-dashboard/shop-management')
}

let mediaQuery: MediaQueryList | null = null
function syncNarrow(event?: MediaQueryListEvent) {
  narrow.value = event ? event.matches : (mediaQuery?.matches ?? false)
  if (!narrow.value) drawerOpen.value = false
}

watch(
  () => route.fullPath,
  () => {
    drawerOpen.value = false
    const next = NAV.filter((entry) => groupHasRoute(entry)).map((entry) => entry.label)
    if (next[0] && !openGroups.value.includes(next[0])) {
      openGroups.value = [...openGroups.value, ...next]
    }
  },
  { immediate: true },
)

onMounted(() => {
  mediaQuery = window.matchMedia('(max-width: 900px)')
  syncNarrow()
  mediaQuery.addEventListener('change', syncNarrow)
  if (userStore.isLoggedIn) void messageStore.loadMessages()
})

onBeforeUnmount(() => {
  mediaQuery?.removeEventListener('change', syncNarrow)
})
</script>

<template>
  <div class="console" data-density="merchant">
    <header class="topbar">
      <button
        v-if="narrow"
        class="icon-btn"
        type="button"
        aria-label="打开导航"
        @click="drawerOpen = true"
      >
        <AppIcon name="menu" size="18" />
      </button>
      <button
        v-else
        class="icon-btn"
        type="button"
        :aria-label="collapsed ? '展开侧栏' : '收起侧栏'"
        @click="collapsed = !collapsed"
      >
        <AppIcon :name="collapsed ? 'chevron-right' : 'chevron-left'" size="18" />
      </button>

      <RouterLink class="brand" to="/merchant-dashboard">
        <span class="brand__name">摄影器材交易系统</span>
        <span class="brand__tag">商家后台</span>
      </RouterLink>

      <p v-if="shopName" class="brand__shop">{{ shopName }}</p>

      <span class="spacer" />

      <button
        class="icon-btn"
        type="button"
        :aria-label="unread > 0 ? `消息中心，${unread} 条未读` : '消息中心'"
        @click="openMessages"
      >
        <AppIcon name="bell" size="18" />
        <span v-if="unread > 0" class="dot">{{ unreadLabel }}</span>
      </button>

      <el-dropdown trigger="click">
        <button class="account" type="button">
          <AppIcon name="user" size="15" />
          <span class="account__name">{{ username }}</span>
          <AppIcon name="chevron-down" size="13" />
        </button>
        <template #dropdown>
          <el-dropdown-menu>
            <el-dropdown-item @click="goProfile">个人中心</el-dropdown-item>
            <el-dropdown-item @click="goShopSettings">店铺设置</el-dropdown-item>
            <el-dropdown-item divided @click="handleLogout">退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </header>

    <div class="console__body">
      <div
        v-if="narrow && drawerOpen"
        class="scrim"
        aria-hidden="true"
        @click="drawerOpen = false"
      />

      <aside
        class="aside"
        :class="{ 'is-collapsed': collapsed && !narrow, 'is-open': drawerOpen }"
        aria-label="商家后台导航"
      >
        <nav class="nav">
          <template v-for="entry in NAV" :key="entry.label">
            <RouterLink
              v-if="entry.to"
              class="nav__item"
              :class="{ 'is-active': isActive(entry.to) }"
              :to="entry.to!"
              :title="collapsed && !narrow ? entry.label : undefined"
            >
              <AppIcon :name="entry.icon" size="16" />
              <span class="nav__label">{{ entry.label }}</span>
            </RouterLink>

            <div v-else class="nav__group">
              <button
                class="nav__item nav__item--group"
                type="button"
                :class="{ 'is-current': groupHasRoute(entry) }"
                :title="collapsed && !narrow ? entry.label : undefined"
                :aria-expanded="openGroups.includes(entry.label)"
                @click="onEntryClick(entry)"
              >
                <AppIcon :name="entry.icon" size="16" />
                <span class="nav__label">{{ entry.label }}</span>
                <AppIcon
                  v-if="!collapsed || narrow"
                  class="nav__caret"
                  :name="openGroups.includes(entry.label) ? 'chevron-up' : 'chevron-down'"
                  size="12"
                />
              </button>

              <ul
                v-if="openGroups.includes(entry.label) && (!collapsed || narrow)"
                class="nav__sub"
              >
                <li v-for="item in entry.items" :key="item.label">
                  <RouterLink
                    class="nav__sub-item"
                    :class="{ 'is-active': isActive(item.to, item.type) }"
                    :to="{ path: item.to, query: item.type ? { type: item.type } : undefined }"
                  >
                    {{ item.label }}
                  </RouterLink>
                </li>
              </ul>
            </div>
          </template>
        </nav>
      </aside>

      <main class="main">
        <div class="main__inner">
          <RouterView />
        </div>
      </main>
    </div>

    <footer class="foot">
      <p>© 2026 摄影器材交易系统 · 商家后台</p>
      <p class="foot__note">库存低于安全库存时会在首页提示补货</p>
    </footer>

    <MerchantMessageDrawer v-model:visible="messageDrawerVisible" />
  </div>
</template>

<style scoped>
.console {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: var(--paper-1);
}

/* --- top bar -------------------------------------------------------------- */

.topbar {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  height: 56px;
  padding-inline: var(--space-3);
  background: var(--paper-0);
  border-bottom: var(--edge);
}

.icon-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-2);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.icon-btn:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

.dot {
  position: absolute;
  top: -2px;
  right: -4px;
  min-width: 16px;
  height: 16px;
  padding-inline: 4px;
  border-radius: var(--radius-pill);
  background: var(--signal-vermilion);
  color: var(--on-ink);
  font-size: var(--text-2xs);
  font-weight: 600;
  line-height: 16px;
  text-align: center;
}

.brand {
  display: flex;
  align-items: baseline;
  gap: var(--space-2);
  min-width: 0;
}

.brand:hover {
  text-decoration: none;
}

.brand__name {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
  white-space: nowrap;
}

.brand__tag {
  font-size: var(--text-xs);
  color: var(--ink-3);
  white-space: nowrap;
}

.brand__shop {
  padding-left: var(--space-3);
  border-left: var(--hairline);
  font-size: var(--text-xs);
  color: var(--ink-3);
  max-width: 220px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.account {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  height: 32px;
  padding-inline: var(--space-2);
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-2);
  font-size: var(--text-sm);
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.account:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

.account__name {
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* --- body ----------------------------------------------------------------- */

.console__body {
  display: flex;
  align-items: stretch;
  flex: 1;
  min-height: 0;
}

.aside {
  flex-shrink: 0;
  width: 196px;
  background: var(--paper-0);
  border-right: var(--edge);
  /* 折叠/展开是结构性布局变化，瞬时生效；动画只留给移动端抽屉的 transform */
  transition: none;
}

.aside.is-collapsed {
  width: 52px;
}

.nav {
  position: sticky;
  top: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: var(--space-2) var(--space-2) var(--space-6);
}

.nav__item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
  height: var(--row-h);
  padding-inline: var(--space-3);
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-2);
  font-size: var(--text-sm);
  font-weight: 500;
  text-align: left;
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.nav__item:hover {
  background: var(--paper-1);
  color: var(--ink-0);
  text-decoration: none;
}

.nav__item.is-active,
.nav__item.is-current {
  background: var(--paper-2);
  color: var(--ink-0);
  font-weight: 600;
}

.nav__label {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.is-collapsed .nav__label,
.is-collapsed .nav__caret {
  display: none;
}

.is-collapsed .nav__item {
  justify-content: center;
  padding-inline: 0;
}

.nav__caret {
  color: var(--ink-4);
}

.nav__sub {
  display: flex;
  flex-direction: column;
  gap: 1px;
  margin: 2px 0 var(--space-1);
  padding: 0 0 0 var(--space-6);
  list-style: none;
}

.nav__sub-item {
  display: block;
  padding: 7px var(--space-3);
  border-radius: var(--radius-sm);
  color: var(--ink-3);
  font-size: var(--text-sm);
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.nav__sub-item:hover {
  background: var(--paper-1);
  color: var(--ink-0);
  text-decoration: none;
}

.nav__sub-item.is-active {
  background: var(--paper-2);
  color: var(--ink-0);
  font-weight: 600;
}

.main {
  flex: 1;
  min-width: 0;
  padding: var(--space-5) var(--shell-gutter) var(--space-10);
}

.main__inner {
  width: 100%;
  max-width: var(--shell-max);
  margin-inline: auto;
}

.foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-3) var(--shell-gutter);
  background: var(--paper-0);
  border-top: var(--hairline);
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.foot__note {
  color: var(--ink-4);
}

.scrim {
  position: fixed;
  inset: 0;
  z-index: 20;
  background: var(--el-mask-color);
}

@media (max-width: 900px) {
  .aside {
    position: fixed;
    top: 0;
    bottom: 0;
    left: 0;
    z-index: 30;
    width: 232px;
    padding-top: var(--space-3);
    overflow-y: auto;
    transform: translateX(-100%);
    transition: transform var(--dur-state) var(--ease-out);
  }

  .aside.is-open {
    transform: none;
  }

  .nav__sub {
    padding-left: var(--space-4);
  }

  .main {
    padding-top: var(--space-4);
  }

  .foot {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-1);
  }

  .brand__shop {
    display: none;
  }
}
</style>
