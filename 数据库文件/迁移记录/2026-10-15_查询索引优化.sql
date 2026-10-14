-- ============================================================================
-- 查询索引优化   2026-10-15
--
-- 依据：在放大到 2 万商品 / 3 万订单 / 10 万消息的数据集上做 EXPLAIN ANALYZE
-- （生成脚本见 scripts/perf/seed-perf-data.sql，分析结论见 docs/performance.md）。
-- 开发库只有 37 件商品，任何索引都会被优化器忽略，所以分析必须在放大的库上做。
--
-- 优化前两条最热的查询都是全表扫描：
--   · 前台商品列表   WHERE audit_status=1 AND is_on_shelf=1 ORDER BY create_time DESC
--                    → Table scan 20037 行 + filesort，25.3ms
--   · 后台商品审核   WHERE audit_status=0 ORDER BY create_time DESC
--                    → Table scan 20037 行，8.4ms
--
-- 取舍：product 上原本已有 4 个索引，再加 2 个会让写入时的索引维护成本上升。
-- 这里选择加，是因为前台列表的读频率远高于商品写入频率；如果后续商品写入量
-- 显著增长，应重新评估而非默认保留。
-- ============================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 幂等建索引：脚本可能被重复执行（例如先在生产库跑过一次再回来核对），
-- 直接 CREATE INDEX 撞上已有索引会中断后续语句，留下做了一半的库。
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `add_index_if_absent`;

DELIMITER //
CREATE PROCEDURE `add_index_if_absent`(IN p_table VARCHAR(64), IN p_index VARCHAR(64), IN p_cols TEXT)
BEGIN
    IF (SELECT COUNT(*) FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND INDEX_NAME = p_index) = 0 THEN
        SET @ddl = CONCAT('CREATE INDEX `', p_index, '` ON `', p_table, '` (', p_cols, ')');
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('已创建 ', p_table, '.', p_index) AS 结果;
    ELSE
        SELECT CONCAT('已存在，跳过 ', p_table, '.', p_index) AS 结果;
    END IF;
END //
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 1. 前台商品列表与总数
--    等值条件 (audit_status, is_on_shelf) 在前，排序列 create_time 在后，
--    product_id 兜底保证同一时间戳下的排序稳定。
--    ORDER BY 全是 DESC，MySQL 8 可以直接反向扫描这个 ASC 索引，无需 filesort。
-- ---------------------------------------------------------------------------
CALL `add_index_if_absent`('product', 'idx_product_onsale_time', '`audit_status`,`is_on_shelf`,`create_time`,`product_id`');

-- ---------------------------------------------------------------------------
-- 2. 后台商品审核列表：只按审核状态过滤，不需要 is_on_shelf，
--    上面那个索引在这里会因中间列缺失而用不上排序，单建一条。
-- ---------------------------------------------------------------------------
CALL `add_index_if_absent`('product', 'idx_product_audit_time', '`audit_status`,`create_time`');

-- ---------------------------------------------------------------------------
-- 3. 商城按交易线筛选（全新 / 二手 / 租赁）
--    交易线在后端是 product_type，放在两列等值条件之后、create_time 之前：
--    这样「productType=1 且按最新排序」可以只取前 20 条就停，而不是把
--    符合条件的 1.6 万条全走一遍再排序（实测 51ms → 个位数）。
-- ---------------------------------------------------------------------------
CALL `add_index_if_absent`('product', 'idx_product_onsale_type_time', '`audit_status`,`is_on_shelf`,`product_type`,`create_time`,`product_id`');

-- ---------------------------------------------------------------------------
-- 4. 商城按价格排序
--    价格排序无法复用按时间排序的索引，会退化成「扫全表 + filesort」（实测 80ms）。
-- ---------------------------------------------------------------------------
CALL `add_index_if_absent`('product', 'idx_product_onsale_price', '`audit_status`,`is_on_shelf`,`price`,`product_id`');

-- ---------------------------------------------------------------------------
-- 5. 订单列表：买家按 user_id、商家按 seller_id 取自己的订单，
--    再按创建时间倒序。原有索引只有单列，排序仍要走 filesort。
-- ---------------------------------------------------------------------------
CALL `add_index_if_absent`('orders', 'idx_orders_user_time', '`user_id`,`create_time`');
CALL `add_index_if_absent`('orders', 'idx_orders_seller_time', '`seller_id`,`create_time`');

DROP PROCEDURE IF EXISTS `add_index_if_absent`;

-- ---------------------------------------------------------------------------
-- 6. 刷新统计信息
--
-- 这一步不能省。新建索引后表级统计仍是旧的，优化器会在两个可选索引之间
-- 估错代价：实测它给「商品总数」挑中了只有 audit_status 一列的
-- idx_product_audit_time，把 19035 条索引项读出来再逐条过滤 is_on_shelf，
-- 查询从 7.15ms 退化到 52ms；ANALYZE 之后改选两列等值索引，降到 4.27ms。
-- ---------------------------------------------------------------------------
ANALYZE TABLE `product`, `orders`, `order_item`, `inventory`, `sys_notice`, `favorite`, `cart`, `evaluation`;

-- ---------------------------------------------------------------------------
-- 7. 校验：这些索引是否真的被选中
-- ---------------------------------------------------------------------------
SELECT '--- 前台商品列表 ---' AS '';
EXPLAIN SELECT p.`product_id` FROM `product` p
WHERE p.`audit_status` = 1 AND p.`is_on_shelf` = 1
ORDER BY p.`create_time` DESC, p.`product_id` DESC LIMIT 20;

SELECT '--- 后台商品审核列表 ---' AS '';
EXPLAIN SELECT p.`product_id` FROM `product` p
WHERE p.`audit_status` = 0 ORDER BY p.`create_time` DESC LIMIT 20;

SELECT '--- 买家订单列表 ---' AS '';
EXPLAIN SELECT o.`order_id` FROM `orders` o
WHERE o.`user_id` = 100 ORDER BY o.`create_time` DESC LIMIT 10;
