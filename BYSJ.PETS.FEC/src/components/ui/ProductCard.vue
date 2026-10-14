<script setup lang="ts">
import { computed } from 'vue'
import ImageFrame from './ImageFrame.vue'
import PriceTag from './PriceTag.vue'
import StatePill from './StatePill.vue'
import { conditionLabel, labelOf, PRODUCT_TYPE } from '@/constants/domain'
import { stockNote } from '@/utils/format'

/**
 * 商品列表格。这是一张「接触印样」里的单格：
 * 图占满上部，规格行在下面，价格是唯一的暖色。
 * 悬停不抬升、不加阴影，只让底色退一层并把规格行显影出来。
 */
const props = withDefaults(
  defineProps<{
    /** 字段名对齐后端 GoodsVO。 */
    productId: number | string
    name?: string | null
    brandName?: string | null
    categoryName?: string | null
    price?: number | string | null
    imageUrl?: string | null
    productType?: number | null
    condition?: number | null
    stockTip?: string | null
    stock?: number | null
    minStock?: number | null
    deposit?: number | string | null
    minRentalDays?: number | null
    sellerName?: string | null
    to?: string
    eager?: boolean
  }>(),
  {
    name: null,
    brandName: null,
    categoryName: null,
    price: null,
    imageUrl: null,
    productType: 1,
    condition: null,
    stockTip: null,
    stock: null,
    minStock: null,
    deposit: null,
    minRentalDays: null,
    sellerName: null,
    to: undefined,
    eager: false,
  },
)

const type = computed(() => labelOf(PRODUCT_TYPE, props.productType))
const grade = computed(() => (props.productType === 1 ? null : conditionLabel(props.condition)))
const stock = computed(() => stockNote(props.stock, props.minStock))

/** 规格行：成色 / 分类 / 卖家，空的一项就跳过，不占位。 */
const specLine = computed(() =>
  [grade.value, props.categoryName, props.sellerName].filter(Boolean).join(' · '),
)

const link = computed(() => {
  if (props.to) return props.to
  return props.productType === 3 ? `/rental/detail/${props.productId}` : `/product/${props.productId}`
})

const isRental = computed(() => props.productType === 3)
</script>

<template>
  <RouterLink class="card" :to="link">
    <div class="card__media">
      <ImageFrame :src="imageUrl" :alt="name || '商品图'" :eager="eager" fit="contain" ratio="4 / 3" />
      <span class="card__type"><StatePill :label="type.label" :tone="type.tone" /></span>
    </div>

    <div class="card__body">
      <h3 class="card__name">{{ name || '未命名商品' }}</h3>
      <p class="card__spec">{{ specLine || '—' }}</p>

      <div class="card__foot">
        <PriceTag :price="price" :unit="isRental ? '/天' : null" size="sm" :show-original="false" />
        <span class="card__stock" :class="{ 'is-low': stock.low, 'is-out': stock.out }">
          {{ stockTip || stock.text }}
        </span>
      </div>
    </div>
  </RouterLink>
</template>

<style scoped>
.card {
  display: flex;
  flex-direction: column;
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  overflow: hidden;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease;
}

.card:hover {
  text-decoration: none;
  border-color: var(--ink-4);
  background: var(--paper-1);
}

.card:focus-visible {
  box-shadow: var(--focus-ring);
}

.card__media {
  position: relative;
  background: var(--paper-0);
  border-bottom: var(--hairline);
}

.card__type {
  position: absolute;
  top: var(--space-2);
  left: var(--space-2);
}

.card__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4) var(--space-4);
  flex: 1;
}

.card__name {
  font-size: var(--text-base);
  font-weight: 600;
  line-height: 1.4;
  color: var(--ink-0);
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: calc(1.4em * 2);
}

/* 规格行：悬停时从失焦到显影，是这套系统唯一的「揭示」动作。 */
.card__spec {
  margin: 0;
  font-size: var(--text-xs);
  color: var(--ink-3);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  filter: blur(0.35px);
  opacity: 0.72;
  transition:
    filter var(--dur-state) ease,
    opacity var(--dur-state) ease;
}

.card:hover .card__spec {
  filter: none;
  opacity: 1;
  color: var(--ink-2);
}

.card__foot {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-2);
  margin-top: auto;
  padding-top: var(--space-1);
}

.card__stock {
  font-size: var(--text-2xs);
  color: var(--ink-3);
  white-space: nowrap;
}

.card__stock.is-low {
  color: var(--signal-amber-deep);
  font-weight: 600;
}

.card__stock.is-out {
  color: var(--signal-vermilion-deep);
  font-weight: 600;
}

@media (max-width: 767px) {
  .card__name {
    font-size: var(--text-sm);
  }
  .card__body {
    padding: var(--space-2) var(--space-3) var(--space-3);
  }
}
</style>
