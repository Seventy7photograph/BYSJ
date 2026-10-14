-- ============================================================================
-- 性能分析用的放大数据集（一次性工具，不属于业务数据）
--
-- 用法：
--   mysql -u root -p < 数据库文件/db_bysj_pets.sql            # 先建基准库
--   mysqldump ... db_bysj_pets | sed 's/db_bysj_pets/db_bysj_perf/g' | mysql ...
--   mysql -u root -p db_bysj_perf < scripts/perf/seed-perf-data.sql
--
-- 为什么需要它：开发库里只有 37 件商品、50 笔订单，优化器对任何小表都会选择
-- 全表扫描 —— 在这个体量上做 EXPLAIN 分析得不出任何结论。这份脚本把各表放大到
-- 万级，让索引是否被用上、排序是否落到文件排序，都能真实暴露出来。
-- ============================================================================

SET NAMES utf8mb4;
SET SESSION cte_max_recursion_depth = 200000;

-- ---------------------------------------------------------------------------
-- 用户：5000
-- ---------------------------------------------------------------------------
INSERT INTO `user` (`username`, `nickname`, `password`, `user_type`, `phone`, `email`,
                    `status`, `create_time`, `update_time`)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 5000
)
SELECT CONCAT('perf_', LPAD(n, 6, '0')),
       CONCAT('压测用户', n),
       '$2a$12$etCitOk68ONZtMTg6N25ZOXCVpWjqrBm4i7gtznXUD4TV1d5J7U5m',
       1,
       CONCAT('139', LPAD(n, 8, '0')),
       CONCAT('perf', n, '@example.com'),
       1,
       NOW(),
       NOW()
FROM seq;

-- ---------------------------------------------------------------------------
-- 商品：20000（product 上的 AFTER INSERT 触发器会连带建 SKU 与库存行）
-- ---------------------------------------------------------------------------
INSERT INTO `product` (`category_id`, `brand`, `model`, `product_type`, `condition`,
                       `original_price`, `price`, `stock`, `min_stock`, `seller_id`,
                       `audit_status`, `is_on_shelf`, `create_time`, `update_time`)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 20000
)
SELECT CASE n % 4 WHEN 0 THEN 1 WHEN 1 THEN 2 WHEN 2 THEN 3 ELSE 40 END,
       CASE n % 8 WHEN 0 THEN 11 WHEN 1 THEN 12 WHEN 2 THEN 13 WHEN 3 THEN 14
                  WHEN 4 THEN 21 WHEN 5 THEN 22 WHEN 6 THEN 23 ELSE 31 END,
       CONCAT('PERF-', LPAD(n, 6, '0'), ' 器材'),
       CASE n % 3 WHEN 0 THEN 1 WHEN 1 THEN 2 ELSE 3 END,
       CASE WHEN n % 3 = 1 THEN 85 + (n % 15) ELSE NULL END,
       ROUND(3000 + (n % 25000) + (n % 100) / 100, 2),
       ROUND(2000 + (n % 20000) + (n % 100) / 100, 2),
       20 + (n % 300),
       10,
       7 + (n % 3),
       CASE WHEN n % 20 = 0 THEN 0 ELSE 1 END,   -- audit_status：留出约 5% 待审商品
       CASE WHEN n % 7 = 0 THEN 0 ELSE 1 END,    -- is_on_shelf：留出未上架商品
       DATE_SUB(NOW(), INTERVAL (n % 720) DAY),
       DATE_SUB(NOW(), INTERVAL (n % 720) DAY)
FROM seq;

-- ---------------------------------------------------------------------------
-- 商品详情、图库与主图绑定
-- ---------------------------------------------------------------------------
INSERT INTO `sys_image` (`image_name`, `original_name`, `storage_path`, `storage_key`,
                         `file_size`, `file_type`, `width`, `height`, `upload_user_id`,
                         `upload_time`, `business_type`, `is_deleted`)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 20000
)
SELECT CONCAT('PERF-', LPAD(n, 6, '0')),
       CONCAT('perf-', n, '.png'),
       '/uploads/seed/00170959838740d1ad2e5e8f1ef3bb5b.png',
       'seed/00170959838740d1ad2e5e8f1ef3bb5b.png',
       10240, 'image/png', 800, 600, 7, NOW(), 'product', 0
FROM seq;

INSERT INTO `product_image` (`product_id`, `image_id`, `image_type`, `sort`, `is_deleted`)
SELECT p.`product_id`, si.`id`, 'main', 0, 0
FROM `product` p
JOIN `sys_image` si ON si.`image_name` = SUBSTRING_INDEX(p.`model`, ' ', 1)
WHERE p.`model` LIKE 'PERF-%';

INSERT INTO `product_detail` (`product_id`, `parameters`, `warranty_info`, `img_urls`,
                              `description`, `create_time`, `update_time`)
SELECT p.`product_id`,
       JSON_OBJECT('卡口', '尼康 Z', '型号', p.`model`),
       '全国联保一年',
       JSON_ARRAY(),
       CONCAT('性能分析用商品：', p.`model`),
       NOW(), NOW()
FROM `product` p
WHERE p.`model` LIKE 'PERF-%';

