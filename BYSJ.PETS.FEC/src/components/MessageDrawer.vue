<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { useMessageStore } from '@/stores/message'
import {
  getMessageList,
  noticeTypeLabel,
  MESSAGE_FILTERS,
  type MessageFilterKey,
  type MessageItem,
} from '@/api/message'
import { formatDateTime, formatRelative } from '@/utils/format'

/**
 * 消息中心。
 *
 * 原实现是一个必须靠父组件传 visible 才打开的 el-drawer，却被挂到 /messages
 * 路由上当页面用：直接访问 /messages 时 visible 默认 false，页面是一片空白。
 * 这里改成真正的页面级组件——列表、类型筛选、标记已读、删除都在页面里完成，
 * 未读数与顶栏徽标共用同一个 store。
 */
const messageStore = useMessageStore()

/** 一次取满一页，筛选在前端做，避免每切一个页签打一次请求。 */
const PAGE_SIZE = 100

const loading = ref(true)
const error = ref('')
const total = ref(0)
const activeFilter = ref<MessageFilterKey>('all')

const messages = computed<MessageItem[]>(() => messageStore.messages)
const unreadCount = computed(() => messageStore.unreadCount)

const filtered = computed(() => {
  const filter = MESSAGE_FILTERS.find((item) => item.key === activeFilter.value)
  if (!filter || !filter.codes) return messages.value
  const codes = filter.codes as readonly number[]
  return messages.value.filter((msg) => codes.includes(Number(msg.noticeType)))
})

const filterCounts = computed<Record<string, number>>(() => {
  const counts: Record<string, number> = { all: messages.value.length }
  for (const filter of MESSAGE_FILTERS) {
    if (!filter.codes) continue
    const codes = filter.codes as readonly number[]
    counts[filter.key] = messages.value.filter((msg) => codes.includes(Number(msg.noticeType))).length
  }
  return counts
})

const emptyTitle = computed(() =>
  activeFilter.value === 'all' ? '还没有收到消息' : '这一类暂时没有消息',
)

const emptyNote = computed(() =>
  activeFilter.value === 'all'
    ? '下单、支付、发货、退款与账号变动的通知都会出现在这里。'
    : '换一个类别看看，或选「全部」查看所有消息。',
)

async function load() {
  loading.value = true
  error.value = ''
  try {
    const page = await getMessageList({ page: 1, pageSize: PAGE_SIZE })
    // 写回 store：消息中心与顶栏未读徽标始终共用同一份数据。
    messageStore.messages = page.records
    total.value = page.total
  } catch (e) {
    error.value = e instanceof Error ? e.message : '消息加载失败，请稍后重试'
    total.value = 0
  } finally {
    loading.value = false
  }
}

async function markAsRead(msg: MessageItem) {
  if (Number(msg.isRead) === 1) return
  try {
    await messageStore.markAsRead(msg.noticeId)
  } catch {
    ElMessage.error('标记已读失败，请稍后重试')
  }
}

async function markAllAsRead() {
  if (unreadCount.value === 0) return
  try {
    await messageStore.markAllAsRead()
    ElMessage.success('已全部标记为已读')
  } catch {
    ElMessage.error('标记失败，请稍后重试')
  }
}

async function remove(msg: MessageItem) {
  try {
    await messageStore.deleteMessageById(msg.noticeId)
    ElMessage.success('消息已删除')
  } catch {
    ElMessage.error('删除失败，请稍后重试')
  }
}

onMounted(load)
</script>

