# 性能分析与压测报告

2026-10-15 · 针对 3.0.0

可复现工具在 [scripts/perf/](../scripts/perf/)：

- `seed-perf-data.sql` —— 把各表放大到万级的生成脚本
- `analyze-queries.cjs` —— 对热点查询做 `EXPLAIN ANALYZE` 计时
- `load-test.cjs` —— 混合请求的并发压测

## 一、为什么必须在放大的数据集上做

开发库里只有 37 件商品、50 笔订单、51 条图片记录。在这个体量上，优化器对**任何**
查询都会选择全表扫描 —— 全表就只有一页。此时做 `EXPLAIN` 得到的结论是"所有查询
都在全表扫描"，既不能说明问题，也不能验证优化。所以先把数据放大：

| 表 | 放大前 | 放大后 |
| --- | --- | --- |
| user | 10 | 5 010 |
| product | 37 | 20 037 |
| sku / inventory | 39 / 31 | 20 039 / 20 031 |
| product_image / sys_image | 59 / 51 | 20 054 / 20 051 |
| orders / order_item | 50 / 32 | 30 050 / 20 050 |
| sys_notice | 94 | 100 174 |
| evaluation | 13 | 10 013 |
| favorite | 14 | 20 014 |

商品分布刻意保留了未上架与待审核的样本（在售 16 285 件、待审 1 000 件），
否则筛选条件形同虚设，测不出索引的选择性。

## 二、`EXPLAIN` 分析与索引

### 优化前的问题

| 查询 | 计划 | 耗时 |
| --- | --- | --- |
| 前台商品列表 | `Table scan on p`（20 037 行）+ `filesort` | 24.5 ms |
| 后台商品审核列表 | `Table scan on p`（20 037 行）+ `filesort` | 8.9 ms |
| 商家订单列表 | 单列 `seller_id` 索引 + `filesort` | 14.6 ms |
| 前台商品总数 | 走的是 9 列宽索引的覆盖扫描 | 7.2 ms |

### 新增索引

脚本见 [数据库文件/迁移记录/2026-10-15_查询索引优化.sql](../数据库文件/迁移记录/2026-10-15_查询索引优化.sql)，
用存储过程做了幂等，可重复执行。

| 索引 | 服务的查询 |
| --- | --- |
| `product(audit_status, is_on_shelf, create_time, product_id)` | 商城默认列表与总数 |
| `product(audit_status, create_time)` | 后台商品审核队列 |
| `product(audit_status, is_on_shelf, product_type, create_time, product_id)` | 商城按交易线筛选 |
| `product(audit_status, is_on_shelf, price, product_id)` | 商城按价格排序 |
| `orders(user_id, create_time)` / `orders(seller_id, create_time)` | 买家 / 商家订单列表 |

排序方向与索引一致时，MySQL 8 可以直接反向扫描，`filesort` 随之消失：

```
-> Index lookup on p using idx_product_onsale_time
   (audit_status=1, is_on_shelf=1; iterate backwards)  (actual time=0.345..0.354 rows=20)
```

### 一个容易漏掉的步骤：`ANALYZE TABLE`

建完索引不刷新统计信息，优化器会估错代价。实测它给「商品总数」挑中了只有
`audit_status` 一列的索引，把 19 035 条索引项读出来再逐条过滤 `is_on_shelf`，
查询从 7.2 ms **退化到 52 ms**；执行 `ANALYZE TABLE` 后改选两列等值索引，降到 4.2 ms。
所以迁移脚本的最后一步固定是 `ANALYZE TABLE`。

### 取舍

`product` 表因此有 9 个索引。每个索引都会增加写入时的维护成本，这里选择加，
是因为商城读远多于写；如果后续商品写入量显著增长，应重新评估而不是默认保留。

## 三、压测暴露出的三个代码缺陷

索引只能解决"数据库怎么找数据"，下面三个是代码层面的问题，只有在真实数据量
和并发下才暴露得出来。

### 1. 列表分页是"全部取出再在 Java 里切片"（最严重）

`ProductServiceImpl.getGoodsList` 把匹配到的**全部**行查出来，再用 `for` 循环
截取 `[start, end)`。在 37 件商品的开发库上无人察觉；在 2 万件的库上：

```
pageNum=1    0.71 s
pageNum=200  0.74 s
pageNum=800  0.75 s     ← 耗时与页码无关，正是"全量取出再切页"的特征
```

