<script setup lang="ts">
import { onMounted } from 'vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

onMounted(async () => {
  // 应用启动时检查登录状态
  await userStore.checkLoginStatus()
})
</script>

<template>
  <router-view></router-view>
</template>

<style scoped>
</style>
