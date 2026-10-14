-- ============================================================================
-- 收尾补齐   2026-10-15
--
-- 一、权限：商家回复评价的接口此前在 permission 表里没有对应项，
--     启用按角色鉴权后它变成"谁都调不到"的孤儿接口。
-- 二、库存：6 件商品没有对应的 inventory 行，商家端的库存列表因此漏掉它们。
--     下单扣减是同时写 product 与 inventory 的，缺行会让两处数字对不上。
-- ============================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 一、权限目录 + 商家授权
-- ---------------------------------------------------------------------------

INSERT INTO `permission` (`permission_name`, `permission_code`, `url`, `method`, `parent_id`, `create_time`, `update_time`)
SELECT '评价回复', 'EVAL_REPLY', '/evaluations/{evaluationId}/reply', 'POST', 42, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `permission_code` FROM `permission`) x WHERE x.`permission_code` = 'EVAL_REPLY');

INSERT INTO `role_permission` (`role_id`, `permission_id`, `create_time`)
SELECT r.`role_id`, p.`permission_id`, NOW()
FROM `role` r
JOIN `permission` p ON p.`permission_code` = 'EVAL_REPLY'
WHERE r.`role_code` = 'MERCHANT'
  AND NOT EXISTS (SELECT 1 FROM (SELECT `role_id`, `permission_id` FROM `role_permission`) rp
                  WHERE rp.`role_id` = r.`role_id` AND rp.`permission_id` = p.`permission_id`);

-- ---------------------------------------------------------------------------
-- 二、SKU 补齐：为还没有默认 SKU 的商品建一条
--     after_product_insert 触发器会建默认 SKU，但触发器是后加的，
--     之前录入的商品没有补上；inventory.sku_id 有外键，缺 SKU 就立不了库存行。
-- ---------------------------------------------------------------------------

INSERT INTO `sku` (`product_id`, `sku_attribute`, `sku_value`, `price`, `stock`, `min_stock`, `sales`,
                   `create_time`, `update_time`)
SELECT p.`product_id`, '默认', '默认', p.`price`, p.`stock`, p.`min_stock`, 0, NOW(), NOW()
FROM `product` p
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `product_id` FROM `sku`) s WHERE s.`product_id` = p.`product_id`);

-- ---------------------------------------------------------------------------
-- 三、库存行补齐：为每个还没有 inventory 记录的商品建一行
--     命名与 product_type 的映射和 after_product_insert 触发器保持一致，
--     避免同一个商品因入口不同而出现两种写法。
-- ---------------------------------------------------------------------------

INSERT INTO `inventory` (`product_id`, `product_name`, `product_type`, `sku_id`, `sku_attribute`,
                         `sku_value`, `current_stock`, `min_stock`, `sales`,
                         `create_time`, `last_update_time`)
SELECT p.`product_id`,
       CONCAT(IFNULL(b.`brand_name`, ''), ' ', p.`model`),
       CASE p.`product_type` WHEN 2 THEN 'used' WHEN 3 THEN 'rental' ELSE 'new' END,
       (SELECT s.`sku_id` FROM `sku` s WHERE s.`product_id` = p.`product_id` ORDER BY s.`sku_id` LIMIT 1),
       '默认', '默认',
       p.`stock`, p.`min_stock`, 0,
       NOW(), NOW()
FROM `product` p
LEFT JOIN `brand` b ON b.`brand_id` = p.`brand`
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `product_id` FROM `inventory`) i WHERE i.`product_id` = p.`product_id`);

-- ---------------------------------------------------------------------------
-- 四、一致性校正：让 inventory.current_stock 与 product.stock 对齐
--     两处都存库存是既有设计，长时间运行后必然漂移；以 product 为准收敛一次。
--
--     inventory 上挂着 sync_inventory_stock_to_product 触发器（库存变化时回写
--     product），而这条一次性语句同时读了 product，MySQL 会以 1442 拒绝
--     （"已在同一语句中使用该表"）。因此先把触发器摘掉，校正完再装回去。
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS `sync_inventory_stock_to_product`;

UPDATE `inventory` i
JOIN `product` p ON p.`product_id` = i.`product_id`
SET i.`current_stock` = p.`stock`
WHERE i.`current_stock` <> p.`stock`;

DELIMITER //
CREATE TRIGGER `sync_inventory_stock_to_product`
AFTER UPDATE ON `inventory`
FOR EACH ROW
BEGIN
    -- 只在库存真的变化时同步，避免无意义的连带写入
    IF NEW.`current_stock` <> OLD.`current_stock` THEN
        UPDATE `product`
        SET `stock` = NEW.`current_stock`
        WHERE `product_id` = NEW.`product_id`;
    END IF;
END //
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 五、校验
-- ---------------------------------------------------------------------------

SELECT '无库存行的商品' AS 检查项, COUNT(*) AS 数量 FROM `product` p
WHERE NOT EXISTS (SELECT 1 FROM `inventory` i WHERE i.`product_id` = p.`product_id`);

SELECT '库存不一致' AS 检查项, COUNT(*) AS 数量 FROM `inventory` i
JOIN `product` p ON p.`product_id` = i.`product_id`
WHERE i.`current_stock` <> p.`stock`;

SELECT '评价回复权限' AS 检查项, COUNT(*) AS 数量 FROM `role_permission` rp
JOIN `permission` p ON p.`permission_id` = rp.`permission_id`
JOIN `role` r ON r.`role_id` = rp.`role_id`
WHERE p.`permission_code` = 'EVAL_REPLY' AND r.`role_code` = 'MERCHANT';
