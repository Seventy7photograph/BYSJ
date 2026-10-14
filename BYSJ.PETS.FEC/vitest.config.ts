import { fileURLToPath } from 'node:url'
import { mergeConfig, defineConfig, configDefaults } from 'vitest/config'
import type { UserConfig } from 'vite'
import viteConfig from './vite.config'

export default mergeConfig(
  // defineConfig 的返回是一个联合类型（对象 / 函数 / Promise），
  // mergeConfig 只接受展开后的配置对象，这里收窄到 UserConfig。
  viteConfig as UserConfig,
  defineConfig({
    test: {
      environment: 'jsdom',
      exclude: [...configDefaults.exclude, 'e2e/**'],
      root: fileURLToPath(new URL('./', import.meta.url)),
    },
  }),
)
