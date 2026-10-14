<script setup lang="ts">
/**
 * 空状态。告诉用户这里为什么是空的、下一步能做什么，
 * 而不是放一张插画然后什么都不说。
 */
withDefaults(
  defineProps<{
    title: string
    note?: string
  }>(),
  { note: '' },
)
</script>

<template>
  <div class="empty">
    <svg class="empty__mark" viewBox="0 0 44 44" width="44" height="44" aria-hidden="true">
      <rect x="1" y="1" width="42" height="42" rx="6" fill="none" stroke="var(--line-2)" stroke-width="1.5" />
      <path d="M12 28.5 L19 21 L24.5 26.5 L30 20 L34 24" fill="none" stroke="var(--line-2)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
      <circle cx="16.5" cy="16" r="2.5" fill="none" stroke="var(--line-2)" stroke-width="1.5" />
    </svg>
    <p class="empty__title">{{ title }}</p>
    <p v-if="note" class="empty__note">{{ note }}</p>
    <div v-if="$slots.default" class="empty__action">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.empty__mark {
  margin-bottom: var(--space-1);
}

.empty__action {
  margin-top: var(--space-2);
}
</style>
