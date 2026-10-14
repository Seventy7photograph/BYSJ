<script setup lang="ts">
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'

/**
 * 社区订阅。
 *
 * 原页面只有一句「该模块正在开发中」。后端确实没有面向买家的社区数据：
 * 公告（sys_notice / admin/notices）只对管理员开放，社区帖子、订阅关系都没有
 * 表结构。所以这里不编造帖子和订阅人数，只把这件事说明白：
 * 这个频道准备做什么、现在能用什么、公告在哪里看。
 */
const plans = [
  {
    title: '器材资讯与评测',
    note: '新机发布、固件更新、镜头实拍与对比，按分类整理。',
  },
  {
    title: '二手行情参考',
    note: '按型号汇总平台内在售二手器材的成色与价格区间。',
  },
  {
    title: '租赁档期与活动',
    note: '长租优惠、淡季价格与节假日档期提醒。',
  },
  {
    title: '订单与售后提醒',
    note: '支付、发货、归还与退款节点，通过站内消息推送。',
  },
]

const channels = [
  { label: '器材商城', note: '全新在售器材', to: '/shop', icon: 'goods' as const },
  { label: '二手交易', note: '单件库存，成色可查', to: '/second-hand', icon: 'sell' as const },
  { label: '租赁中心', note: '按天计价，含押金', to: '/rental', icon: 'luggage' as const },
]
</script>

<template>
  <div class="shell community">
    <SectionHead
      title="社区订阅"
      note="器材资讯、二手行情与活动预告的推送入口"
      size="lg"
    />

    <p class="lede">
      订阅频道正在建设。开放之后，你可以只订阅关心的分类与型号，资讯、行情变化和
      活动通知会通过站内消息送达，而不是在商品列表里翻找。
    </p>

    <div class="cols">
      <section class="plate">
        <div class="plate__head">
          <span class="plate__title">订阅内容</span>
        </div>
        <ul class="plans">
          <li v-for="plan in plans" :key="plan.title" class="plans__item">
            <span class="plans__title">{{ plan.title }}</span>
            <span class="plans__note">{{ plan.note }}</span>
          </li>
        </ul>
      </section>

      <section class="plate">
        <div class="plate__head">
          <span class="plate__title">平台公告</span>
        </div>
        <EmptyState
          title="暂无公开公告"
          note="公告由平台管理员在后台发布，目前只通过站内消息推送给对应用户。"
        >
          <RouterLink class="btn" to="/messages">
            <AppIcon name="message" size="14" />
            查看站内消息
          </RouterLink>
        </EmptyState>
      </section>
    </div>

    <section class="band">
      <SectionHead title="现在可以去的地方" note="订阅开放前，这三条交易线都是可用的" />
      <ul class="channels">
        <li v-for="channel in channels" :key="channel.to">
          <RouterLink class="channel" :to="channel.to">
            <AppIcon :name="channel.icon" size="18" />
            <span class="channel__text">
              <span class="channel__label">{{ channel.label }}</span>
              <span class="channel__note">{{ channel.note }}</span>
            </span>
            <AppIcon name="chevron-right" size="15" />
          </RouterLink>
        </li>
      </ul>
    </section>
  </div>
</template>

<style scoped>
.community {
  max-width: 1000px;
  padding-block: var(--space-6) var(--space-16);
}

.lede {
  margin-bottom: var(--space-6);
  font-size: var(--text-md);
  line-height: 1.7;
  color: var(--ink-2);
}

.cols {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-4);
}

.plans {
  margin: 0;
  padding: 0;
  list-style: none;
}

.plans__item {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: var(--space-3) var(--pad-surface);
  border-bottom: var(--hairline);
}

.plans__item:last-child {
  border-bottom: none;
}

.plans__title {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.plans__note {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.band {
  margin-top: var(--space-10);
}

.channels {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: var(--space-3);
  margin: 0;
  padding: 0;
  list-style: none;
}

.channel {
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

.channel:hover {
  text-decoration: none;
  border-color: var(--ink-4);
  background: var(--paper-1);
}

.channel__text {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.channel__label {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.channel__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

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
}

.btn:hover {
  text-decoration: none;
  border-color: var(--ink-3);
  background: var(--paper-2);
}

@media (max-width: 900px) {
  .cols {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 520px) {
  .community {
    padding-block: var(--space-4) var(--space-12);
  }
  .lede {
    font-size: var(--text-base);
  }
}
</style>
