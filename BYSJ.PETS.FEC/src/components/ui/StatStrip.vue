<script setup lang="ts">
/**
 * 数据条 —— 控制台顶部的关键读数。
 * 刻意不是「大数字 + 小标签 + 迷你图」的模板：这里是把若干读数并排成
 * 一张可横向扫读的条带，每格有明确单位与对比项。
 */
export interface StatEntry {
  label: string
  value: string | number
  unit?: string
  note?: string
  tone?: 'default' | 'amber' | 'teal' | 'vermilion'
}

withDefaults(defineProps<{ entries: StatEntry[]; loading?: boolean }>(), { loading: false })
</script>

<template>
  <div class="stat-strip">
    <div v-for="entry in entries" :key="entry.label" class="stat-strip__cell">
      <span class="stat-strip__label">{{ entry.label }}</span>
      <span v-if="loading" class="stat-strip__value skeleton" />
      <span v-else class="stat-strip__value" :class="`stat-strip__value--${entry.tone || 'default'}`">
        {{ entry.value }}<span v-if="entry.unit" class="stat-strip__unit">{{ entry.unit }}</span>
      </span>
      <span v-if="entry.note" class="stat-strip__note">{{ entry.note }}</span>
    </div>
  </div>
</template>

<style scoped>
.stat-strip {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(0, 1fr);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.stat-strip__cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: var(--space-3) var(--space-4);
  border-right: var(--hairline);
  min-width: 0;
}

.stat-strip__cell:last-child {
  border-right: none;
}

.stat-strip__label {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.stat-strip__value {
  font-size: var(--text-lg);
  font-weight: 600;
  color: var(--ink-0);
  letter-spacing: -0.02em;
  font-variant-numeric: tabular-nums;
  line-height: 1.25;
  min-height: 1.25em;
}

.stat-strip__value--amber {
  color: var(--signal-amber-deep);
}

.stat-strip__value--teal {
  color: var(--signal-teal-deep);
}

.stat-strip__value--vermilion {
  color: var(--signal-vermilion-deep);
}

.stat-strip__unit {
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--ink-3);
  margin-left: 3px;
}

.stat-strip__note {
  font-size: var(--text-2xs);
  color: var(--ink-4);
}

@media (max-width: 900px) {
  .stat-strip {
    grid-auto-flow: row;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .stat-strip__cell:nth-child(2n) {
    border-right: none;
  }
  .stat-strip__cell {
    border-bottom: var(--hairline);
  }
}

@media (max-width: 520px) {
  .stat-strip {
    grid-template-columns: minmax(0, 1fr);
  }
  .stat-strip__cell {
    border-right: none;
  }
}
</style>