<template>
  <div class="shell messages">
    <SectionHead title="消息中心" :note="`共 ${total} 条，未读 ${unreadCount} 条`" size="lg">
      <template #action>
        <button class="btn" type="button" :disabled="unreadCount === 0" @click="markAllAsRead">
          <AppIcon name="check" size="14" />
          全部已读
        </button>
      </template>
    </SectionHead>

    <div class="filters" role="tablist" aria-label="消息类型">
      <button
        v-for="filter in MESSAGE_FILTERS"
        :key="filter.key"
        class="filters__item"
        :class="{ 'is-active': activeFilter === filter.key }"
        type="button"
        role="tab"
        :aria-selected="activeFilter === filter.key"
        @click="activeFilter = filter.key"
      >
        {{ filter.label }}
        <span class="filters__count">{{ filterCounts[filter.key] ?? 0 }}</span>
      </button>
    </div>

    <!-- 加载：骨架行，结构与真实列表一致 -->
    <div v-if="loading" class="plate list" aria-busy="true">
      <div v-for="n in 5" :key="n" class="msg">
        <div class="msg__head">
          <span class="ghost ghost--pill skeleton" />
          <span class="ghost ghost--time skeleton" />
        </div>
        <span class="ghost ghost--line skeleton" />
        <span class="ghost ghost--line ghost--short skeleton" />
      </div>
    </div>

    <!-- 错误：说明发生了什么，并给出重试 -->
    <div v-else-if="error" class="plate state">
      <AppIcon name="warning" size="22" />
      <p class="state__title">消息没能加载出来</p>
      <p class="state__note">{{ error }}</p>
      <button class="btn" type="button" @click="load">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </div>

    <EmptyState v-else-if="!filtered.length" :title="emptyTitle" :note="emptyNote">
      <button
        v-if="activeFilter !== 'all'"
        class="btn"
        type="button"
        @click="activeFilter = 'all'"
      >
        查看全部消息
      </button>
    </EmptyState>

    <ol v-else class="plate list">
      <li
        v-for="msg in filtered"
        :key="msg.noticeId"
        class="msg"
        :class="{ 'is-unread': Number(msg.isRead) === 0 }"
      >
        <div class="msg__head">
          <span class="msg__title">
            <StatePill v-if="Number(msg.isRead) === 0" label="未读" tone="amber" />
            <StatePill
              :label="noticeTypeLabel(msg.noticeType).label"
              :tone="noticeTypeLabel(msg.noticeType).tone"
            />
          </span>
          <time class="msg__time" :title="formatDateTime(msg.createTime)">
            {{ formatRelative(msg.createTime) }}
          </time>
        </div>

        <p class="msg__body">{{ msg.content }}</p>

        <div class="msg__actions">
          <button
            v-if="Number(msg.isRead) === 0"
            class="link"
            type="button"
            @click="markAsRead(msg)"
          >
            标为已读
          </button>
          <button class="link link--danger" type="button" @click="remove(msg)">删除</button>
        </div>
      </li>
    </ol>

    <p v-if="!loading && !error && total > PAGE_SIZE" class="foot-note">
      共 {{ total }} 条消息，当前显示最近 {{ PAGE_SIZE }} 条。
    </p>
  </div>
</template>

<style scoped>
.messages {
  max-width: 880px;
}

/* --- filters ------------------------------------------------------------- */

.filters {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  margin-bottom: var(--space-4);
}

.filters__item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.filters__item:hover {
  background: var(--paper-2);
  color: var(--ink-1);
}

.filters__item.is-active {
  background: var(--paper-0);
  border-color: var(--line-2);
  color: var(--ink-0);
  font-weight: 600;
}

.filters__count {
  font-size: var(--text-2xs);
  font-variant-numeric: tabular-nums;
  color: var(--ink-4);
}

.filters__item.is-active .filters__count {
  color: var(--ink-3);
}

/* --- list ---------------------------------------------------------------- */

.list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.msg {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4) var(--space-5);
  border-bottom: var(--hairline);
}

.msg:last-child {
  border-bottom: none;
}

.msg.is-unread {
  background: var(--paper-1);
}

.msg__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
}

.msg__title {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
}

.msg__time {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.msg__body {
  margin: 0;
  font-size: var(--text-base);
  line-height: 1.65;
  color: var(--ink-1);
  white-space: pre-wrap;
  word-break: break-word;
}

.msg__actions {
  display: flex;
  gap: var(--space-4);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-xs);
  color: var(--ink-3);
  cursor: pointer;
}

.link:hover {
  color: var(--ink-0);
  text-decoration: underline;
}

.link--danger:hover {
  color: var(--signal-vermilion-deep);
}

/* --- states -------------------------------------------------------------- */

.state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-12) var(--space-6);
  text-align: center;
  color: var(--ink-3);
}

.state__title {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-1);
}

.state__note {
  font-size: var(--text-sm);
  max-width: 42ch;
}

/* --- primitives ---------------------------------------------------------- */

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding-inline: 14px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
  background: var(--paper-1);
  text-decoration: none;
}

.btn:disabled {
  color: var(--ink-4);
  border-color: var(--line-1);
  cursor: not-allowed;
}

.ghost {
  display: block;
  height: 13px;
}

.ghost--pill {
  width: 68px;
  height: 22px;
  border-radius: var(--radius-sm);
}

.ghost--time {
  width: 56px;
}

.ghost--line {
  width: 100%;
}

.ghost--short {
  width: 46%;
}

.foot-note {
  margin-top: var(--space-4);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

@media (max-width: 900px) {
  .messages {
    max-width: 100%;
  }
  .msg {
    padding: var(--space-3) var(--space-4);
  }
  .msg__head {
    flex-wrap: wrap;
    gap: var(--space-2);
  }
}

@media (max-width: 520px) {
  .msg {
    padding: var(--space-3) var(--space-4);
  }
  .filters__item {
    padding: 5px 10px;
  }
}
</style>

