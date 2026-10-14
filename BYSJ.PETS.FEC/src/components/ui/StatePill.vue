<script setup lang="ts">
import type { Tone } from '@/constants/domain'

/**
 * 状态徽标。颜色只是辅助：文案始终在场，状态绝不靠颜色单独表达。
 */
withDefaults(
  defineProps<{
    label: string
    tone?: Tone
  }>(),
  { tone: 'neutral' },
)
</script>

<template>
  <span class="pill" :class="`pill--${tone}`">{{ label }}</span>
</template>
