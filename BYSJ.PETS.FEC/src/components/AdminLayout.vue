<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import AppIcon, { type IconName } from '@/components/ui/AppIcon.vue'
import { getMerchantAuditList } from '@/api/admin/merchant'
import { getProductAuditList } from '@/api/admin/product'
import { useUserStore } from '@/stores/user'

/**
 * 管理员后台外壳。
 *
 * 定位是"队列 + 决定"：导航把两个待办队列放在最前，并在每一项旁给出队列深度，
 * 管理员在任何一页都能看到还有多少事在等。密度用 data-density="admin"
 * （0.85 倍间距、1680px 外壳），比买家端紧、比商家端更紧。
 *
 * 原来的外壳有四个问题，都在这里解决：
 *   1. 侧栏颜色写死在模板上（#304156 / #bfcbd9 / #409EFF），与设计令牌无关；
 *   2. 折叠按钮是一个悬浮的蓝色圆钮，压在菜单上，与"没有装饰"的世界不符；
 *   3. 组件内部注册了一个全局 router.beforeEach 守卫，会拦下"离开管理员后台"
 *      的跳转（连查看商城、退出登录都被弹回来），而且每次挂载都会再注册一次；
 *   4. 折叠后菜单只剩图标，没有任何可读名称。
 */

interface NavItem {
  /** 相对路由路径，空字符串表示工作台首页。 */
  path: string
  label: string
  icon: IconName
  /** 需要显示队列深度时填对应的待办键。 */
  queue?: 'merchant' | 'product'
}

interface NavGroup {
  title: string
  items: NavItem[]
}

const GROUPS: NavGroup[] = [
  {
    title: '待办',
    items: [
      { path: '', label: '待办总览', icon: 'home' },
      { path: 'product-audit', label: '商品审核', icon: 'goods', queue: 'product' },
      { path: 'merchant-audit', label: '商家认证审核', icon: 'id', queue: 'merchant' },
    ],
  },
  {
    title: '目录',
    items: [
      { path: 'category-management', label: '分类管理', icon: 'list' },
      { path: 'brand-management', label: '品牌管理', icon: 'tag' },
    ],
  },
  {
    title: '账号',
    items: [
      { path: 'merchant-management', label: '商家账户', icon: 'shop' },
      { path: 'user-management', label: '普通用户', icon: 'user' },
    ],
  },
  {
    title: '内容',
    items: [{ path: 'notice-publish', label: '公告与通知', icon: 'document' }],
  },
]

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const BASE = '/admin-dashboard'
const collapsed = ref(false)

/** 两个待办队列的深度。取不到时保留上一次的值，绝不让外壳因此报错。 */
const queueDepth = ref<{ merchant: number | null; product: number | null }>({
  merchant: null,
  product: null,
})

const currentUser = computed(() => userStore.userInfo)
const activePath = computed(() => route.path.replace(/\/+$/, ''))

function hrefOf(item: NavItem) {
  return item.path ? `${BASE}/${item.path}` : BASE
}

function isActive(item: NavItem) {
  return activePath.value === hrefOf(item).replace(/\/+$/, '')
}

function depthOf(item: NavItem) {
  if (!item.queue) return null
  return queueDepth.value[item.queue]
}

async function loadQueueDepth() {
  const [merchant, product] = await Promise.allSettled([
    getMerchantAuditList({ pageNum: 1, pageSize: 1 }),
    getProductAuditList({ pageNum: 1, pageSize: 1, auditStatus: 0 }),
  ])
  if (merchant.status === 'fulfilled') queueDepth.value.merchant = merchant.value.total ?? 0
  if (product.status === 'fulfilled') queueDepth.value.product = product.value.total ?? 0
}

function handleProfile() {
  void router.push(`${BASE}/profile`)
}

function handleLogout() {
  userStore.logout()
  void router.push('/login')
}

onMounted(() => {
  void loadQueueDepth()
})

// 处理完一条队列回到列表时，导航上的数字要跟着动。
watch(
  () => route.fullPath,
  () => {
    void loadQueueDepth()
  },
)
</script>

