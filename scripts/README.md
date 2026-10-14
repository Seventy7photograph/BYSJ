# 验收脚本

三个验收脚本覆盖「接口权限 → 业务闭环 → 页面渲染」三层，另有三项性能工具。
它们都用项目自己的 JWT 密钥现场签发令牌，不需要知道任何账号密码。

## 前提

- 后端已在 `http://127.0.0.1:9090` 启动，MySQL 与 Redis 正常
- 前端 dev server 已在 `http://127.0.0.1:5173` 启动（只有页面脚本需要）
- 前端依赖已安装（浏览器驱动复用 `BYSJ.PETS.FEC/node_modules`）

## 运行

```bash
node scripts/verify-all.cjs          # 三个一起跑
node scripts/verify-permissions.cjs  # 只跑权限矩阵
node scripts/verify-business-flow.cjs
BASE_URL=http://127.0.0.1:5173 node scripts/verify-pages.cjs
```

## 性能工具（`scripts/perf/`）

`mysqldump` 出开发库、改名导入 `db_bysj_perf`，再执行生成脚本：

```bash
node scripts/perf/analyze-queries.cjs db_bysj_perf BEFORE   # 热点查询计时
mysql -u root -p db_bysj_perf < 数据库文件/迁移记录/2026-10-15_查询索引优化.sql
node scripts/perf/analyze-queries.cjs db_bysj_perf AFTER
node scripts/perf/load-test.cjs http://127.0.0.1:9091 20 20
```

- `seed-perf-data.sql` 把各表放大到万级（2 万商品、3 万订单、10 万消息）。
  开发库只有 37 件商品，在这个体量上所有查询都是全表扫描，分析不出任何结论。
- `analyze-queries.cjs` 对热点查询跑 `EXPLAIN ANALYZE`，每条取 5 次中位数；
  单次读数很容易被冷缓存干扰（实测出现过一次 52 ms 的假回退）。
- `load-test.cjs` 用内置 `fetch` 做并发压测，混合比例贴近真实浏览行为。
  建议让被测实例指向放大库、并关掉 SQL 日志打印，否则测的是日志性能。

## 各脚本在验证什么

### `verify-permissions.cjs`

对 40 个代表性接口 × 5 种身份（匿名 / 买家 / 商家 / 管理员 / 超级管理员）逐一发请求，
判定「是否越过了鉴权门」：`401`、`403` 视为被拦，其余状态码视为放行，并与期望模型比对。

期望模型：匿名只能访问公开接口；买家只能访问自己的数据；商家在买家能力之上叠加
商家经营接口；管理员只做平台运营（不拥有购物车/收藏等买家自有数据）；
超级管理员持有根权限，全区域放行。

输出两张清单：**越权**（不该放行却放行了）与**过严**（应当放行却被拦了）。
两者都应为空。

### `verify-business-flow.cjs`

走真实接口跑主链路：加购 → 从购物车下单 → 支付 → 发货 → 确认收货 → 申请退款 →
商家同意退款，并在每一步核对库存变化：

- 支付后 `product.stock` 应精确减少订单数量（验证原子扣减）；
- 退款成功后库存应回补（验证退款不会永久吞掉库存）；
- 超量下单/支付应被拒绝（验证不会超卖）；
- 买家不能替商家发货、商家不能进管理端、管理员不能改超管授权（验证越权拦截）；
- 驳回商品不填理由应被拒绝，审核通过后应自动上架。

### `verify-pages.cjs`

用 Playwright（Edge）以四种角色打开共 30 个路由，桌面 1440 与移动 390 两档，
收集控制台错误、页面异常、`/api` 下 ≥400 的响应，并测量横向溢出。
三项里有任意一项非零即标记该页有问题。
