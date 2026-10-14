# 摄影器材交易系统

**版本 3.0.1** · [更新日志](CHANGELOG.md) · [性能报告](docs/performance.md) · [MIT 许可](LICENSE)

一个面向摄影器材的多模式交易平台：**全新零售、二手流转、器材租赁**三条业务线
共用同一套库存与订单流转。本科毕业设计作品。

系统按四类角色划分为四套界面，共用一套设计系统与一套接口权限模型：

| 角色 | 在这里做什么 |
| --- | --- |
| 买家 | 按分类/品牌/价格筛选器材，加购下单、支付、退款、评价；收藏与地址管理 |
| 商家 | 发布与维护商品、管理库存与安全库存、处理订单发货与退款、维护店铺资料与资质 |
| 平台管理员 | 审核商家认证与商品上架、管理用户/分类/品牌/公告、查看操作日志 |
| 超级管理员 | 管理员账号管理、权限目录维护、角色 × 权限矩阵分配 |

---

## 技术栈

| 层 | 选型 |
| --- | --- |
| 后端 | Spring Boot 3.5.6 · Spring Security · MyBatis-Plus 3.5.5 · JWT (jjwt) · Sa-Token |
| 数据库 | MySQL 8.0（`db_bysj_pets`） |
| 缓存 | Redis（图形验证码、库存列表缓存、分布式锁、权限规则缓存） |
| 前端 | Vue 3 · TypeScript · Vite 7 · Element Plus · Pinia · Vue Router |
| 运行时 | JDK 17+（开发环境 JDK 18）· Node.js ≥ 20.19 |

---

## 快速开始

### 1. 准备环境

- MySQL 8 与 Redis 已启动（默认 `localhost:3306` / `localhost:6379`）
- JDK 17+、Maven 3.9+、Node.js 20+

### 2. 导入数据库

```bash
mysql -u root -p < 数据库文件/db_bysj_pets.sql
```

这一份是**完整快照**（建表 + 触发器 + 演示数据 + 权限目录），导入即可用。
`数据库文件/迁移记录/` 下的脚本是这次重构对**已有旧库**的升级步骤，
全新安装不需要执行。详见 [数据库文件/README.md](数据库文件/README.md)。

### 3. 启动后端

```bash
cd BYSJ.PETS.BEC
mvn spring-boot:run
```

服务在 `http://localhost:9090`。
数据库账号、文件存储路径在 `src/main/resources/application.yml` 中配置，
存储根目录可用环境变量 `FILE_STORAGE_ROOT` 覆盖。

### 4. 启动前端

```bash
cd BYSJ.PETS.FEC
npm install
npm run dev
```

浏览器打开 `http://localhost:5173`。开发服务器会把 `/api` 与 `/uploads` 代理到后端。

### 5. 演示账号

数据库里已带四类角色的账号，密码均为 `Test123456`：

| 角色 | 账号 |
| --- | --- |
| 买家 | `13800138000` |
| 商家 | `52440000799352866W` |
| 管理员 | `18344551993` |
| 超级管理员 | `18344551990` |

---

## 目录结构

```
AAA-BYSJ-New/
├── BYSJ.PETS.BEC/                 后端
│   ├── src/main/java/bysj/pets/bec/
│   │   ├── config/                安全、权限过滤器、存储配置、跨域、异常处理
│   │   ├── controller/            接口层
│   │   ├── service/               业务层
│   │   ├── mapper/                持久层（含 xml/ 下的 SQL）
│   │   └── utils/                 JWT、验证码、缓存、分布式锁、文本清洗
│   └── data/uploads/              上传存储根：seed/avatar/auth 为种子素材，其余为运行时上传
├── BYSJ.PETS.FEC/                 前端
│   ├── public/                    设计素材（字体、占位图、hero 图）
│   └── src/
│       ├── styles/                设计令牌与基础层
│       ├── components/ui/         共享组件库
│       ├── constants/             领域字典（状态码 → 文案 + 色调）
│       ├── api/                   接口封装
│       └── pages/                 按角色分目录：user / merchant / admin / super-admin
├── 数据库文件/                     数据库脚本
├── scripts/                       验收脚本（页面、权限矩阵、业务闭环）
├── docs/api/openapi.json          接口文档（由运行中的后端导出）
├── PRODUCT.md                     产品定位与角色职责
├── DESIGN.md                      设计系统（视觉世界、令牌、组件约定）
├── REFACTOR.md                    本次重构改动与问题清单
├── CHANGELOG.md                   版本变更记录
├── CONTRIBUTING.md                贡献指南
└── SECURITY.md                    安全策略与部署注意
```

接口文档在服务启动后可访问 <http://localhost:9090/swagger-ui.html>；
`docs/api/openapi.json` 是从运行中的后端导出的快照，接口变动后用
`curl http://127.0.0.1:9090/v3/api-docs -o docs/api/openapi.json` 重新生成。

---

## 设计系统