<template>
  <div class="admin" data-density="admin">
    <header class="topbar">
      <div class="topbar__inner">
        <RouterLink class="brand" :to="BASE">
          <img class="brand__mark" src="/相机.png" alt="摄影器材交易系统" />
          <span class="brand__text">
            <span class="brand__name">摄影器材交易系统</span>
            <span class="brand__role">平台管理员</span>
          </span>
        </RouterLink>

        <nav class="topnav" aria-label="管理员导航">
          <template v-for="group in GROUPS" :key="group.title">
            <RouterLink
              v-for="item in group.items"
              :key="item.path"
              class="topnav__item"
              :class="{ 'is-active': isActive(item) }"
              :to="hrefOf(item)"
            >
              {{ item.label }}
              <span v-if="depthOf(item)" class="topnav__count">{{ depthOf(item) }}</span>
            </RouterLink>
          </template>
        </nav>

        <div class="topbar__user">
          <RouterLink class="ghost-link" to="/index">查看商城</RouterLink>
          <el-dropdown>
            <button class="account" type="button">
              <AppIcon name="user" size="15" />
              <span class="account__name">
                {{ currentUser?.nickname || currentUser?.username || '管理员' }}
              </span>
              <AppIcon name="chevron-down" size="13" />
            </button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="handleProfile">账户信息</el-dropdown-item>
                <el-dropdown-item divided @click="handleLogout">安全退出</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </div>
    </header>

    <div class="admin__body">
      <aside class="rail" :class="{ 'rail--slim': collapsed }">
        <nav class="rail__nav" aria-label="后台导航">
          <template v-for="group in GROUPS" :key="group.title">
            <p v-if="!collapsed" class="rail__group">{{ group.title }}</p>
            <RouterLink
              v-for="item in group.items"
              :key="item.path"
              class="rail__item"
              :class="{ 'is-active': isActive(item) }"
              :to="hrefOf(item)"
              :title="collapsed ? item.label : undefined"
            >
              <AppIcon :name="item.icon" size="16" />
              <span v-if="!collapsed" class="rail__label">{{ item.label }}</span>
              <span v-if="depthOf(item)" class="rail__count">{{ depthOf(item) }}</span>
            </RouterLink>
          </template>
        </nav>

        <button class="rail__toggle" type="button" @click="collapsed = !collapsed">
          <AppIcon :name="collapsed ? 'chevron-right' : 'chevron-left'" size="14" />
          <span v-if="!collapsed">收起导航</span>
        </button>
      </aside>

      <main class="admin__main">
        <div class="admin__inner">
          <RouterView />
        </div>
      </main>
    </div>

    <footer class="admin__foot">
      <span>© 2026 摄影器材交易系统 · 管理员后台</span>
    </footer>
  </div>
</template>

<style scoped>
.admin {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  height: 100vh;
  background: var(--paper-1);
  color: var(--ink-1);
}

/* --- 顶栏 ---------------------------------------------------------------- */

.topbar {
  flex-shrink: 0;
  background: var(--paper-0);
  border-bottom: var(--edge);
}

.topbar__inner {
  display: flex;
  align-items: center;
  gap: var(--space-6);
  height: calc(56px * var(--dense));
  max-width: var(--shell-max);
  margin-inline: auto;
  padding-inline: var(--shell-gutter);
}

.brand {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
}

.brand:hover {
  text-decoration: none;
}

.brand__mark {
  width: calc(28px * var(--dense));
  height: calc(28px * var(--dense));
  object-fit: contain;
}

