<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import { useUserStore } from '@/stores/user'
import { useMessageStore } from '@/stores/message'

/**
 * 前台右侧浮动工具条。
 *
 * 原来它在页面里又渲染了一个自带的 MessageDrawer，和路由 /messages 是两套东西，
 * 未读数靠子组件回调反填。这里统一走 message store，抽屉交给 /messages 承担。
 */
const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const messageStore = useMessageStore()

const showTop = ref(false)
const unread = computed(() => messageStore.unreadCount)

/** 商家与管理端有自己的信息架构，浮动条只服务前台。 */
const enabled = computed(() => !/^\/(merchant|admin|super-admin)-dashboard/.test(route.path))

function onScroll() {
  showTop.value = window.scrollY > 480
}

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  void messageStore.loadMessages()
})

onUnmounted(() => window.removeEventListener('scroll', onScroll))

function requireLogin(path: string) {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  router.push(path)
}

function scrollTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<template>
  <div v-if="enabled" class="rail" role="complementary" aria-label="快捷入口">
    <button class="rail__btn" type="button" title="购物车" @click="requireLogin('/cart')">
      <AppIcon name="cart" size="17" />
      <span class="rail__label">购物车</span>
    </button>
    <button class="rail__btn" type="button" title="我的订单" @click="requireLogin('/orders')">
      <AppIcon name="order" size="17" />
      <span class="rail__label">订单</span>
    </button>
    <button class="rail__btn" type="button" title="我的收藏" @click="requireLogin('/favorites')">
      <AppIcon name="star" size="17" />
      <span class="rail__label">收藏</span>
    </button>
    <button class="rail__btn" type="button" title="消息中心" @click="requireLogin('/messages')">
      <AppIcon name="message" size="17" />
      <span class="rail__label">消息</span>
      <span v-if="unread > 0" class="rail__badge">{{ unread > 99 ? '99+' : unread }}</span>
    </button>

    <button
      class="rail__btn rail__btn--top"
      :class="{ 'is-shown': showTop }"
      type="button"
      title="回到顶部"
      @click="scrollTop"
    >
      <AppIcon name="chevron-up" size="17" />
      <span class="rail__label">顶部</span>
    </button>
  </div>
</template>

<style scoped>
.rail {
  position: fixed;
  right: 16px;
  bottom: 88px;
  z-index: 90;
  display: flex;
  flex-direction: column;
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.rail__btn {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  width: 52px;
  padding: 10px 0;
  border: none;
  border-bottom: var(--hairline);
  background: transparent;
  color: var(--ink-3);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.rail__btn:last-child {
  border-bottom: none;
}

.rail__btn:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

.rail__label {
  font-size: var(--text-2xs);
  line-height: 1;
}

.rail__badge {
  position: absolute;
  top: 6px;
  right: 8px;
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

.rail__btn--top {
  display: none;
}

.rail__btn--top.is-shown {
  display: flex;
}

@media (max-width: 900px) {
  .rail {
    display: none;
  }
}
</style>
