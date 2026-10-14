# 更新日志

本文件记录每个版本对外可见的变化。格式参考
[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [3.0.0] - 2026-10-15

首个重构完成版。相比 2.x，前后端与数据库都做了结构调整，
旧版代码与历史文件不再随仓库提供。

### 新增

- 设计系统：`tokens.css` / `base.css` / `element.css` 三层令牌，四种角色共用一套
  组件库，按 `data-density` 切换前台 1.35、商家 1.0、管理端 0.85 三档密度。
- 共享组件库：图标、状态徽标、价格、规格表、图片框、商品卡、区块头、数据条、
  空状态、上传控件。
- 单一文件上传入口 `POST /files/upload`：扩展名白名单、真实解码校验、尺寸压缩、
  日期分目录、统一登记 `sys_image`；存储根可用 `FILE_STORAGE_ROOT` 覆盖。
- 真正的 RBAC：`user_type → role → role_permission → permission(方法 + 路径)`
  逐条比对，137 条权限、4 个角色共 222 条授权，角色无授权时 fail-closed。
- 可复现的验收脚本 `scripts/`：权限矩阵、主业务闭环、四角色页面走查。
- 工程规范文件：`.gitattributes`、`.editorconfig`、`LICENSE`、`CONTRIBUTING.md`、
  `SECURITY.md`、CHANGELOG、Issue 与 PR 模板。

### 变更

- 前端 60+ 页面按角色重写；首页由静态硬编码改为真实数据驱动。
- 后端接口面收敛：补齐 `/shop/products`；下线 `/image/upload`、
  `/image/product/{id}`、`/orders/update-overdue`。
- 库存改为单一写入口：`product.stock` 权威，写入方负责镜像到 `inventory`。
- 上传存储搬出前端 `public/`，前端资源目录从 324MB 降到 1.4MB。
- 数据库结构、触发器与权限目录整理为一份完整快照加按序迁移记录。

### 修复

- 越权：普通买家可以调用 `POST /orders/{id}/ship` 把自己的订单标记为已发货，
  并可读取 `/refunds/merchant/list`。
- 超卖：库存扣减原为"查出来再写回去"，并发下必然超卖且可为负，改为把条件写进
  `WHERE` 的原子扣减。
- 退款吞库存：退款成功只改订单状态，库存永久停留在"已卖出"。
- 支付失败：`inventory` 到 `product` 的触发器与下单时的反向镜像互相冲突
  （MySQL 1442），支付事务直接回滚。
- 权限矩阵形同虚设：过滤器只按 `user_type` 放行，`role_permission` 从未被读取。
- 商品驳回理由丢失、公告发布后无人可见、订单筛选只作用于当前页、
  租赁租期从不落库、规格参数写死成空对象、店铺 logo 覆盖个人头像。
- 安全：找回密码可重置任意账号；登录打印密码、收藏打印完整 JWT；
  重置验证码永不过期；密码哈希随接口返回；缺失静态资源回 500 而非 404；
  CSV 导出存在公式注入。
- 可用性：`axios` 取消并发同请求并返回假空列表；路由守卫在登录态恢复前
  把用户弹回登录页。

### 移除

- 旧版历史文档目录（作品附件、备份、归档、文档、答辩等）与重复的源码压缩包。
- 零引用的假安全工具：`SqlInjectionUtil` 与前端 `xssProtection.js`。
- 未被任何代码引用的零散素材与遗留构建产物。

### 已知限制

见 [README.md 的「已知限制」](README.md)。支付为模拟实现，按需求保留。

[3.0.0]: https://github.com/Seventy7photograph/BYSJ/releases/tag/v3.0.0
