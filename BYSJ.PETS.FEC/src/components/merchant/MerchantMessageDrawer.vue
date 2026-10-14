<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { useMessageStore } from '@/stores/message'
import { useUserStore } from '@/stores/user'
import {
  getMessageList,
  MESSAGE_FILTERS,
  noticeTypeLabel,
  type MessageFilterKey,
  type MessageItem,
} from '@/api/message'
import { formatDateTime, formatRelative } from '@/utils/format'

/**
 * 商家后台的消息抽屉。
 *
 * 与前台 /messages 用同一份数据源（@/stores/message）和同一套视觉：
 * 消息类型字典、未读数、标记已读与删除都走同一个 store，顶栏徽标与抽屉
 * 不会出现两套未读逻辑。原来的实现自己维护了一份 messageType → 标题的
 * if-else（其中「库存预警」直接等同于订单通知）、用鼠标拖拽删除，还在
 * computed 里向父组件 emit —— 这些都不再需要。
 */
const props = withDefaults(defineProps<{ visible: boolean }>(), { visible: false })
const emit = defineEmits<{ 'update:visible': [boolean]; 'update:unread-count': [number] }>()

const PAGE_SIZE = 100

const messageStore = useMessageStore()
const userStore = useUserStore()
const loading = ref(false)
const error = ref('')
const total = ref(0)
const activeFilter = ref<MessageFilterKey>('all')

const visible = computed({
  get: () => props.visible,
  set: (value: boolean) => {
    emit('update:visible', value)
    if (value) void load()
  },
})

const messages = computed<MessageItem[]>(() => messageStore.messages)
const unreadCount = computed(() => messageStore.unreadCount)

watch(unreadCount, (value) => emit('update:unread-count', value), { immediate: true })

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
    ? '订单、退款、审核与账号变动的通知都会出现在这里。'
    : '换一个类别看看，或选「全部」查看所有消息。',
)

async function load() {
  // 未登录时不发请求：抽屉随布局一起挂载，凭据已经失效时不该再打一次接口。
  if (!userStore.isLoggedIn) {
    total.value = 0
    error.value = ''
    loading.value = false
    return
  }
  loading.value = true
  error.value = ''
  try {
    const page = await getMessageList({ page: 1, pageSize: PAGE_SIZE })
    // 写回 store：抽屉与顶栏徽标始终共用同一份数据。
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
    total.value = Math.max(0, total.value - 1)
    ElMessage.success('消息已删除')
  } catch {
    ElMessage.error('删除失败，请稍后重试')
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <el-drawer v-model="visible" size="min(420px, 94vw)" direction="rtl" :with-header="false">
    <div class="panel">
      <header class="panel__head">
        <div class="panel__title">
          <h2>消息中心</h2>
          <p class="panel__note">共 {{ total }} 条，未读 {{ unreadCount }} 条</p>
        </div>
        <div class="panel__actions">
          <button class="btn" type="button" :disabled="unreadCount === 0" @click="markAllAsRead">
            <AppIcon name="check" size="14" />
            全部已读
          </button>
          <button class="btn btn--icon" type="button" aria-label="关闭消息中心" @click="visible = false">
            <AppIcon name="close" size="14" />
          </button>
        </div>
      </header>

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

      <div class="panel__body">
        <!-- 加载 -->
        <div v-if="loading" class="list" aria-busy="true">
          <div v-for="n in 5" :key="n" class="msg">
            <div class="msg__head">
              <span class="ghost ghost--pill skeleton" />
              <span class="ghost ghost--time skeleton" />
            </div>
            <span class="ghost ghost--line skeleton" />
          </div>
        </div>

        <!-- 错误 -->
        <EmptyState v-else-if="error" title="消息没能加载出来" :note="error">
          <button class="btn" type="button" @click="load">
            <AppIcon name="refresh" size="14" />
            重新加载
          </button>
        </EmptyState>

        <!-- 空 -->
        <EmptyState v-else-if="!filtered.length" :title="emptyTitle" :note="emptyNote" />

        <!-- 列表 -->
        <ol v-else class="list">
          <li
            v-for="msg in filtered"
            :key="msg.noticeId"
            class="msg"
            :class="{ 'is-unread': Number(msg.isRead) === 0 }"
          >
            <div class="msg__head">
              <span class="msg__tags">
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
    </div>
  </el-drawer>
</template>

<style scoped>
.panel {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
}

.panel__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-3);
  padding-bottom: var(--space-3);
  border-bottom: var(--hairline);
}

.panel__title h2 {
  font-size: var(--text-md);
  font-weight: 600;
}

.panel__note {
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.panel__actions {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-shrink: 0;
}

.panel__body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  margin-top: var(--space-3);
}

/* --- 筛选 ---------------------------------------------------------------- */

.filters {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  margin-top: var(--space-3);
}

.filters__item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px 10px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-xs);
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

/* --- 列表 ---------------------------------------------------------------- */

.list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.msg {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3) 2px;
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

.msg__tags {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.msg__time {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.msg__body {
  font-size: var(--text-sm);
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

.foot-note {
  padding-top: var(--space-3);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 控件与骨架 ---------------------------------------------------------- */

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 30px;
  padding-inline: 10px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--ink-1);
  cursor: pointer;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
  background: var(--paper-1);
}

.btn:disabled {
  border-color: var(--line-1);
  color: var(--ink-4);
  cursor: not-allowed;
}

.btn--icon {
  width: 30px;
  padding-inline: 0;
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
  width: 92%;
}
</style>
