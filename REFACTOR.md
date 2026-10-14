# 重构记录（2026-10-15）

前后端重构的完整清单。设计权威见 [PRODUCT.md](PRODUCT.md) 与 [DESIGN.md](DESIGN.md)；
数据库变更见 `数据库文件/2026-10-15_*.sql`。

## 一、设计系统（新增）

| 文件 | 作用 |
| --- | --- |
| `PRODUCT.md` | 四类角色的职责、产品定位、术语表 |
| `DESIGN.md` | 「灰卡与规格表」视觉世界：色调阶、三条信号色、字体、动效、招牌组件 |
| `BYSJ.PETS.FEC/src/styles/tokens.css` | 唯一的设计令牌层（颜色/字号/间距/圆角/动效/密度） |
| `BYSJ.PETS.FEC/src/styles/base.css` | 基础层：重置、浏览器表面（选区/滚动条/焦点环）、通用原子类 |
| `BYSJ.PETS.FEC/src/styles/element.css` | 把 Element Plus 重新蒙到令牌上，而不是被它的默认蓝色牵着走 |
| `BYSJ.PETS.FEC/src/components/ui/` | 共享组件：AppIcon / StatePill / PriceTag / SpecList / ImageFrame / ProductCard / SectionHead / StatStrip / EmptyState / FileUploader |
| `BYSJ.PETS.FEC/src/constants/domain.ts` | 状态字典（订单/审核/上下架/用户/店铺/成色），收敛原先散落在 20+ 页面的重复映射表 |
| `BYSJ.PETS.FEC/src/utils/format.ts` | 金额、日期、库存、图片地址的唯一实现 |

**三种密度，一套组件**：前台 `--dense:1.35`、商家 `1.0`、管理端 `0.85`，通过
根元素的 `data-density` 切换，同一组件在三个控制台里自动收紧或放松。

**字体**：自托管 IBM Plex Sans / Plex Mono（latin 子集共 99KB），中文交回系统字体。

## 二、前端重构

全部 60+ 页面重写，按角色划分：

- **买家**：首页（原为 60 余条硬编码商品，现改为真实查询）、商城、商品详情、购物车、
  确认订单、支付、订单详情、我的订单、二手（列表/详情）、租赁（列表/详情，含租期计算器）、
  收藏、地址、个人中心、消息中心、社区、404、登录/注册/找回密码。
- **商家**：外壳、工作台、商品发布/编辑/管理、库存管理、订单管理/详情、店铺管理、个人中心。
- **管理员**：外壳、待办总览、商家认证审核、商品审核、用户管理、商家账户、分类、品牌、公告、个人中心。
- **超级管理员**：外壳、总览、管理员账号、权限清单、角色权限矩阵、个人中心。

### 前端修掉的问题（按月归类）

**接口层**：`api/user/order.ts` 全部路径都打错（`/order/list`、`PUT /order/{id}/cancel`、
`/order/{id}/receipt` 后端都不存在）；`api/admin/*` 的分页与状态参数名与后端不符；
`api/super-admin/*` 打了不存在的 `/permissions/tree`，启停把参数放进 body 而后端收 query；
`api/merchant/inventory.ts` 里塞了 200 多行 mock 数据、`batchImportInventory` 是个只
`console.warn` 的假实现。全部改为真实调用。

**假功能**：支付页的收款码是 picsum 随机图、点一次"支付"还会再要一次"我已支付完成"；
订单详情有编造的物流轨迹；商家首页有写死的 `+12.5% 较上月`；管理端图表是假数据；
二手详情的议价按钮打向不存在的 `/second-hand/negotiate`；个人中心的"实名认证"提交到
不存在的 `PUT /user/verify`。这些入口要么接到真实接口，要么按事实删掉并说明。

**竞态与并发**：`axios.ts` 会取消同 URL 的并发请求，并把取消结果解析成 `{list:[],total:0}`
这一"成功的空列表"——页头与页面同帧取同一接口时，必有一方拿到假空数据。改为共享同一
Promise。路由守卫在首次导航时读不到尚未异步恢复的 token，直接刷新 `/orders` 会被弹回
登录页，改为在守卫里同步水合本地登录态。

**安全**：`Profile.vue` 一度用 `v-html` 渲染商品描述；`Payment.vue` 无实际校验；
多个页面把 token 打进控制台。

## 三、后端修正

