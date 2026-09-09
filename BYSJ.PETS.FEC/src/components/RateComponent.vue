<template>
  <div class="rate-component">
    <div class="stars" @click="handleClick" @mousemove="handleMouseMove" @mouseleave="handleMouseLeave">
      <div
        v-for="(star, index) in 5"
        :key="index"
        class="star"
        :class="{
          'filled': isFilled(index),
          'half-filled': isHalfFilled(index),
          'hover-filled': isHoverFilled(index),
          'hover-half-filled': isHoverHalfFilled(index)
        }"
      >
        <i class="star-icon"></i>
      </div>
    </div>
    <span v-if="showScore" class="score">{{ formatScore(localValue) }}</span>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  value: {
    type: Number,
    default: 0
  },
  showScore: {
    type: Boolean,
    default: false
  },
  readonly: {
    type: Boolean,
    default: false
  },
  clearable: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['update:value'])

const localValue = ref(props.value)
const hoverValue = ref(0)

// 监听props.value的变化，更新本地状态
watch(() => props.value, (newValue) => {
  localValue.value = newValue
})

const isFilled = (index) => {
  return index < Math.floor(localValue.value)
}

const isHalfFilled = (index) => {
  return index === Math.floor(localValue.value) && localValue.value % 1 !== 0
}

const isHoverFilled = (index) => {
  return index < hoverValue.value
}

const isHoverHalfFilled = (index) => {
  return index === Math.floor(hoverValue.value) && hoverValue.value % 1 !== 0
}

const formatScore = (score) => {
  return score.toFixed(1)
}

const handleClick = (event) => {
  if (props.readonly) return

  const starsContainer = event.currentTarget
  const rect = starsContainer.getBoundingClientRect()
  const clickX = event.clientX - rect.left
  const starWidth = rect.width / 5

  // 计算点击位置对应的评分
  let score = Math.ceil((clickX / starWidth) * 2) / 2
  score = Math.min(5, Math.max(0, score))

  // 如果支持清空，且当前评分大于0，则清空评分
  if (props.clearable && localValue.value > 0) {
    score = 0
  }

  localValue.value = score
  emit('update:value', score)
}

const handleMouseMove = (event) => {
  if (props.readonly) return

  const starsContainer = event.currentTarget
  const rect = starsContainer.getBoundingClientRect()
  const mouseX = event.clientX - rect.left
  const starWidth = rect.width / 5

  let score = Math.ceil((mouseX / starWidth) * 2) / 2
  score = Math.min(5, Math.max(0, score))

  hoverValue.value = score
}

const handleMouseLeave = () => {
  hoverValue.value = 0
}
</script>

<style scoped>
.rate-component {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.stars {
  display: flex;
  position: relative;
  cursor: pointer;
  width: 120px;
  height: 24px;
}

.star {
  flex: 1;
  position: relative;
  height: 100%;
  overflow: hidden;
}

.star-icon {
  display: block;
  width: 100%;
  height: 100%;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23e0e0e0'%3E%3Cpath d='M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z'/%3E%3C/svg%3E");
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.star.filled .star-icon,
.star.hover-filled .star-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23ffc107'%3E%3Cpath d='M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z'/%3E%3C/svg%3E");
}

.star.half-filled .star-icon,
.star.hover-half-filled .star-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23e0e0e0'%3E%3Cpath d='M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z'/%3E%3C/svg%3E");
}

.star.half-filled::after,
.star.hover-half-filled::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 50%;
  height: 100%;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23ffc107'%3E%3Cpath d='M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z'/%3E%3C/svg%3E");
  background-size: cover;
  background-repeat: no-repeat;
  background-position: left center;
  z-index: 1;
}

.score {
  font-size: 16px;
  font-weight: bold;
  color: #ffc107;
}

.stars[readonly] {
  cursor: default;
}
</style>
