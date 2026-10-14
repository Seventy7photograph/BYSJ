<script setup lang="ts">
/**
 * 区块头。标题自己承担分量，其上不放任何引导词；
 * 右侧是这一区块唯一的动作入口。
 */
withDefaults(
  defineProps<{
    title: string
    note?: string
    size?: 'md' | 'lg'
  }>(),
  { note: '', size: 'md' },
)
</script>

<template>
  <header class="section-head">
    <div class="section-head__text">
      <h2 class="section-head__title" :class="`section-head__title--${size}`">{{ title }}</h2>
      <p v-if="note" class="section-head__note">{{ note }}</p>
    </div>
    <div v-if="$slots.action" class="section-head__action">
      <slot name="action" />
    </div>
  </header>
</template>

<style scoped>
.section-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-4);
  padding-bottom: var(--space-3);
  margin-bottom: var(--space-5);
  border-bottom: 1px solid var(--line-1);
}

.section-head__title {
  margin: 0;
}

.section-head__title--md {
  font-size: var(--text-md);
  font-weight: 600;
}

.section-head__title--lg {
  font-size: var(--text-lg);
  font-weight: 600;
}

.section-head__note {
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.section-head__action {
  flex-shrink: 0;
}

@media (max-width: 767px) {
  .section-head {
    align-items: flex-start;
    flex-direction: column;
    gap: var(--space-2);
  }
}
</style>
