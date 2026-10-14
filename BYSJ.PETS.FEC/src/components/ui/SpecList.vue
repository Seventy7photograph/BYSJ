<script setup lang="ts">
/**
 * 规格表 —— 这套系统的招牌组件。
 * 商品的身份是一条条对齐的数据，不是一段营销文案。
 * 空值直接省略整行，不留「暂无」噪音。
 */
export interface SpecEntry {
  key: string
  value: string | number | null | undefined
  mono?: boolean
}

defineProps<{
  entries: SpecEntry[]
  /** 两列排布，用于商品详情页的横向规格区。 */
  columns?: 1 | 2
}>()
</script>

<template>
  <dl class="spec" :class="{ 'spec--two': columns === 2 }">
    <template v-for="entry in entries" :key="entry.key">
      <div v-if="entry.value !== null && entry.value !== undefined && entry.value !== ''" class="spec__row">
        <dt class="spec__key">{{ entry.key }}</dt>
        <dd class="spec__val" :class="{ mono: entry.mono }">{{ entry.value }}</dd>
      </div>
    </template>
  </dl>
</template>

<style scoped>
.spec {
  margin: 0;
}

.spec__val {
  margin: 0;
}

.spec--two {
  grid-template-columns: repeat(2, minmax(0, 1fr));
  column-gap: var(--space-8);
}

.spec--two .spec__row {
  grid-template-columns: 88px minmax(0, 1fr);
}

@media (max-width: 767px) {
  .spec--two {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
