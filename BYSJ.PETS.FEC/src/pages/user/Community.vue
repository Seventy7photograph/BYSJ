<template>
  <div class="community-page">
    <div class="under-development">
      <h1>该模块正在开发中</h1>
      <p>我们正在努力开发社区订阅功能，敬请期待！</p>
    </div>
  </div>
</template>

<script setup lang="ts">
// 社区订阅页面 - 开发中
</script>

<style scoped>
.community-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 500px;
  padding: 20px;
}

.under-development {
  text-align: center;
  background-color: #f5f7fa;
  padding: 50px;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.under-development h1 {
  font-size: 28px;
  color: #333;
  margin-bottom: 20px;
}

.under-development p {
  font-size: 16px;
  color: #666;
  margin-bottom: 30px;
}
</style>