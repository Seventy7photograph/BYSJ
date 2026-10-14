<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppIcon, { type IconName } from '@/components/ui/AppIcon.vue'
import { useUserStore } from '@/stores/user'

/**
 * 超管后台外壳。
 *
 * 这一层只回答一个问题：谁有什么权限。运营审核（用户、商家、商品、分类、
 * 品牌、公告）不在这里重做一遍，导航直接把人送到管理员后台的同一批页面 ——
 * 后端已经放行 userType = 4 访问 /admin/**，前端没有理由再抄一份路由和组件。
 *
 * 原来的实现有三处结构性问题，一并修掉：
 *   1. 组件里注册了全局 router.beforeEach：每次进入超管后台都会再挂一个守卫，
 *      且永不卸载。它会拦截所有离开后台的导航，连回商城首页都被弹回后台首页。
 *   2. 侧边栏颜色（#304156 / #409EFF）硬编码在模板属性上，绕开整套设计令牌。
 *   3. ≤900px 时侧栏仍固定占位，手机上的正文被压成一条。
 */

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

interface NavItem {
  label: string
  to: string
}

interface NavEntry {
  label: string
  icon: IconName
  to?: string
  items?: NavItem[]
  /** 该组属于管理员后台，跳过去之后外壳会换成管理员后台。 */
  crossConsole?: boolean
}

const NAV: NavEntry[] = [
  { label: '后台首页', icon: 'home', to: '/super-admin-dashboard' },
  { label: '管理员账号', icon: 'user', to: '/super-admin-dashboard/admin-management' },
  {
    label: '权限配置',
    icon: 'key',
    items: [
      { label: '权限清单', to: '/super-admin-dashboard/permission-list' },
      { label: '角色权限矩阵', to: '/super-admin-dashboard/dynamic-permission' },
    ],
  },
  {
    label: '运营审核',
    icon: 'shop',
    crossConsole: true,
    items: [
      { label: '管理员后台首页', to: '/admin-dashboard' },
      { label: '普通用户管理', to: '/admin-dashboard/user-management' },
      { label: '商家账户管理', to: '/admin-dashboard/merchant-management' },
      { label: '商家认证审核', to: '/admin-dashboard/merchant-audit' },
      { label: '商品审核', to: '/admin-dashboard/product-audit' },
      { label: '分类管理', to: '/admin-dashboard/category-management' },
      { label: '品牌管理', to: '/admin-dashboard/brand-management' },
      { label: '公告发布', to: '/admin-dashboard/notice-publish' },
    ],
  },
  { label: '个人中心', icon: 'id', to: '/super-admin-dashboard/profile' },
]

const collapsed = ref(false)
const drawerOpen = ref(false)
const narrow = ref(false)
const openGroups = ref<string[]>([])

const username = computed(() => userStore.userInfo?.username || '超级管理员')
const nickname = computed(() => userStore.userInfo?.nickname || '')

function isActive(to: string): boolean {
  return route.path === to
}

function groupHasRoute(entry: NavEntry): boolean {
  return entry.items?.some((item) => item.to === route.path) ?? false
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
  toggleGroup(entry.label)
}

function handleLogout() {
  userStore.logout()
}

function goProfile() {
  void router.push('/super-admin-dashboard/profile')
}

function goAdminConsole() {
  void router.push('/admin-dashboard')
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
    const next = NAV.filter(groupHasRoute).map((entry) => entry.label)
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
})

onBeforeUnmount(() => {
  mediaQuery?.removeEventListener('change', syncNarrow)
})
</script>

<template>
  <div class="console" data-density="admin">
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

      <RouterLink class="brand" to="/super-admin-dashboard">
        <span class="brand__name">摄影器材交易系统</span>
        <span class="brand__tag">超级管理员后台</span>
      </RouterLink>

      <span class="spacer" />

      <RouterLink class="jump" to="/admin-dashboard">
        <AppIcon name="link" size="14" />
        <span>管理员后台</span>
      </RouterLink>

      <el-dropdown trigger="click">
        <button class="account" type="button">
          <AppIcon name="user" size="15" />
          <span class="account__name">{{ username }}</span>
          <AppIcon name="chevron-down" size="13" />
        </button>
        <template #dropdown>
          <el-dropdown-menu>
            <el-dropdown-item @click="goProfile">个人中心</el-dropdown-item>
            <el-dropdown-item @click="goAdminConsole">管理员后台</el-dropdown-item>
            <el-dropdown-item divided @click="handleLogout">退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </header>

    <div class="console__body">
      <div v-if="narrow && drawerOpen" class="scrim" aria-hidden="true" @click="drawerOpen = false" />

      <aside
        class="aside"
        :class="{ 'is-collapsed': collapsed && !narrow, 'is-open': drawerOpen }"
        aria-label="超级管理员后台导航"
      >
        <nav class="nav">
          <template v-for="entry in NAV" :key="entry.label">
            <RouterLink
              v-if="entry.to"
              class="nav__item"
              :class="{ 'is-active': isActive(entry.to) }"
              :to="entry.to"
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

              <ul v-if="openGroups.includes(entry.label) && (!collapsed || narrow)" class="nav__sub">
                <li v-for="item in entry.items" :key="item.to">
                  <RouterLink
                    class="nav__sub-item"
                    :class="{ 'is-active': isActive(item.to) }"
                    :to="item.to"
                  >
                    <span>{{ item.label }}</span>
                    <AppIcon v-if="entry.crossConsole" name="link" size="12" />
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
      <p>© 2026 摄影器材交易系统 · 超级管理员后台</p>
      <p class="foot__note">{{ nickname ? `当前登录 ${nickname}` : '角色与权限中心' }}</p>
    </footer>
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

.jump {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding-inline: var(--space-3);
  border: var(--edge);
  border-radius: var(--radius-sm);
  color: var(--ink-2);
  font-size: var(--text-sm);
}

.jump:hover {
  border-color: var(--ink-3);
  color: var(--ink-0);
  text-decoration: none;
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
  max-width: 140px;
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
  width: 208px;
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
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
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
  background: rgb(13 17 20 / 45%);
}

@media (max-width: 900px) {
  .aside {
    position: fixed;
    top: 0;
    bottom: 0;
    left: 0;
    z-index: 30;
    width: 240px;
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

  .jump {
    display: none;
  }
}

@media (max-width: 520px) {
  .brand__tag {
    display: none;
  }

  .account__name {
    max-width: 88px;
  }
}
</style>
