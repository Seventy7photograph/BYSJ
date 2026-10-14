<script setup lang="ts">
/**
 * 页脚。
 *
 * 原页脚里挂了一批并不存在的路由（/support/app、/support/help、
 * /support/swap、/support/feedback、/rent），以及一组写死的联系方式与备案号
 * —— 那些信息没有真实来源，留在页面上就是对外承诺。这里只保留真实可达的
 * 链接和平台自己的介绍。
 */
const GROUPS = [
  {
    title: '交易',
    links: [
      { label: '器材商城', to: '/shop' },
      { label: '二手交易', to: '/second-hand' },
      { label: '租赁中心', to: '/rental' },
      { label: '社区订阅', to: '/community' },
    ],
  },
  {
    title: '我的',
    links: [
      { label: '我的订单', to: '/orders' },
      { label: '购物车', to: '/cart' },
      { label: '我的收藏', to: '/favorites' },
      { label: '收货地址', to: '/address' },
    ],
  },
  {
    title: '账户',
    links: [
      { label: '个人资料', to: '/profile' },
      { label: '消息中心', to: '/messages' },
      { label: '登录', to: '/login' },
      { label: '注册', to: '/register' },
    ],
  },
] as const

const year = new Date().getFullYear()
</script>

<template>
  <footer class="foot">
    <div class="shell foot__inner">
      <div class="foot__brand">
        <div class="foot__lockup">
          <img src="/相机.png" alt="" width="26" height="26" />
          <span>摄影器材交易系统</span>
        </div>
        <p class="foot__desc">
          一个专注摄影器材的交易平台，把全新零售、二手流转与器材租赁放进同一套库存与订单流转里。
        </p>
      </div>

      <nav v-for="group in GROUPS" :key="group.title" class="foot__group" :aria-label="group.title">
        <h2 class="foot__group-title">{{ group.title }}</h2>
        <ul class="foot__list">
          <li v-for="link in group.links" :key="link.to">
            <RouterLink :to="link.to">{{ link.label }}</RouterLink>
          </li>
        </ul>
      </nav>
    </div>

    <div class="shell foot__base">
      <span>© {{ year }} 摄影器材交易系统</span>
      <span class="foot__meta">课程设计与实现作品，非商业运营</span>
    </div>
  </footer>
</template>

<style scoped>
.foot {
  margin-top: var(--space-16);
  background: var(--paper-0);
  border-top: 1px solid var(--line-2);
}

.foot__inner {
  display: grid;
  grid-template-columns: minmax(0, 1.6fr) repeat(3, minmax(0, 1fr));
  gap: var(--space-8);
  padding-block: var(--space-10) var(--space-8);
}

.foot__lockup {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
  letter-spacing: -0.02em;
}

.foot__desc {
  margin-top: var(--space-3);
  max-width: 42ch;
  font-size: var(--text-sm);
  color: var(--ink-3);
  line-height: 1.7;
}

.foot__group-title {
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--ink-1);
  letter-spacing: 0;
}

.foot__list {
  margin: var(--space-3) 0 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.foot__list a {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.foot__list a:hover {
  color: var(--ink-0);
}

.foot__base {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  padding-block: var(--space-4);
  border-top: var(--hairline);
  font-size: var(--text-xs);
  color: var(--ink-4);
}

@media (max-width: 900px) {
  .foot__inner {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-6);
    padding-block: var(--space-8) var(--space-6);
  }
  .foot__brand {
    grid-column: 1 / -1;
  }
}

@media (max-width: 520px) {
  .foot__inner {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
