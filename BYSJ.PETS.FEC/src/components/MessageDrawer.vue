<template>
  <el-drawer
    v-model="drawerVisible"
    size="25%"
    direction="rtl"
  >
    <!-- 自定义标题插槽 -->
    <template #title>
      <div class="message-header-container">
        <div class="message-title-section">
          <div style="font-size: 20px; font-weight: bold; color: #1989fa; display: inline-block; vertical-align: middle;">消息中心</div>
          <img
            src="/public/消息.png"
            alt="message"
            style="margin-right: 5px;
                   width: 20px;
                   height: 20px;
                   object-fit: contain;
                   vertical-align: middle;"
          >
        </div>
        <div class="header-actions">
          <el-button
            type="primary"
            size="small"
            @click="markAllAsRead"
            :disabled="unreadCount === 0"
          >
            一键已读
          </el-button>
        </div>
      </div>
    </template>

    <!-- 消息内容区域 -->
    <div class="messages-content">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="系统消息" name="system">
          <div v-if="messageStore.loading" class="loading-messages">
            <el-skeleton :rows="5" animated />
          </div>
          <div v-else-if="systemMessages.length === 0" class="empty-messages">
            <el-empty description="暂无系统消息" :image-size="100" />
          </div>
          <div v-else class="message-list">
            <div
              v-for="msg in systemMessages"
              :key="msg.noticeId"
              class="message-item-container"
            >
              <!-- 删除按钮区域（在消息卡片下方） -->
              <div
                class="delete-area"
                :class="{ 'delete-visible': msg.isSwiping && (msg.swipeDistance??0) < -60 }"
              >
                <div class="delete-button" @click="handleDelete(msg)">
                  删除
                </div>
              </div>

              <!-- 消息卡片 -->
              <div
                class="message-item"
                :class="{ 'unread': msg.isRead === 0, 'swiping': msg.isSwiping }"
                :style="{ transform: `translateX(${msg.swipeDistance || 0}px)` }"
                @click="markAsRead(msg)"
                @touchstart="handleStart($event, msg)"
                @touchmove="handleMove($event, msg)"
                @touchend="handleEnd($event, msg)"
                @touchcancel="handleEnd($event, msg)"
                @mousedown="handleStart($event, msg)"
                @mouseup="handleEnd($event, msg)"
                @mouseleave="handleEnd($event, msg)"
              >
                <div class="message-header">
                  <div class="message-title">{{ getMessageTitle(msg) }}</div>
                  <div class="message-badge" v-if="msg.isRead === 0">
                    <span class="unread-dot"></span>
                  </div>
                </div>
                <div class="message-content">{{ msg.content }}</div>
                <div class="message-time">{{ formatTime(msg.createTime) }}</div>
              </div>
            </div>
          </div>
        </el-tab-pane>
        <el-tab-pane label="订单消息" name="order">
          <div v-if="messageStore.loading" class="loading-messages">
            <el-skeleton :rows="5" animated />
          </div>
          <div v-else-if="orderMessages.length === 0" class="empty-messages">
            <el-empty description="暂无订单消息" :image-size="100" />
          </div>
          <div v-else class="message-list">
            <div
              v-for="msg in orderMessages"
              :key="msg.noticeId"
              class="message-item-container"
            >
              <!-- 删除按钮区域（在消息卡片下方） -->
              <div
                class="delete-area"
                :class="{ 'delete-visible': msg.isSwiping && (msg.swipeDistance??0) < -60 }"
              >
                <div class="delete-button" @click="handleDelete(msg)">
                  删除
                </div>
              </div>

              <!-- 消息卡片 -->
              <div
                class="message-item"
                :class="{ 'unread': msg.isRead === 0, 'swiping': msg.isSwiping }"
                :style="{ transform: `translateX(${msg.swipeDistance || 0}px)` }"
                @click="markAsRead(msg)"
                @touchstart="handleStart($event, msg)"
                @touchmove="handleMove($event, msg)"
                @touchend="handleEnd($event, msg)"
                @touchcancel="handleEnd($event, msg)"
                @mousedown="handleStart($event, msg)"
                @mouseup="handleEnd($event, msg)"
                @mouseleave="handleEnd($event, msg)"
              >
                <div class="message-header">
                  <div class="message-title">{{ getMessageTitle(msg) }}</div>
                  <div class="message-badge" v-if="msg.isRead === 0">
                    <span class="unread-dot"></span>
                  </div>
                </div>
                <div class="message-content">{{ msg.content }}</div>
                <div class="message-time">{{ formatTime(msg.createTime) }}</div>
              </div>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>
  </el-drawer>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { useMessageStore } from '@/stores/message'

const userStore = useUserStore()
const messageStore = useMessageStore()

// 定义props
interface Props {
  visible: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:visible': [value: boolean]
  'update:unread-count': [value: number]
}>()



