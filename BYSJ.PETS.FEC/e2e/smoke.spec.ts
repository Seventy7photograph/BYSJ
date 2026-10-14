import { expect, test } from '@playwright/test'

/**
 * 冒烟测试：只验证前台在真实渲染，不依赖后端可用。
 * 更完整的四角色走查与权限矩阵见仓库根的 scripts/。
 */
test.describe('前台冒烟', () => {
  test('首页渲染出品牌与主导航', async ({ page }) => {
    await page.goto('/index')

    await expect(page).toHaveTitle(/首页|摄影器材交易系统/)
    await expect(page.getByRole('link', { name: /摄影器材交易系统/ }).first()).toBeVisible()
    await expect(page.getByRole('navigation', { name: '主导航' })).toBeVisible()
    await expect(page.getByRole('link', { name: '器材商城' })).toBeVisible()
  })

  test('未登录访问购物车会跳转到登录页', async ({ page }) => {
    await page.goto('/cart')
    await expect(page).toHaveURL(/\/login/)
  })

  test('不存在的地址落到 404 页并提供出口', async ({ page }) => {
    await page.goto('/this-route-does-not-exist')
    await expect(page.getByText(/页面不存在|找不到/).first()).toBeVisible()
  })
})
