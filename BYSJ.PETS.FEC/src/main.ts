import { createApp } from 'vue'
import App from './App.vue'
import ElementPlus from 'element-plus'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import 'element-plus/dist/index.css'

// 导入路由
import router from './router'

// 导入状态管理
import { createPinia } from 'pinia'
const pinia = createPinia()

const app = createApp(App)

// 使用Element Plus并配置中文语言
app.use(ElementPlus, {
  locale: zhCn,
})

// 使用路由和状态管理
app.use(router)
app.use(pinia)

app.mount('#app')