.brand__text {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.brand__name {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.brand__role {
  font-size: var(--text-2xs);
  color: var(--ink-3);
}

/* 窄屏时顶栏承载导航；宽屏时导航在左栏，这里只留品牌与账号。 */
.topnav {
  display: none;
  flex: 1;
  gap: var(--space-1);
  overflow-x: auto;
  scrollbar-width: none;
}

.topnav::-webkit-scrollbar {
  display: none;
}

.topnav__item {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 6px 10px;
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--ink-2);
  white-space: nowrap;
}

.topnav__item:hover {
  background: var(--paper-1);
  text-decoration: none;
}

.topnav__item.is-active {
  background: var(--paper-2);
  color: var(--ink-0);
  font-weight: 600;
}

.topnav__count,
.rail__count {
  min-width: 18px;
  padding: 0 5px;
  border-radius: var(--radius-pill);
  background: var(--ink-0);
  color: var(--on-ink);
  font-size: 10px;
  font-weight: 600;
  line-height: 16px;
  text-align: center;
  font-variant-numeric: tabular-nums;
}

.topbar__user {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-left: auto;
  flex-shrink: 0;
}

.ghost-link {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.ghost-link:hover {
  color: var(--ink-0);
}

.account {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  height: var(--control-h);
  padding-inline: 10px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  cursor: pointer;
}

.account:hover {
  border-color: var(--ink-3);
}

.account__name {
  font-size: var(--text-sm);
  max-width: 12ch;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* --- 主体 ---------------------------------------------------------------- */

.admin__body {
  display: flex;
  flex: 1;
  min-height: 0;
}

.rail {
  display: flex;
  flex-direction: column;
  width: calc(206px * var(--dense) + 14px);
  flex-shrink: 0;
  background: var(--paper-0);
  border-right: var(--edge);
  overflow: hidden;
  /* 折叠/展开是结构性布局变化，瞬时生效；动画只留给移动端抽屉的 transform */
  transition: none;
}

.rail--slim {
  width: 52px;
}

.rail__nav {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-3) var(--space-2);
}

.rail__group {
  padding: var(--space-3) var(--space-2) var(--space-1);
  font-size: var(--text-2xs);
  color: var(--ink-4);
  letter-spacing: 0.04em;
}

.rail__item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  height: var(--row-h);
  padding: 0 var(--space-2);
  border-radius: var(--radius-sm);
  color: var(--ink-2);
  font-size: var(--text-sm);
}

.rail__item:hover {
  background: var(--paper-1);
  color: var(--ink-0);
  text-decoration: none;
}

.rail__item.is-active {
  background: var(--paper-2);
  color: var(--ink-0);
  font-weight: 600;
}

.rail__label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.rail--slim .rail__item,
.rail--slim .rail__toggle {
  justify-content: center;
}

.rail__toggle {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-1);
  height: var(--row-h);
  border: none;
  border-top: var(--hairline);
  background: var(--paper-0);
  color: var(--ink-3);
  font-size: var(--text-xs);
  cursor: pointer;
}

.rail__toggle:hover {
  background: var(--paper-1);
  color: var(--ink-0);
}

.admin__main {
  flex: 1;
  min-width: 0;
  overflow-y: auto;
  padding: var(--pad-surface) 0;
}

.admin__inner {
  max-width: var(--shell-max);
  margin-inline: auto;
  padding-inline: var(--shell-gutter);
}

/* --- 页脚 ---------------------------------------------------------------- */

.admin__foot {
  flex-shrink: 0;
  padding: var(--space-2) var(--shell-gutter);
  border-top: var(--hairline);
  background: var(--paper-1);
  color: var(--ink-4);
  font-size: var(--text-2xs);
  text-align: center;
}

/* --- 窄屏：左栏收成横向导航条 --------------------------------------------- */

@media (max-width: 900px) {
  .admin {
    height: auto;
    min-height: 100vh;
  }

  /* 导航整条放到品牌行下面，横滑时不会被账号区挤到看不见。 */
  .topbar__inner {
    flex-wrap: wrap;
    height: auto;
    gap: var(--space-2);
    padding-block: var(--space-2);
  }

  .topnav {
    display: flex;
    order: 3;
    flex-basis: 100%;
  }

  .rail,
  .rail--slim {
    display: none;
  }

  .admin__body {
    display: block;
  }

  .admin__main {
    overflow: visible;
  }

  .ghost-link {
    display: none;
  }

  .account__name {
    max-width: 8ch;
  }
}
</style>
