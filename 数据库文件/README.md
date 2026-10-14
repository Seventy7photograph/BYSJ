# 数据库

数据库名：`db_bysj_pets`，字符集 `utf8mb4`，排序规则 `utf8mb4_bin`。

## 全新安装

只导入一份文件：

```bash
mysql -u root -p < db_bysj_pets.sql
```

`db_bysj_pets.sql` 是**当前完整快照**：建表、外键、索引、8 个触发器、权限目录
（137 条权限 / 4 个角色的授权）、以及可演示三条业务线的种子数据。导入后直接可用，
不需要再执行任何迁移脚本。

脚本顶部包含 `CREATE DATABASE IF NOT EXISTS` 与 `USE`，无需手工建库。

## 迁移记录（升级既有旧库时才用）

`迁移记录/` 下是本次重构对**旧版数据库**的升级步骤，必须**按顺序**执行。
如果是从全新快照安装，整个目录都可以忽略。

| 顺序 | 文件 | 做了什么 |
| --- | --- | --- |
| 1 | `inventory_trigger.sql` / `product_rental_sync.sql` | 原项目自带的触发器脚本（历史文件，其最终形态已并入快照与迁移） |
| 2 | `2026-10-15_存储与数据整治.sql` | 图片路径统一到 `/uploads`；`product_image.is_deleted` 去 zerofill 并归一；主图去重；库存/上架状态清洗；补 `payment` 流水；重建触发器；补 `sku`/`inventory` 唯一键 |
| 3 | `2026-10-15_模拟数据补全.sql` | 二手商品改为单件在售；补规格参数、二手档案、评价 |
| 4 | `2026-10-15_权限目录补全.sql` | 补管理员后台缺失的 `BRAND_MANAGE` / `OPERATION_LOG` 权限并授权 |
| 5 | `2026-10-15_角色权限目录.sql` | 为买家/商家/管理员补全各自的接口授权（92 条权限 + 角色绑定） |
| 6 | `2026-10-15_收尾补齐.sql` | 补评价回复权限；补缺失的默认 SKU 与库存行；校正两处库存 |
| 7 | `2026-10-15_库存单一写入口.sql` | 去掉 `inventory → product` 的隐式回写触发器，库存改为单向显式维护 |
| 8 | `2026-10-15_查询索引优化.sql` | 依据 `EXPLAIN ANALYZE` 补 6 个查询索引（商城列表、交易线筛选、价格排序、订单列表）并刷新统计信息 |

整套脚本已在一个空库上按顺序完整验证过，零报错。
第 8 个脚本用存储过程做了幂等，可以重复执行而不会因索引已存在而中断。

## 库存的两处存储

`product.stock` 与 `inventory.current_stock` 同时存在，这不是冗余：

- **`product.stock` 是权威值**，前台列表、下单扣减都读它；
- `inventory.current_stock` 是商家端库存管理页的视图，由写入方显式镜像。

两者原先靠一个触发器双向同步，而下单时需要「读 product、写 inventory」，
触发器又要求「写 product」，同一条语句里既读又写同一张表，MySQL 会以 1442 拒绝，
支付直接失败。因此改为单向：所有写入方都先写 `product`，再调用
`ProductMapper.syncInventoryFromProduct` 镜像到 `inventory`。

## 库存扣减的原子性

`ProductMapper.decreaseStockIfEnough` 把余量条件写进 `WHERE`：

```sql
UPDATE product SET stock = stock - #{quantity}
WHERE product_id = #{productId} AND stock >= #{quantity}
```

返回 0 行即表示余量不足，下单事务随即回滚。这样并发下单不会超卖，
库存也不会被减成负数。
