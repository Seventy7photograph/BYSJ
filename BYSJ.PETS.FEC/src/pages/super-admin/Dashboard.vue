<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import StatStrip, { type StatEntry } from '@/components/ui/StatStrip.vue'
import {
  fetchOverview,
  readableError,
  type SuperAdminOverview,
} from '@/api/super-admin'
import { ACCOUNT_STATUS, USER_TYPE, labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative, maskPhone } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 超管首页。
 *
 * 超管的职责是"授权"，所以这一页只回答四件事：有几个管理员账号、几个被停用、
 * 有几个角色、一共有多少条权限项，再给出账号清单与角色权限量。
 * 原来的页面是标准的大数字仪表盘模板：8 张卡片（用户数 / 商家数 / 商品数 /
 * 订单数 / 成交额）加一排写死的 "+12.5% 较上月"，那些涨跌数字后端并不提供，
 * 也没人知道是按什么统计的。
 */

const userStore = useUserStore()

const loading = ref(true)
const error = ref('')
const overview = ref<SuperAdminOverview | null>(null)

const operator = computed(() => userStore.userInfo?.nickname || userStore.userInfo?.username || '')
const superAdminLabel = computed(() => labelOf(USER_TYPE, 4).label)

const stats = computed<StatEntry[]>(() => {
  const data = overview.value
  return [
    {
      label: '管理员账号',
      value: data ? data.adminCount : '—',
      unit: '个',
      note: '账号类型为「管理员」',
    },
    {
      label: '已停用账号',
      value: data ? data.disabledCount : '—',
      unit: '个',
      tone: data && data.disabledCount > 0 ? 'vermilion' : 'default',
      note: '停用后无法登录后台',
    },
    { label: '角色', value: data ? data.roleCount : '—', unit: '个', note: '与账号类型对应' },
    { label: '权限项', value: data ? data.permissionCount : '—', unit: '条', note: '按模块分组维护' },
  ]
})

/** 角色按最后更新时间倒序：这一栏要替代"最近的角色权限变更"。 */
const roles = computed(() => {
  const list = overview.value?.roles ?? []
  return [...list].sort((a, b) => {
    const left = a.updateTime ?? a.createTime ?? ''
    const right = b.updateTime ?? b.createTime ?? ''
    return right.localeCompare(left)
  })
})

