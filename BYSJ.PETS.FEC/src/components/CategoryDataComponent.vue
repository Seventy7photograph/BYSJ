<template>
  <!-- 这个组件不渲染任何内容，仅提供数据 -->
</template>

<script setup>
import { ref } from 'vue';

// 摄影器材分类数据
const categoryList = ref([
  {
    id: 1,
    name: "相机",
    value: "CAM", // 对应后端category_code
    img: "/public/CAM.png"
  },
  {
    id: 2,
    name: "镜头",
    value: "LEN", // 对应后端category_code
    img: "/public/LEN.png"
  },
  {
    id: 3,
    name: "无人机",
    value: "DRONE", // 对应后端category_code
    img: "/public/DRO.png"
  },
  {
    id: 4,
    name: "配件",
    value: "ACC", // 对应后端category_code
    img: "/public/ACC.png"
  },
  {
    id: 5,
    name: "灯光设备",
    value: "LIG", // 对应后端category_code
    img: "/public/LIG.png"
  },
  {
    id: 6,
    name: "存储设备",
    value: "STO", // 对应后端category_code
    img: "/public/STO.png"
  }
]);

// 暴露数据和方法
defineExpose({
  categoryList: categoryList.value
});
</script>