-- ---------------------------------------------------------------------------
-- 订单与订单项：30000 / 40000
-- ---------------------------------------------------------------------------
INSERT INTO `orders` (`order_no`, `user_id`, `seller_id`, `total_amount`, `shipping_fee`,
                      `pay_amount`, `order_status`, `payment_method`, `recipient`, `phone`,
                      `province`, `city`, `district`, `detail`, `create_time`, `update_time`)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 30000
)
SELECT CONCAT('PERF', LPAD(n, 14, '0')),
       (SELECT MIN(`user_id`) FROM `user` WHERE `username` LIKE 'perf\_%') + (n % 5000),
       7 + (n % 3),
       ROUND(2000 + (n % 20000) + (n % 100) / 100, 2),
       0.00,
       ROUND(2000 + (n % 20000) + (n % 100) / 100, 2),
       n % 10,
       'alipay',
       CONCAT('收件人', n),
       CONCAT('139', LPAD(n % 100000000, 8, '0')),
       '广东省', '广州市', '从化区',
       CONCAT('压测路 ', n, ' 号'),
       DATE_SUB(NOW(), INTERVAL (n % 720) DAY),
       DATE_SUB(NOW(), INTERVAL (n % 720) DAY)
FROM seq;

INSERT INTO `order_item` (`order_id`, `product_id`, `quantity`, `unit_price`, `deposit`,
                          `freight`, `item_status`, `lease_term`, `create_time`, `update_time`)
SELECT o.`order_id`,
       (SELECT MIN(`product_id`) FROM `product` WHERE `model` LIKE 'PERF-%') + (o.`order_id` % 20000),
       1 + (o.`order_id` % 3),
       o.`pay_amount`,
       0.00, 0.00, 1, 1, o.`create_time`, o.`update_time`
FROM `orders` o
WHERE o.`order_no` LIKE 'PERF%'
  AND o.`order_id` % 3 <> 0;

-- ---------------------------------------------------------------------------
-- 站内消息：100000（消息中心的读路径）
-- ---------------------------------------------------------------------------
INSERT INTO `sys_notice` (`user_id`, `content`, `notice_type`, `create_time`, `is_read`, `notice_status`)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 100000
)
SELECT (SELECT MIN(`user_id`) FROM `user` WHERE `username` LIKE 'perf\_%') + (n % 5000),
       CONCAT('压测通知 ', n, '：您的订单状态已更新。'),
       n % 5,
       DATE_SUB(NOW(), INTERVAL (n % 720) DAY),
       n % 2,
       0
FROM seq;

-- ---------------------------------------------------------------------------
-- 收藏与购物车
-- ---------------------------------------------------------------------------
INSERT INTO `favorite` (`user_id`, `product_id`, `create_time`)
SELECT u.`user_id`, p.`product_id`, NOW()
FROM `user` u
JOIN `product` p ON p.`product_id` % 1000 = u.`user_id` % 1000
WHERE u.`username` LIKE 'perf\_%' AND p.`model` LIKE 'PERF-%'
LIMIT 20000;

-- ---------------------------------------------------------------------------
-- 评价：10000（商品详情页的评价区）
-- ---------------------------------------------------------------------------
INSERT INTO `evaluation` (`order_id`, `product_id`, `user_id`, `seller_id`, `score`,
                          `quality_score`, `service_score`, `logistics_score`, `content`,
                          `img_urls`, `eval_status`, `create_time`, `update_time`)
SELECT o.`order_id`, oi.`product_id`, o.`user_id`, o.`seller_id`,
       4 + (o.`order_id` % 2), 4, 4, 4,
       CONCAT('压测评价内容 ', o.`order_id`),
       JSON_ARRAY(), 1, o.`create_time`, o.`create_time`
FROM `orders` o
JOIN `order_item` oi ON oi.`order_id` = o.`order_id`
WHERE o.`order_no` LIKE 'PERF%'
LIMIT 10000;

-- ---------------------------------------------------------------------------
-- 统计
-- ---------------------------------------------------------------------------
SELECT 'user' AS 表, COUNT(*) AS 行数 FROM `user` WHERE `username` LIKE 'perf\_%'
UNION ALL SELECT 'product', COUNT(*) FROM `product` WHERE `model` LIKE 'PERF-%'
UNION ALL SELECT 'sku', COUNT(*) FROM `sku` WHERE `product_id` IN (SELECT `product_id` FROM `product` WHERE `model` LIKE 'PERF-%')
UNION ALL SELECT 'inventory', COUNT(*) FROM `inventory` WHERE `product_id` IN (SELECT `product_id` FROM `product` WHERE `model` LIKE 'PERF-%')
UNION ALL SELECT 'product_image', COUNT(*) FROM `product_image`
UNION ALL SELECT 'orders', COUNT(*) FROM `orders`
UNION ALL SELECT 'order_item', COUNT(*) FROM `order_item`
UNION ALL SELECT 'sys_notice', COUNT(*) FROM `sys_notice`
UNION ALL SELECT 'evaluation', COUNT(*) FROM `evaluation`
UNION ALL SELECT 'favorite', COUNT(*) FROM `favorite`;