界面遵循 [DESIGN.md](DESIGN.md) 定义的「灰卡与规格表」：中性色调阶承担全部结构，
三条信号色各司其职（琥珀=金额、朱红=危险、青=正常），规格参数以对齐的数据呈现
而不是散文。前台 `--dense:1.35`、商家 `1.0`、管理端 `0.85`，同一套组件按角色
切换密度。

字体是自托管的 IBM Plex Sans / Plex Mono（latin 子集，共 99KB），中文交回系统字体。

---

## 安全实现

| 面向 | 做法 |
| --- | --- |
| SQL 注入 | 全部走 MyBatis 参数化（`#{}`），仓库内 **0 处** `${}` 拼接 |
| XSS | 前端 **0 处** `v-html`，插值由 Vue 默认转义；后端对跨角色可见的自由文本（商品型号与描述、公告、评价与回复、退款理由）在入库前剔除脚本类标记 |
| 敏感字段 | `User.password` 加 `@JsonIgnore`，不会随接口返回 |
| 口令与验证码 | BCrypt(12) 存储密码；图形验证码与重置验证码都存在 Redis 并带 TTL，重置验证码与账号绑定邮箱校验 |
| 越权 | 两层鉴权：Spring Security 按角色粗筛，`DynamicPermissionFilter` 再按 `role_permission` 里授予的「方法 + 路径模式」逐条比对，**fail-closed** |
| 传输与响应头 | CSP（无 `unsafe-eval`）、`X-Content-Type-Options`、`X-Frame-Options`、`Referrer-Policy`、`Permissions-Policy` |
| 文件上传 | 单一入口 `/files/upload`：白名单扩展名 + 真实解码校验 + 尺寸压缩 + 日期分目录 + 统一登记 `sys_image` |
| 导出 | CSV 导出对 `= + - @` 开头的单元格做公式注入防护 |
| 凭证 | 日志中不打印密码与 JWT；全站 `System.out.println` 已替换为结构化日志 |

权限矩阵的验证方式与结果见 [scripts/README.md](scripts/README.md)。

---

## 性能

热点查询的 `EXPLAIN` 分析与并发压测结果见 [docs/performance.md](docs/performance.md)。
要点：

- 开发库只有 37 件商品，任何查询都会走全表扫描，**索引分析必须在放大的数据集上做**。
  `scripts/perf/seed-perf-data.sql` 可把各表放大到万级。
- 在 2 万商品 / 3 万订单 / 10 万消息的数据集上，商城列表 74.8 → 11.2 ms，
  按交易线筛选 51.5 → 7.7 ms，价格升序 70.5 → 9.4 ms；
  并发 20 的吞吐 16 → 236 req/s。
- 压测同时暴露了三个代码层面的缺陷：列表分页是"全部取出再在 Java 里切片"、
  计数查询做了两个用不上的 `LEFT JOIN`、排序兜底列方向不一致使索引失效。

```bash
# 放大数据 → 计时热点查询 → 并发压测
mysql -u root -p db_bysj_perf < scripts/perf/seed-perf-data.sql
node scripts/perf/analyze-queries.cjs db_bysj_perf
node scripts/perf/load-test.cjs http://127.0.0.1:9090 20 20
```

---

## 验收

```bash
# 后端
cd BYSJ.PETS.BEC && mvn -o compile

# 前端（含 TypeScript 类型检查）
cd BYSJ.PETS.FEC && npm run build

# 端到端（需先启动后端与前端）
cd scripts && npm run verify
```

`scripts/` 下三个脚本分别验证：四种角色共 30 个页面的渲染与横向溢出、
40 条接口 × 5 种身份的权限矩阵、以及 20 项主业务闭环（加购→下单→支付→发货→
收货→退款回补库存，含超卖拦截与越权拦截）。

---

## 已知限制

1. **支付是模拟的**：`/orders/pay/{orderId}` 直接改写订单状态，没有对接真实支付网关。
2. **权限粒度到接口**：角色与账号通过 `role.user_type` 对应，暂不支持同一账号拥有
   多个自定义角色；矩阵可以细到「方法 + 路径」，但不能再细到数据行级。
3. **部分列表筛选在客户端完成**：`/merchant/inventory`、`/admin/notices` 的类型筛选
   取一个窗口后本地过滤，数据量大时应下推到 SQL。
4. **一个订单只能属于一个商家**，且租赁商品不能与其它类型混选，这是下单接口的约束，
   跨店拆单需要后端支持。
5. **实名认证只有展示**：`user` 表有 `id_card` 字段但没有提交接口。
6. **深页码仍有代价**：`LIMIT 16000, 20` 需要扫描并丢弃 16000 条索引项，第 800 页
   约 460 ms。彻底解决要改成游标分页，会改变接口契约，本次未做。
7. **关键词搜索走不了索引**：`LIKE '%kw%'` 只能全表扫描（2 万商品约 79 ms），
   要优化需引入全文索引或独立检索引擎。
8. **权限过滤器对已登录请求每请求查一次 `user` 表**：权限规则有 60 秒缓存，
   用户查询没有，并发上去后这是可以省掉的一次往返。

---

## 重构记录

本次重构的范围、修掉的具体缺陷与遗留问题见 [REFACTOR.md](REFACTOR.md)。
