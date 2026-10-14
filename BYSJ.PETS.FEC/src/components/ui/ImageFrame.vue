<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { IMAGE_PLACEHOLDER, resolveImageUrl } from '@/utils/format'

/**
 * 商品图框架。固定比例，图片未就绪时是骨架而不是塌陷的空白，
 * 加载失败时落到真实占位图，绝不留一个破图标。
 */
const props = withDefaults(
  defineProps<{
    src?: string | null
    alt?: string
    ratio?: string
    /** contain 用于器材图（不能裁掉镜头），cover 用于场景图。 */
    fit?: 'contain' | 'cover'
    eager?: boolean
  }>(),
  { src: null, alt: '', ratio: '4 / 3', fit: 'contain', eager: false },
)

const status = ref<'loading' | 'ready' | 'error'>('loading')
const url = computed(() => (status.value === 'error' ? IMAGE_PLACEHOLDER : resolveImageUrl(props.src)))

watch(
  () => props.src,
  () => {
    status.value = 'loading'
  },
)
</script>

<template>
  <div class="frame" :style="{ aspectRatio: ratio }">
    <div v-if="status === 'loading'" class="frame__skeleton skeleton" />
    <img
      class="frame__img"
      :class="{ 'frame__img--contain': fit === 'contain' }"
      :src="url"
      :alt="alt"
      :loading="eager ? 'eager' : 'lazy'"
      :decoding="eager ? 'sync' : 'async'"
      @load="status = 'ready'"
      @error="status = 'error'"
    />
  </div>
</template>

<style scoped>
.frame {
  position: relative;
  width: 100%;
  overflow: hidden;
  background: var(--paper-1);
}

.frame__skeleton {
  position: absolute;
  inset: 0;
}

.frame__img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.frame__img--contain {
  object-fit: contain;
  padding: var(--space-4);
}
</style>