| 问题 | 说明 |
| --- | --- |
| 列表页缩略图与库存恒为空 | `selectGoodsList` 漏选 `p.stock` 与主图，前端只能显示占位图 |
| 默认排序是 `ORDER BY RAND()` | 列表每次刷新都变样且无法走索引；改为稳定排序，`random` 变成显式选项 |
| 商家商品列表泄漏他人数据 | `sellerId` 在解析不到登录用户时默认成 `8L`，未认证请求可看到 8 号商家的全部商品 |
| 商家库存列表同样问题 | 匿名请求兜底成 8 号商家 |
| `POST /shop/products` 不存在 | 前端一直在调，商城列表永远拿不到数据 |
| 权限矩阵形同虚设 | `DynamicPermissionFilter` 只按 `user_type` 放行，`permission`/`role_permission` 从未被读取，`matchUrl`/`matchMethod` 是死代码 |
| 商品驳回理由丢失 | `auditProduct` 完全丢掉 `rejectReason`，商家看不到为什么被驳回 |
| 公告发布后无人可见 | 发布写 `notice_status=1`，而消息中心只捞 `0` |
| 订单筛选只作用于当前页 | 状态与订单号在分页之后于 Java 里过滤，翻页漏单、`total` 不可信 |
| 租赁租期从不落库 | `insertBatch` 漏写 `order_item.lease_term` |
| 库存缓存清理是空壳 | 只把 key 前缀算出来，一行都没删，调整库存后列表最长 5 分钟显示旧值 |
| 规格参数永远存不进去 | `setParameters("{}")` 是写死的 |
| 店铺 logo 覆盖个人头像 | 上传 logo 直接写进 `user.avatar_url` |
| 密码会打进日志 | 登录接口 `System.out.println(password)`；收藏接口打印完整 JWT |
| 找回密码可重置任意账号 | 用自己邮箱收到的验证码 + 别人的用户名即可改掉对方密码 |
| 验证码永不过期 | 邮件写"有效期 5 分钟"，实际是内存里的静态 Map，进程不重启就永久有效 |
| 管理员接口返回密码哈希 | `User.password` 未做序列化屏蔽 |
| 触发器缺陷 | 两个 `AFTER INSERT ON product` 定义互相覆盖；`trg_rental_overdue_freeze` 引用了不存在的 `order` 表；`sku` 没有唯一键导致 `ON DUPLICATE KEY` 永不生效；`trg_user_nickname` 无条件覆盖注册时填写的昵称 |
| 调试噪音 | 78 处 `System.out.println`、9 处 `printStackTrace`，全部改为结构化日志 |

## 四、存储重构（上传/下载）

**改造前**：三条互不相干的写盘路径，两份互相矛盾的配置。

1. `FileUploadUtil` 写 `file.upload.path`，返回 `/images/xxx`；
2. `UserController` 直接 `transferTo` 到 `public/head`，返回 `/head/xxx`；
3. `ShopServiceImpl` 写 `public/auth`，返回 `/auth/xxx`。

后两条绕开 `sys_image` 登记表，读的时候靠前端 `public/` 目录碰巧命中。而真正生效的
`WebMvcConfig` 把 `/images/**` 硬编码到 `G:/study/AAA-BYSJ/images/`——**另一个项目**的
目录；`file.upload.path` 指向 `G:/study/AAA-BYSJ/.../public/images`，同样是旧工程。

**改造后**：

```
file:
  storage:
    root: ${FILE_STORAGE_ROOT:.../BYSJ.PETS.BEC/data/uploads}
    url-prefix: /uploads
    max-size-mb: 10
    max-edge: 1920
    allowed-extensions / allowed-biz-types / pdf-biz-types
```

- 唯一入口 `POST /files/upload`（`UploadedFile{bizType}` 区分商品图/头像/店铺 logo/资质/评价/公告），
  校验扩展名与 Content-Type、真实解码一次、按 `yyyy/MM` 分目录、压缩到最长边 1920、
  记录宽高与字节数，**每次落盘都登记 `sys_image`**。
- 存储根目录在后端（`BYSJ.PETS.BEC/data/uploads`，已 gitignore），
  前端 `public/` 只放随代码走的设计素材；Vite 增加 `/uploads` 代理。
- 头像与店铺 logo 上传即回写 `user.avatar_url` / `user.shop_logo_url`，
  不再需要"上传完再调一次接口"。
- 业务代码不再自己拼路径、自己 `transferTo`；`FileUploadUtil` 已删除。
- 历史文件全部迁移到新根（seed / avatar / auth 三个子目录），数据库中的
  `/images/`、`/head/`、`/auth/` 路径统一改写为 `/uploads/...`，
  原先未登记的 40 个文件回填进 `sys_image`。

## 五、数据库

