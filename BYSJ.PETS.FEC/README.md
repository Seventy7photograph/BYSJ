# BYSJ.PETS.FEC — 前端

摄影器材交易系统的前端（Vue 3 + TypeScript + Vite + Element Plus + Pinia）。
项目总览、环境搭建与演示账号见[仓库根 README](../README.md)。

## 常用命令

```bash
npm install
npm run dev          # 开发服务器（默认 5173，/api 与 /uploads 代理到 9090）
npm run build        # 类型检查 + 生产构建
npm run type-check   # 只做类型检查
npm run lint         # ESLint 自动修复
npm run format       # Prettier 格式化 src/
npm run test:unit    # Vitest 单元测试
npm run test:e2e     # Playwright 端到端测试
```

## 目录约定

- `src/styles/` —— 设计令牌（`tokens.css`）、基础层（`base.css`）、
  Element Plus 主题覆盖（`element.css`）。**颜色与间距只从令牌里取**，
  不要在各页面写死数值。
- `src/components/ui/` —— 共享组件库（图标、状态徽标、价格、规格表、
  图片框、商品卡、区块头、数据条、空状态、上传控件）。
- `src/constants/domain.ts` —— 领域字典：状态码到「文案 + 色调」的唯一映射。
- `src/utils/format.ts` —— 金额、日期、库存、图片地址的唯一实现。
- `src/api/` —— 接口封装，按角色分目录。
- `src/pages/` —— 按角色分目录：`user` / `merchant` / `admin` / `super-admin`。

设计与交互约定见[仓库根 DESIGN.md](../DESIGN.md)。