// 计算属性来控制抽屉显示
const drawerVisible = computed({
  get: () => props.visible,
  set: (value: boolean) => {
    emit('update:visible', value)
    // 当抽屉打开时，加载消息列表
    if (value) {
      messageStore.loadMessages()
    }
  }
})

// 消息中心相关状态
const activeTab = ref('system')

// 扩展MessageItem接口，添加滑动相关属性
interface SwipeMessageItem {
  noticeId: number
  userId: number
  content: string
  noticeType: number
  createTime: string
  isRead: number
  expireTime?: string
  noticeStatus: number
  title?: string
  swipeDistance?: number
  touchStartX?: number
  isSwiping?: boolean
  swipeStartTime?: number
}

// 系统消息
const systemMessages = computed(() => {
  return messageStore.systemMessages as SwipeMessageItem[]
})

// 订单消息
const orderMessages = computed(() => {
  return messageStore.orderMessages as SwipeMessageItem[]
})

// 计算当前激活标签的消息列表
const currentMessages = computed(() => {
  return activeTab.value === 'system' ? systemMessages.value : orderMessages.value
})

// 计算未读消息数量
const unreadCount = computed(() => {
  // 向父组件发送未读消息数量更新
  emit('update:unread-count', messageStore.unreadCount)
  return messageStore.unreadCount
})

// 标记单条消息为已读
const markAsRead = async (message: SwipeMessageItem) => {
  if (message.isRead === 0 && !message.isSwiping) {
    try {
      await messageStore.markAsRead(message.noticeId)
      ElMessage.success('标记为已读')
    } catch (error) {
      console.error('标记消息为已读失败:', error)
      ElMessage.error('标记消息为已读失败')
    }
  }
}

// 一键标记所有消息为已读
const markAllAsRead = async () => {
  try {
    await messageStore.markAllAsRead()
    ElMessage.success('所有消息已标记为已读')
  } catch (error) {
    console.error('标记所有消息为已读失败:', error)
    ElMessage.error('标记所有消息为已读失败')
  }
}

// 删除消息
const handleDelete = async (message: SwipeMessageItem) => {
  try {
    await messageStore.deleteMessageById(message.noticeId)
    ElMessage.success('消息已删除')
  } catch (error) {
    console.error('删除消息失败:', error)
    ElMessage.error('删除消息失败')
    // 点击取消时，重置滑动状态回到初始位置
    message.swipeDistance = 0
    message.isSwiping = false
    message.touchStartX = undefined
  }
}
// 获取消息标题
const getMessageTitle = (msg: SwipeMessageItem): string => {
  if (msg.noticeType == 0) {
    return '系统通知'
  } else if (msg.noticeType == 1) {
    return '订单通知'
  } else if (msg.noticeType == 2) {
    return '退款通知'
  } else if (msg.noticeType == 3) {
    return '账号通知'
  } else if (msg.noticeType == 4) {
    return '评价通知'
  } else {
    return '消息通知'
  }
}

// 格式化时间
const formatTime = (timeStr: string): string => {
  const date = new Date(timeStr)
  const now = new Date()
  const diff = now.getTime() - date.getTime()

  const minutes = Math.floor(diff / (1000 * 60))
  const hours = Math.floor(diff / (1000 * 60 * 60))
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (minutes < 60) {
    return `${minutes}分钟前`
  } else if (hours < 24) {
    return `${hours}小时前`
  } else if (days < 30) {
    return `${days}天前`
  } else {
    return date.toLocaleDateString()
  }
}

// 全局监听鼠标移动（用于鼠标滑动）
let currentMessage: SwipeMessageItem | null = null
const handleGlobalMouseMove = (event: MouseEvent) => {
  if (!currentMessage || currentMessage.touchStartX === undefined) return
  // 计算鼠标滑动距离
  const currentX = event.clientX
  currentMessage.swipeDistance = currentX - currentMessage.touchStartX
  // 限制向左滑动最大距离（完全显示删除按钮）
  if (currentMessage.swipeDistance < -80) {
    currentMessage.swipeDistance = -80
  }
}

// 开始滑动（兼容触摸/鼠标）
const handleStart = (event: TouchEvent | MouseEvent, message: SwipeMessageItem) => {
  // 阻止事件冒泡和默认行为（避免触发点击事件）
  event.preventDefault()
  event.stopPropagation()

  // 非空守卫
  if (!message) return

  // 记录当前操作的消息
  currentMessage = message
  message.isSwiping = true
  message.swipeStartTime = Date.now()

  // 区分触摸/鼠标事件，获取起始X坐标
  if ('touches' in event) { // 触摸事件
    if (event.touches.length === 0) return
    const touch = event.touches[0]!
    message.touchStartX = touch.clientX
  } else { // 鼠标事件
    message.touchStartX = event.clientX
    // 全局监听鼠标移动（因为鼠标可能移出元素）
    document.addEventListener('mousemove', handleGlobalMouseMove)
  }
  message.swipeDistance = 0
}