`数据库文件/2026-10-15_存储与数据整治.sql`、`2026-10-15_模拟数据补全.sql`、
`2026-10-15_权限目录补全.sql`。

- `product_image.is_deleted` 原为 `tinyint(3) unsigned zerofill`，值域里混着
  `001`/`000`/`NULL`；MyBatis-Plus 的逻辑删除判定 `is_deleted = 0`，于是值为 `NULL`
  的行被静默排除——商品 8/20/21/23/25 因此全部没有主图。归一后 8 件商品恢复主图。
- 去重绑定；一个商品只保留一张主图（其余降级为详情图），列表页与详情页口径统一。
- 库存为负（`product 24` 是 `-137`）→ 归零；二手商品库存改为单件在售。
- 未通过审核却挂着上架的脏数据 → 下架。
- 补齐 `payment` 支付流水（原表 0 行，而订单里已有支付时间与流水号）；订单完成时间与流水号一致化。
- 删除 4 张从未被使用的空壳表（`user_member`/`statistics`/`rental_rule`/`rental_equipment_status`）。
- 重建 4 个触发器；`sku` 与 `inventory` 补唯一键。
- 权限目录补齐 `BRAND_MANAGE`、`OPERATION_LOG` 并授予管理员角色。
- 模拟数据：5 件二手商品补齐二手档案、37 件商品补齐规格参数、13 条已完成订单补齐评价。

## 六、素材清理

| 位置 | 前 | 后 |
| --- | --- | --- |
| `BYSJ.PETS.FEC/public/` | 324.6 MB / 590 文件 | 1.4 MB / 7 文件 |
| `BYSJ.PETS.FEC/dist/` | 81.8 MB | 已删除（可重新构建） |
| 仓库根 `node_modules/` | 182.7 MB | 已删除（依赖声明在 FEC 内） |

- 190 MB 品牌产品图库 → 后端 `data/uploads/library/`（不再进前端构建产物，也不进版本库）；
- 80 MB 未引用素材与 51 MB 源照片 → `data/uploads/library/_unused/`；
- 首页与登录页改用优化后的 `/media/hero-shoot.jpg`（956KB，原 18MB）与
  `/media/hero-skyline.jpg`（198KB，原 13MB）；
- 删除 3 个零引用的遗留组件；`element-china-area-data` 由"靠上级 node_modules 兜住"
  改为正式声明并本地安装。

## 七、验收

- `npm run build`（含 `vue-tsc` 类型检查）通过，**0 类型错误**；
- 后端 `mvn compile` 通过；
- 用项目自己的 JWT 密钥为四种角色签发令牌，真实浏览器（Edge）跑 30 个路由 ×
  1440/390 两档：**横向溢出 0、控制台错误 0、HTTP ≥ 400 为 0**；
- `impeccable detect` 对 `src/` 返回空数组（0 条发现）。

## 八、尚未解决

1. **权限粒度到接口，不到数据行**：矩阵可以细到「方法 + 路径」，角色与账号靠
   `role.user_type` 对应，因此一个账号无法同时拥有多个自定义角色。
2. **商家/管理端列表分页部分仍在客户端**：`/merchant/inventory`、`/merchant/product/list`
   的审核状态筛选、`/admin/notices` 的类型筛选仍是取一个窗口再本地过滤，商品量上来后要下推到 SQL。
3. **退款与拆单**：一个订单只能属于一个商家，且租赁不能与其它类型混选，这是
   `create-from-cart` 的硬约束；真正的跨店拆单需要后端支持。
4. **实名认证只有展示**：`user` 表有 `id_card` 但没有提交接口。
5. **支付是模拟的**（按需求保留）：`orders/pay` 直接改状态，没有对接任何支付网关，
   `payment.qr_code` 无来源。
6. **未做端到端压测**：索引与慢查询只做了人工核对，没有 `EXPLAIN` 报告。
7. **`product.condition` 的表注释仍是 1–4 老编码**，实际存的是 0–100 百分比，注释需要单独改。
8. **商家回复评价只有接口没有页面**：`POST /evaluations/{id}/reply` 已开通权限，
   买家端能看到回复，但商家控制台还没有专门的评价列表页。

---

## 九、第二轮：权限、安全与库存（2026-10-15 续）

### 权限：从"装饰"变成真正的鉴权

上一轮只解决了「矩阵不参与鉴权」，但留下一个更大的洞：**买家与商家角色的授权表是空的**，
过滤器只能回退到"按 user_type 判前缀"的粗粒度白名单。而白名单分不清同一个前缀下的
不同角色动作 —— `/orders/**` 里既有买家的取消订单，也有商家的发货。

