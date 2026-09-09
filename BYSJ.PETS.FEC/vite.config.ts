import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import path from 'path'

export default defineConfig({
  plugins: [vue(), vueJsx()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src') // 路径别名，与TS配置一致
    }
  },
  server: {
    port: 5173,// 前端端口（默认，可修改）
    host: '0.0.0.0', // 允许所有网络接口访问，支持local和network
    open: false,// 启动时自动打开浏览器
    cors: true, // 允许所有来源的跨域请求
    allowedHosts: true, // Vite 7.x 中允许所有主机访问的正确配置
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:9090', // 使用 IP 地址而不是 localhost，避免 IPv6 解析问题
        changeOrigin: true, // 允许跨域
        rewrite: (path) => path.replace(/^\/api/, ''),
        logLevel: 'debug' // 添加调试日志
      }
    }
  }
})