修法是把 `LIMIT offset, size` 下推到 SQL。改完之后同一接口在放大库上从
**803 ms 降到 76 ms**。

### 2. 计数查询做了两个用不上的 `LEFT JOIN`

`selectGoodsTotal` 无条件 `LEFT JOIN product_category` 与 `brand`，但 `LEFT JOIN`
不可能减少行数、它们的列也不参与 `COUNT` —— 数据库却要为每一行多做两次关联查找：
1.6 万件商品就是 3.2 万次单行查询，`COUNT` 从 4 ms 变成 **85 ms**。

修法是让 JOIN 只在其筛选条件生效时才出现。改完后列表接口从 74.8 ms 降到 13.6 ms。

### 3. 排序的兜底列方向不一致，导致索引无法使用

`sort=price_asc` 生成的是 `ORDER BY p.price ASC, p.product_id DESC` —— 混合方向，
ASC 索引的正向与反向扫描都满足不了，只能退回全表扫描加 `filesort`：

```
价格降序  Index lookup on p using idx_product_onsale_price ... iterate backwards   0.8 ms
价格升序  Sort: p.price, p.product_id DESC（20 037 行）                            57 ms
```

把兜底列改成同向（`product_id ASC`）即可。兜底列只用于稳定排序，方向不影响语义。

## 四、接口延迟（放大库，单请求中位数）

| 接口 | 优化前 | 优化后 | 变化 |
| --- | --- | --- | --- |
| 商品详情 | 3.2 ms | 3.9 ms | 持平 |
| 分类列表 | 3.0 ms | 2.9 ms | 持平 |
| 商城列表（第 1 页） | 74.8 ms | **11.2 ms** | 6.7× |
| 商城列表（第 25 页） | 84.2 ms | **20.8 ms** | 4.0× |
| 按交易线筛选 | 51.5 ms | **7.7 ms** | 6.7× |
| 按价格升序 | 70.5 ms | **9.4 ms** | 7.5× |
| 按价格降序 | 9.5 ms | 9.2 ms | 持平 |
| 按分类筛选 | 12.3 ms | 9.5 ms | 1.3× |
| 关键词搜索 | 129 ms | 79.4 ms | 1.6× |

`EXPLAIN ANALYZE` 侧的改善更明显：列表与计数查询从 24.5 ms 量级降到 **1 ms 以内**。

## 五、并发压测

混合比例贴近真实浏览：列表页 30%、按类型 15%、商品详情 15%、价格排序 15%、
关键词 10%、订单列表 10%、分类与相关推荐 10%。

| 并发 | 吞吐 | 平均延迟 | p50 | p90 | p99 | 失败 |
| --- | --- | --- | --- | --- | --- | --- |
| 20 | **236 req/s** | 84 ms | 46.8 ms | 215 ms | 354 ms | 1 / 4744 |
| 50 | 240 req/s | 207 ms | 123 ms | 528 ms | 984 ms | 2 / 4843 |

优化前的同一套压测（并发 20）只有 **16 req/s**、平均延迟 607 ms。

把连接池从默认 10 提到 40 后吞吐没有变化（230 → 240），说明瓶颈不在连接池：
这台机器同时跑着 Node 压测进程、MySQL、Redis 和两个 JVM，**是单机 CPU 竞争
造成的平台期**，不是服务端配置问题。因此上表的绝对数字受限于测试环境，
有意义的是相对改善与各接口的延迟量级。

## 六、仍然存在的性能问题

1. **深页码**：`LIMIT 16000, 20` 需要扫描并丢弃 16000 条索引项，第 800 页仍需
   460 ms。这是 OFFSET 分页的固有问题，要到更深的分页才有体感。彻底解决需要改成
   游标分页（`WHERE create_time < ?`），会改变接口契约，本次未做。
2. **关键词搜索**：`LIKE '%kw%'` 无法走 B-Tree 索引，只能全表扫描，79 ms。
   要优化需引入全文索引或独立检索引擎。
3. **图片详情子查询**：列表每行都要为取主图跑一次带 `ORDER BY` 的子查询。
   数据量再大时应把主图页码化到 `product` 表，避免逐行子查询。
4. **权限过滤器每请求查一次用户**：`DynamicPermissionFilter` 对已登录请求会按
   用户名查一次 `user` 表。权限规则本身有 60 秒缓存，用户查询没有。并发上去后
   这是可以省掉的一次往返。