实测确认的越权：普通买家可以调用 `POST /orders/{id}/ship` 把订单标记成已发货，
也可以读取 `/refunds/merchant/list`。

修法不是加特例，而是把授权补全、然后让回退逻辑消失：

| 项 | 处理 |
| --- | --- |
| 新增权限项 | 买家 45 条、商家专属 41 条、管理员自助 6 条、评价回复 1 条（共 137 条权限） |
| 角色授权 | 买家 45、商家 86、管理员 47、超级管理员 43 |
| 过滤器 | 角色没有任何授权时**直接拒绝**（fail-closed），不再有"猜"的分支 |
| 路径模式 | `/admin/brands/**` 现在同时匹配前缀本身与其子路径（原先只匹配子路径，把列表接口自己拒了） |
| 缓存失效 | 超管改动角色权限时立即清空过滤器缓存，不必等 60 秒 |
| HTTP 语义 | 未登录返回 **401**、已登录无权限返回 **403**（原先两种都是 403，前端把"登录过期"显示成"没有权限"） |

同时清掉三处"看起来有鉴权其实没有"的地方：`POST /orders/update-overdue`
（任何人可触发全站订单状态变更，已改为小时级定时任务）、`POST /image/upload`
（未被任何权限覆盖的上传别名，已下线）、`GET /image/product/{id}`（与商家端重复，已下线）。

### 安全审计结果

| 检查项 | 结论 |
| --- | --- |
| SQL 注入 | MyBatis XML 中 `${}` 出现 **0 次**，全部走 `#{}` 参数化；`.last("LIMIT 1")` 等均为常量 |
| XSS | 前端 `v-html` / `innerHTML` 出现 **0 次**；内容由 Vue 默认转义 |
| 假安全工具 | `SqlInjectionUtil`、`src/utils/xssProtection.js` 零引用（"有防护"的错觉），已删除；`XssProtectionUtil` 改为经 `TextSanitizer` 真正接入商品型号与描述、公告内容、评价与回复、退款理由的入库路径 |
| Redis | 验证码、重置验证码（5 分钟 TTL）、库存缓存、分布式锁、权限规则缓存都在使用；确认缓存值带 Jackson 类型信息可正确还原为 `Page` |
| CSP | 去掉 `script-src` 的 `unsafe-eval` 与 `unsafe-inline`，补 `object-src 'none'` / `base-uri 'self'` / `frame-ancestors 'none'`；`X-XSS-Protection` 按现行规范置 0，新增 `Referrer-Policy` 与 `Permissions-Policy` |
| CSV 导出 | 对 `= + - @` 开头的单元格做公式注入防护 |
| 凭证泄漏 | 登录接口打印密码、收藏接口打印完整 JWT 已移除；`User.password` 加 `@JsonIgnore` |

### 库存：并发与一致性

| 问题 | 说明 |
| --- | --- |
| 超卖 | 扣减是"查出来 → Java 里减 → 写回去"，两个并发订单会各自读到同一余量，最后一单必然超卖且库存可为负。改为把条件写进 `WHERE` 的原子扣减（`stock >= ?`），影响 0 行即拒绝支付 |
| 退款吞库存 | 退款成功只改订单状态，库存永久停在"已卖出"。已补回补逻辑 |
| 双向同步冲突 | `inventory → product` 的触发器与下单时 `product → inventory` 的镜像互相冲突，MySQL 以 1442 拒绝执行，**支付直接失败**（业务闭环测试抓到）。去掉隐式触发器，库存改为单向显式维护：`product.stock` 权威，写入方负责镜像到 `inventory` |
| 一键下单重复 | 下单增加按用户的 Redis 分布式锁（原先只靠前端 `submitting` 标志，挡不住重试与多标签页） |
| 数据补齐 | 6 件商品缺默认 SKU 与库存行（`inventory.sku_id` 有外键，缺 SKU 连库存行都建不了），已补齐 |
| 自动完成口径 | 「超期自动完成」原先把未付款、退款中的订单一并"完成"，改为只处理「已发货」满 14 天的订单 |

### 验证结果

三个可复现脚本见 [scripts/](scripts/README.md)：

- **权限矩阵**：40 条接口 × 5 种身份，**越权 0、过严 0**
- **业务闭环**：**20/20 通过**（加购→下单→支付→发货→收货→退款回补，含超卖与越权拦截）
- **页面渲染**：四角色 30 个路由 × 双视口，**0/30 有问题**（横向溢出 0、控制台错误 0、HTTP ≥400 为 0）
