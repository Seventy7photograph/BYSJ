<script setup lang="ts">
import { computed } from 'vue'
import { discountLabel, formatAmount, formatMoney } from '@/utils/format'

/**
 * 价格。金额是这一行的主角，划线的原价与折扣是注脚。
 * 租赁商品传入 unit 说明计价单位（如「/天」）。
 */
const props = withDefaults(
  defineProps<{
    price: number | string | null | undefined
    originalPrice?: number | string | null
    unit?: string | null
    size?: 'sm' | 'md' | 'lg'
    showOriginal?: boolean
  }>(),
  { originalPrice: null, unit: null, size: 'md', showOriginal: true },
)

const amount = computed(() => formatAmount(props.price))
const original = computed(() => formatMoney(props.originalPrice))
const off = computed(() => discountLabel(Number(props.price), Number(props.originalPrice)))
const hasOriginal = computed(
  () =>
    props.showOriginal &&
    props.originalPrice !== null &&
    props.originalPrice !== undefined &&
    Number(props.originalPrice) > Number(props.price),
)
</script>

<template>
  <div class="price" :class="`price--${size}`">
    <span class="price__now money">
      <span class="money__sign">¥</span>{{ amount }}
    </span>
    <span v-if="unit" class="price__unit">{{ unit }}</span>
    <template v-if="hasOriginal">
      <span class="price__was money--chrome">{{ original }}</span>
      <span v-if="off" class="price__off">{{ off }}</span>
    </template>
  </div>
</template>

<style scoped>
.price {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 6px;
  min-width: 0;
}

.price__now {
  font-size: var(--text-md);
  line-height: 1.1;
  font-weight: 600;
}

.price--sm .price__now {
  font-size: var(--text-base);
}

.price--lg .price__now {
  font-size: var(--text-xl);
  letter-spacing: -0.025em;
}

.price__unit {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.price__off {
  padding: 1px 5px;
  border-radius: var(--radius-xs);
  background: var(--signal-vermilion-wash);
  color: var(--signal-vermilion-deep);
  font-size: var(--text-2xs);
  font-weight: 600;
  line-height: 1.5;
}
</style>
