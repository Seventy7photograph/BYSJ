<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage } from 'element-plus'
import AppIcon from './AppIcon.vue'
import { ACCEPTED_IMAGE_TYPES, uploadFile, type BizType, type UploadedFile } from '@/api/files'
import { resolveImageUrl } from '@/utils/format'

/**
 * 图片上传控件（商品图、头像、店铺资质共用一套）。
 *
 * 重构前每个页面各写一份 el-upload，各自拼接口地址、各自的成功判断、
 * 各自的失败提示。这里收敛成一个受控组件：v-model 进出 UploadedFile[]，
 * 组件负责校验、上传、错误提示与预览，业务侧只关心最后的列表。
 */
const props = withDefaults(
  defineProps<{
    modelValue: UploadedFile[]
    bizType?: BizType
    max?: number
    /** 缩略图比例，商品图 4/3，资质照 16/10。 */
    ratio?: string
    hint?: string
    disabled?: boolean
  }>(),
  { bizType: 'product', max: 8, ratio: '4 / 3', hint: '', disabled: false },
)

const emit = defineEmits<{ 'update:modelValue': [UploadedFile[]] }>()

const inputRef = ref<HTMLInputElement | null>(null)
const busy = ref(false)
const dragOver = ref(false)

const reachedMax = computed(() => props.modelValue.length >= props.max)

function pick() {
  if (props.disabled || busy.value || reachedMax.value) return
  inputRef.value?.click()
}

async function ingest(files: FileList | null) {
  if (!files || files.length === 0) return
  const room = props.max - props.modelValue.length
  const chosen = Array.from(files).slice(0, room)
  if (chosen.length === 0) return

  busy.value = true
  const next = [...props.modelValue]
  let failed = 0
  for (const file of chosen) {
    try {
      next.push(await uploadFile(file, props.bizType))
    } catch (error) {
      failed += 1
      ElMessage.error(error instanceof Error ? error.message : '上传失败')
    }
  }
  busy.value = false
  if (next.length !== props.modelValue.length) emit('update:modelValue', next)
  if (failed === 0 && chosen.length > 0) ElMessage.success(`已上传 ${chosen.length} 张`)
}

function remove(index: number) {
  const next = [...props.modelValue]
  next.splice(index, 1)
  emit('update:modelValue', next)
}

function onDrop(event: DragEvent) {
  dragOver.value = false
  if (props.disabled) return
  void ingest(event.dataTransfer?.files ?? null)
}

function onInputChange(event: Event) {
  const target = event.target as HTMLInputElement
  void ingest(target.files)
  target.value = ''
}
</script>

<template>
  <div class="uploader">
    <ul v-if="modelValue.length" class="uploader__list">
      <li v-for="(item, index) in modelValue" :key="item.id ?? item.url" class="uploader__item">
        <div class="uploader__thumb" :style="{ aspectRatio: ratio }">
          <img :src="resolveImageUrl(item.url)" :alt="item.name || `图片 ${index + 1}`" />
          <span v-if="index === 0" class="uploader__flag">主图</span>
        </div>
        <button
          class="uploader__remove"
          type="button"
          :aria-label="`移除第 ${index + 1} 张图片`"
          :disabled="disabled"
          @click="remove(index)"
        >
          <AppIcon name="close" size="12" />
        </button>
      </li>
    </ul>

    <button
      v-if="!reachedMax"
      class="uploader__drop"
      :class="{ 'is-over': dragOver }"
      type="button"
      :disabled="disabled || busy"
      @click="pick"
      @dragover.prevent="dragOver = true"
      @dragleave.prevent="dragOver = false"
      @drop.prevent="onDrop"
    >
      <AppIcon :name="busy ? 'loading' : 'upload'" size="18" />
      <span class="uploader__label">{{ busy ? '上传中…' : '选择或拖入图片' }}</span>
      <span class="uploader__meta">
        {{ hint || `JPG / PNG / WebP，单张不超过 10MB，最多 ${max} 张` }}
      </span>
      <span v-if="modelValue.length" class="uploader__count">
        已上传 {{ modelValue.length }} / {{ max }}
      </span>
    </button>

    <input
      ref="inputRef"
      class="sr-only"
      type="file"
      :accept="ACCEPTED_IMAGE_TYPES"
      multiple
      @change="onInputChange"
    />
  </div>
</template>

<style scoped>
.uploader {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.uploader__list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(118px, 1fr));
  gap: var(--space-3);
  margin: 0;
  padding: 0;
  list-style: none;
}

.uploader__item {
  position: relative;
}

.uploader__thumb {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: var(--paper-1);
  border: var(--edge);
  border-radius: var(--radius-sm);
}

.uploader__thumb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  padding: 6px;
}

.uploader__flag {
  position: absolute;
  left: 4px;
  bottom: 4px;
  padding: 1px 5px;
  border-radius: var(--radius-xs);
  background: var(--ink-0);
  color: #fff;
  font-size: 10px;
  font-weight: 600;
  line-height: 1.5;
}

.uploader__remove {
  position: absolute;
  top: -6px;
  right: -6px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-pill);
  background: var(--paper-0);
  color: var(--ink-2);
  cursor: pointer;
}

.uploader__remove:hover {
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion);
}

.uploader__drop {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: var(--space-5) var(--space-4);
  border: 1px dashed var(--line-2);
  border-radius: var(--radius-sm);
  background: var(--paper-1);
  color: var(--ink-3);
  cursor: pointer;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.uploader__drop:hover:not(:disabled),
.uploader__drop.is-over {
  border-color: var(--ink-0);
  background: var(--paper-0);
  color: var(--ink-0);
}

.uploader__drop:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.uploader__label {
  font-size: var(--text-base);
  font-weight: 500;
}

.uploader__meta,
.uploader__count {
  font-size: var(--text-2xs);
  color: var(--ink-4);
}
</style>