function statusOf(status: number) {
  return labelOf(ACCOUNT_STATUS, status, '状态未知')
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    overview.value = await fetchOverview()
  } catch (e) {
    overview.value = null
    error.value = readableError(e, '后台数据加载失败')
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <SectionHead
      title="超级管理员后台"
      :note="operator ? `${operator} · ${superAdminLabel} · 负责角色与权限` : superAdminLabel"
      size="lg"
    >
      <template #action>
        <button class="btn" type="button" :disabled="loading" @click="load">
          <AppIcon name="refresh" size="14" />
          刷新
        </button>
      </template>
    </SectionHead>

    <StatStrip :entries="stats" :loading="loading" />

    <div v-if="error" class="block">
      <EmptyState title="后台数据加载失败" :note="error">
        <button class="btn" type="button" @click="load">
          <AppIcon name="refresh" size="14" />
          重新加载
        </button>
      </EmptyState>
    </div>

    <div v-else class="grid">
      <section class="plate">
        <header class="plate__head">
          <div>
            <p class="plate__title">管理员账号</p>
            <p class="plate__note">
              <template v-if="loading">正在读取…</template>
              <template v-else-if="overview">
                共 {{ overview.adminCount }} 个，其中 {{ overview.disabledCount }} 个已停用
              </template>
            </p>
          </div>
          <RouterLink class="btn" to="/super-admin-dashboard/admin-management">管理账号</RouterLink>
        </header>

        <div v-if="loading" class="plate__body">
          <div v-for="n in 4" :key="n" class="ghost-row">
            <span class="ghost ghost--lg skeleton" />
            <span class="ghost ghost--sm skeleton" />
            <span class="ghost ghost--sm skeleton" />
          </div>
        </div>

        <EmptyState
          v-else-if="!overview || overview.admins.length === 0"
          title="还没有管理员账号"
          note="新增一个管理员账号后，它会接手用户、商家与商品的审核队列。"
        >
          <RouterLink class="btn btn--solid" to="/super-admin-dashboard/admin-management">
            新增管理员
          </RouterLink>
        </EmptyState>

        <ul v-else class="list">
          <li v-for="admin in overview.admins" :key="admin.userId" class="list__row">
            <div class="list__main">
              <span class="list__name">{{ admin.username }}</span>
              <span v-if="admin.nickname" class="list__sub">{{ admin.nickname }}</span>
            </div>
            <span class="list__meta mono">#{{ admin.userId }}</span>
            <span class="list__meta">{{ admin.phone ? maskPhone(admin.phone) : '未填手机号' }}</span>
            <StatePill
              :label="statusOf(admin.status).label"
              :tone="statusOf(admin.status).tone"
            />
            <span class="list__meta" :title="formatDateTime(admin.createTime)">
              创建于 {{ formatRelative(admin.createTime) }}
            </span>
          </li>
        </ul>
      </section>

      <section class="plate">
        <header class="plate__head">
          <div>
            <p class="plate__title">角色与权限</p>
            <p class="plate__note">
              <template v-if="loading">正在读取…</template>
              <template v-else>按角色最后更新时间排列</template>
            </p>
          </div>
          <RouterLink class="btn" to="/super-admin-dashboard/dynamic-permission">
            配置权限
          </RouterLink>
        </header>

        <div v-if="loading" class="plate__body">
          <div v-for="n in 4" :key="n" class="ghost-row">
            <span class="ghost ghost--lg skeleton" />
            <span class="ghost ghost--sm skeleton" />
          </div>
        </div>

        <EmptyState
          v-else-if="roles.length === 0"
          title="还没有角色"
          note="角色决定后台能做什么；先在权限矩阵里建立一个角色。"
        >
          <RouterLink class="btn btn--solid" to="/super-admin-dashboard/dynamic-permission">
            新建角色
          </RouterLink>
        </EmptyState>

        <ul v-else class="list">
          <li v-for="role in roles" :key="role.roleId" class="list__row list__row--role">
            <div class="list__main">
              <span class="list__name">{{ role.roleName }}</span>
              <span class="list__sub mono">{{ role.roleCode }}</span>
            </div>
            <span class="list__meta">
              <template v-if="role.permissionCount === null">
                <StatePill label="权限项未知" tone="outline" />
              </template>
              <template v-else>{{ role.permissionCount }} 项权限</template>
            </span>
            <span class="list__meta" :title="formatDateTime(role.updateTime)">
              {{ formatRelative(role.updateTime) }}
            </span>
            <RouterLink
              class="link"
              :to="{ path: '/super-admin-dashboard/dynamic-permission', query: { role: role.roleId } }"
            >
              编辑
            </RouterLink>
          </li>
        </ul>

        <p v-if="!loading && roles.length" class="provenance">
          时间戳取自角色信息本身的最后更新；权限分配不会改写它，系统目前也没有逐次变更日志。
        </p>
      </section>
    </div>
  </div>
</template>

<style scoped>
.page {
  max-width: var(--shell-max);
  margin-inline: auto;
  padding-bottom: var(--space-8);
}

.block {
  margin-top: var(--space-5);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.grid {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 1fr);
  gap: var(--gap-surface);
  margin-top: var(--space-5);
  align-items: start;
}

.plate__head {
  align-items: flex-start;
}

.plate__title {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.plate__note {
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.list {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}

.list__row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-3) var(--pad-surface);
  border-bottom: var(--hairline);
  font-size: var(--text-sm);
}

.list__row:last-child {
  border-bottom: none;
}

.list__row:hover {
  background: var(--paper-1);
}

.list__main {
  display: flex;
  flex-direction: column;
  gap: 1px;
  flex: 1;
  min-width: 0;
}

.list__name {
  color: var(--ink-0);
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.list__sub {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.list__meta {
  flex-shrink: 0;
  color: var(--ink-3);
  font-size: var(--text-xs);
  white-space: nowrap;
}

.list__row--role .list__meta {
  min-width: 76px;
  text-align: right;
}

.provenance {
  padding: var(--space-3) var(--pad-surface) var(--pad-surface);
  border-top: var(--hairline);
  color: var(--ink-4);
  font-size: var(--text-2xs);
  line-height: 1.5;
}

.link {
  flex-shrink: 0;
  border: none;
  background: transparent;
  color: var(--ink-1);
  font-size: var(--text-sm);
  font-weight: 500;
  cursor: pointer;
}

.link:hover {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

.ghost-row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.ghost-row + .ghost-row {
  margin-top: var(--space-3);
}

.ghost {
  display: block;
  height: 13px;
}

.ghost--lg {
  width: 34%;
  height: 18px;
}

.ghost--sm {
  width: 16%;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 14px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  font-size: var(--text-sm);
  font-weight: 500;
  text-decoration: none;
  cursor: pointer;
  white-space: nowrap;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
  text-decoration: none;
}

.btn--solid {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.btn--solid:hover:not(:disabled) {
  background: #262d33;
  border-color: #262d33;
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

@media (max-width: 1100px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 640px) {
  .list__row {
    flex-wrap: wrap;
    gap: var(--space-2) var(--space-3);
  }

  .list__main {
    flex-basis: 100%;
  }
}
</style>