// 滑动中（仅触摸事件需要，鼠标事件用全局监听）
const handleMove = (event: TouchEvent | MouseEvent, message: SwipeMessageItem) => {
  // 阻止默认行为
  event.preventDefault()
  event.stopPropagation()

  // 非空守卫
  if (!message || message.touchStartX === undefined) return

  // 仅处理触摸事件的滑动（鼠标滑动在全局监听）
  if ('touches' in event) {
    if (event.touches.length === 0) return
    const touch = event.touches[0]!
    const currentX = touch.clientX
    message.swipeDistance = currentX - message.touchStartX
    // 限制向左滑动最大距离（完全显示删除按钮）
    if (message.swipeDistance < -80) {
      message.swipeDistance = -80
    }
  }
}

// 结束滑动（兼容触摸/鼠标）
const handleEnd = (event: TouchEvent | MouseEvent, message: SwipeMessageItem) => {
  // 阻止事件冒泡和默认行为
  event.preventDefault()
  event.stopPropagation()

  // 非空守卫
  if (!message || message.swipeDistance === undefined || message.touchStartX === undefined) {
    currentMessage = null
    document.removeEventListener('mousemove', handleGlobalMouseMove)
    return
  }

  // 计算滑动速度（避免过快滑动直接触发删除）
  const swipeDuration = Date.now() - (message.swipeStartTime || Date.now())
  const swipeSpeed = Math.abs(message.swipeDistance) / Math.max(swipeDuration, 1)

  // 如果滑动距离超过阈值且滑动速度适中，显示删除按钮
  if (message.swipeDistance < -60 && swipeSpeed < 2) {
    // 保持滑动状态，显示删除按钮
    message.isSwiping = true
  } else {
    // 重置滑动状态
    message.swipeDistance = 0
    message.isSwiping = false
  }

  message.touchStartX = undefined
  currentMessage = null

  // 移除全局鼠标移动监听
  document.removeEventListener('mousemove', handleGlobalMouseMove)
}

// 组件挂载时，加载消息列表
onMounted(() => {
  // 初始化时，只有登录后才加载消息列表
  if (userStore.isLoggedIn) {
    messageStore.loadMessages()
  }
})

// 组件卸载时清理事件监听
onUnmounted(() => {
  document.removeEventListener('mousemove', handleGlobalMouseMove)
})
</script>

<style scoped>
/* 消息中心样式 */
.messages-content {
  padding: 0 10px;
  max-height: calc(100vh - 120px);
  overflow-y: auto;
}

.loading-messages {
  padding: 20px 0;
}

.empty-messages {
  text-align: center;
  padding: 30px 0;
}

.message-list {
  margin-top: 15px;
}

/* 消息项容器 */
.message-item-container {
  position: relative;
  margin-bottom: 12px;
}

/* 删除区域 */
.delete-area {
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  width: 0;
  background-color: #f56c6c;
  border-radius: 8px;
  transition: width 0.3s ease;
  overflow: hidden;
  z-index: 1;
}

.delete-area.delete-visible {
  width: 80px;
}

.delete-button {
  width: 80px;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 14px;
  font-weight: bold;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.delete-button:hover {
  background-color: #e64c4c;
}

/* 消息卡片 */
.message-item {
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 12px;
  background-color: #f9f9f9;
  cursor: pointer;
  transition: transform 0.3s ease, background-color 0.3s ease;
  position: relative;
  z-index: 2;
  user-select: none;
}

.message-item:hover {
  background-color: #f0f7ff;
  border-color: #409EFF;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.1);
}

.message-item.swiping {
  transition: transform 0.1s ease; /* 滑动时使用更快的过渡 */
}

.message-item.unread {
  background-color: #fff;
  border-left: 4px solid #409EFF;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.message-title {
  font-weight: bold;
  font-size: 14px;
  color: #333;
  flex: 1;
  margin-right: 8px;
}

.message-badge {
  position: relative;
}

.unread-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  background-color: #f56c6c;
  border-radius: 50%;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.2);
    opacity: 0.7;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.message-content {
  color: #666;
  margin-bottom: 6px;
  font-size: 13px;
  line-height: 1.4;
}

.message-time {
  color: #999;
  font-size: 11px;
  text-align: right;
}

.message-header-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding-right: 20px;
}

.message-title-section {
  display: flex;
  align-items: center;
}

.header-actions {
  position: relative;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .message-header-container {
    flex-direction: column;
    align-items: flex-start;
    padding-right: 0;
  }

  .header-actions {
    margin-top: 10px;
  }

  .message-item {
    padding: 10px;
  }

  .message-title {
    font-size: 13px;
  }

  .message-content {
    font-size: 12px;
  }
}
</style>
