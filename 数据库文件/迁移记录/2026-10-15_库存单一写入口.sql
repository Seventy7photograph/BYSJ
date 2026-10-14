-- ============================================================================
-- 库存改为单一写入口   2026-10-15
--
-- 背景：product.stock 与 inventory.current_stock 同时存着库存，并且是双向同步的
--   · 触发器 sync_inventory_stock_to_product：inventory 变化 → 回写 product
--   · 下单代码：直接写 product，再显式镜像到 inventory
-- 双向同步在 MySQL 里直接行不通：下单时要 UPDATE inventory 并 JOIN product 取值，
-- 而 inventory 上的触发器又要写 product，同一条语句里既读又写同一张表，
-- MySQL 以 1442 拒绝执行 —— 支付会直接失败（已实测）。
--
-- 定案：**product.stock 是唯一的权威库存**（前台列表、下单扣减都读它），
-- inventory.current_stock 是商家端的管理视图，由写入方显式镜像。
-- 因此去掉那个隐式回写的触发器，让数据流变成单向、可见。
-- ============================================================================

SET NAMES utf8mb4;

DROP TRIGGER IF EXISTS `sync_inventory_stock_to_product`;

-- 先把两边对齐一次，避免去掉触发器时留下不一致
UPDATE `inventory` i
JOIN `product` p ON p.`product_id` = i.`product_id`
SET i.`current_stock` = p.`stock`
WHERE i.`current_stock` <> p.`stock`;

SELECT '库存不一致' AS 检查项, COUNT(*) AS 数量 FROM `inventory` i
JOIN `product` p ON p.`product_id` = i.`product_id`
WHERE i.`current_stock` <> p.`stock`;

SELECT '剩余触发器' AS 检查项, COUNT(*) AS 数量 FROM information_schema.triggers
WHERE trigger_schema = DATABASE() AND trigger_name = 'sync_inventory_stock_to_product';
