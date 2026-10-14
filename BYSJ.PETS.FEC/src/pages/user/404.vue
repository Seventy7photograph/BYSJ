<script setup lang="ts">
import { useRoute } from 'vue-router'
import AppIcon from '@/components/ui/AppIcon.vue'

/**
 * 404。
 *
 * 这个路由挂在导航布局之外，所以页面自己带一条最简的顶栏，让访客随时能回到
 * 有内容的地方，而不是停在一句「你找的页面走丢了」上。
 * 原实现用 el-result 的默认插画，没有说明地址、也没有回到商城的入口。
 */
const route = useRoute()

const paths = [
  { label: '器材商城', note: '全新在售器材', to: '/shop' },
  { label: '二手交易', note: '单件库存，成色可查', to: '/second-hand' },
  { label: '租赁中心', note: '按天计价，含押金', to: '/rental' },
  { label: '消息中心', note: '订单与账号通知', to: '/messages' },
]
</script>

<template>
  <div class="notfound">
    <header class="bar">
      <div class="shell bar__inner">
        <RouterLink class="brand" to="/index">
          <img class="brand__mark" src="/相机.png" alt="" width="28" height="28" />
          <span class="brand__name">摄影器材交易系统</span>
        </RouterLink>
        <RouterLink class="brand brand--link" to="/shop">进入商城</RouterLink>
      </div>
    </header>

    <main class="shell body">
      <div class="plate panel">
        <span class="code mono">404</span>
        <h1 class="title">页面不存在</h1>
        <p class="note">
          地址 <span class="path mono">{{ route.fullPath }}</span> 没有对应的页面。
          链接可能已经失效，或者商品已经下架。
        </p>

        <div class="actions">
          <RouterLink class="btn btn--primary" to="/index">
            <AppIcon name="home" size="15" />
            回到首页
          </RouterLink>
          <RouterLink class="btn" to="/shop">
            去器材商城
            <AppIcon name="chevron-right" size="14" />
          </RouterLink>
        </div>
      </div>

      <ul class="paths">
        <li v-for="item in paths" :key="item.to">
          <RouterLink class="path-card" :to="item.to">
            <span class="path-card__text">
              <span class="path-card__label">{{ item.label }}</span>
              <span class="path-card__note">{{ item.note }}</span>
            </span>
            <AppIcon name="chevron-right" size="15" />
          </RouterLink>
        </li>
      </ul>
    </main>
  </div>
</template>

<style scoped>
.notfound {
  min-height: 100vh;
  background: var(--paper-1);
}

.bar {
  background: var(--paper-0);
  border-bottom: 1px solid var(--line-2);
}

.bar__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  height: 60px;
}

.brand {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  color: var(--ink-0);
}

.brand:hover {
  text-decoration: none;
}

.brand__mark {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.brand__name {
  font-size: var(--text-md);
  font-weight: 600;
  letter-spacing: -0.02em;
}

.brand--link {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.body {
  padding-block: var(--space-12) var(--space-16);
}

.panel {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-10) var(--space-8);
}

.code {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--ink-4);
  letter-spacing: -0.02em;
}

.title {
  font-size: var(--text-lg);
}

.note {
  max-width: 56ch;
  font-size: var(--text-base);
  line-height: 1.7;
  color: var(--ink-2);
}

.path {
  color: var(--ink-1);
  word-break: break-all;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.paths {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: var(--space-3);
  margin: var(--space-6) 0 0;
  padding: 0;
  list-style: none;
}

.path-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: 14px 16px;
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  color: var(--ink-1);
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease;
}

.path-card:hover {
  text-decoration: none;
  border-color: var(--ink-4);
  background: var(--paper-1);
}

.path-card__text {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.path-card__label {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.path-card__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding-inline: 16px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-base);
  font-weight: 500;
  color: var(--ink-1);
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease;
}

.btn:hover {
  text-decoration: none;
  border-color: var(--ink-3);
  background: var(--paper-1);
}

.btn--primary {
  background: var(--ink-0);
  border-color: var(--ink-0);
  color: var(--on-ink);
}

.btn--primary:hover {
  background: var(--ink-1);
  border-color: var(--ink-1);
  color: var(--on-ink);
}

@media (max-width: 900px) {
  .body {
    padding-block: var(--space-8) var(--space-16);
  }
  .panel {
    padding: var(--space-8) var(--space-6);
  }
}

@media (max-width: 520px) {
  .panel {
    padding: var(--space-6) var(--space-5);
  }
  .paths {
    grid-template-columns: minmax(0, 1fr);
  }
  .body {
    padding-block: var(--space-6) var(--space-12);
  }
}
</style>
