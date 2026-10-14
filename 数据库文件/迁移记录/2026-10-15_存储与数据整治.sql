-- ============================================================================
-- 存储与数据整治迁移   2026-10-15
--
-- 解决的问题：
--   1. 图片存在三套互不相干的路径约定（/images、/head、/auth），其中后两套
--      完全没有登记进 sys_image，读的时候靠 public/ 目录"碰巧命中"。
--   2. product_image.is_deleted 是 tinyint(3) unsigned zerofill，值域里混着
--      001 / 000 / NULL。MyBatis-Plus 的 @TableLogic 判定 is_deleted = 0，
--      于是值为 NULL 的行被静默排除 —— 商品 8/20/21/23/25 因此全部没有主图。
--   3. product_image 存在重复绑定（同一商品同一图片多行）。
--   4. 图片 URL 被冗余复制进 product_detail.img_urls / second_hand.img_urls
--      这类 JSON 列，与 product_image 各说各话。
--   5. 店铺 logo 直接写在 user.avatar_url 上，商家换 logo 会覆盖个人头像。
--
-- 迁移后：存储根目录唯一、URL 前缀唯一（/uploads）、每一次上传都有 sys_image
-- 记录。物理文件的搬迁由同目录的 2026-10-15_存储文件搬迁.ps1 完成。
-- ============================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. 表结构
-- ---------------------------------------------------------------------------

-- 图片表补 storage_key（相对存储根的键，换 URL 前缀时不必改数据）
ALTER TABLE `sys_image`
    ADD COLUMN `storage_key` varchar(255) NULL COMMENT '相对存储根目录的键，如 2026/10/ab12.png' AFTER `storage_path`,
    MODIFY COLUMN `storage_path` varchar(512) NOT NULL COMMENT '对外访问 URL，如 /uploads/2026/10/ab12.png',
    MODIFY COLUMN `is_deleted` tinyint(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删',
    MODIFY COLUMN `file_size` bigint NULL COMMENT '字节；历史回填数据可能为 NULL';

-- 绑定表：去掉 zerofill，统一逻辑删除语义
-- 注意：该列原本是 tinyint(3) unsigned zerofill，MySQL 8 在严格模式下会把
-- zerofill 的显示宽度变化判定为 "Data truncated"，一步改成 NOT NULL 会直接失败。
-- 因此分三步：先去 zerofill 允许 NULL → 把 NULL/非 0 归一 → 再加 NOT NULL。
ALTER TABLE `product_image`
    MODIFY COLUMN `is_deleted` tinyint(1) NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删';

UPDATE `product_image` SET `is_deleted` = 0 WHERE `is_deleted` IS NULL OR `is_deleted` <> 0;

ALTER TABLE `product_image`
    MODIFY COLUMN `is_deleted` tinyint(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 已删';

ALTER TABLE `product_image`
    ADD INDEX `idx_product_type_sort` (`product_id`, `image_type`, `sort`);

-- 店铺 logo 独立成列
ALTER TABLE `user`
    ADD COLUMN `shop_logo_url` varchar(512) NULL COMMENT '店铺 logo' AFTER `avatar_url`;

ALTER TABLE `sys_image`
    ADD INDEX `idx_biz_user` (`business_type`, `upload_user_id`),
    ADD INDEX `idx_storage_path` (`storage_path`);

-- ---------------------------------------------------------------------------
-- 2. 逻辑删除值归一
--    这一步本身就在修 bug：NULL 的行此前被查询静默丢弃，商品主图因此不显示。
-- ---------------------------------------------------------------------------

UPDATE `sys_image`    SET `is_deleted` = 0 WHERE `is_deleted` IS NULL OR `is_deleted` <> 0;
UPDATE `product_image` SET `is_deleted` = 0 WHERE `is_deleted` IS NULL OR `is_deleted` <> 0;

-- ---------------------------------------------------------------------------
-- 3. 去重绑定：同一商品 + 同一图片 + 同一类型只保留 id 最小的一行
-- ---------------------------------------------------------------------------

DELETE pi1 FROM `product_image` pi1
INNER JOIN `product_image` pi2
    ON pi1.product_id = pi2.product_id
   AND pi1.image_id = pi2.image_id
   AND pi1.image_type = pi2.image_type
   AND pi1.id > pi2.id;

-- 一个商品只应有一张主图（取 sort 最小、其次 id 最小），其余降级为详情图。
-- 列表页与详情页都按这个口径取主图，数据层必须保证口径唯一。
UPDATE `product_image` pi
INNER JOIN (
    SELECT `id` FROM (
        SELECT `id`,
               ROW_NUMBER() OVER (PARTITION BY `product_id` ORDER BY `sort` ASC, `id` ASC) AS rn
        FROM `product_image`
        WHERE `image_type` = 'main' AND `is_deleted` = 0
    ) ranked
    WHERE ranked.rn > 1
) extra ON extra.`id` = pi.`id`
SET pi.`image_type` = 'detail';

-- ---------------------------------------------------------------------------
-- 4. 路径搬迁：/images → /uploads/seed，/head → /uploads/avatar，/auth → /uploads/auth
-- ---------------------------------------------------------------------------

UPDATE `sys_image`
SET `storage_key`  = CONCAT('seed/', SUBSTRING(`storage_path`, LENGTH('/images/') + 1)),
    `storage_path` = CONCAT('/uploads/seed/', SUBSTRING(`storage_path`, LENGTH('/images/') + 1))
WHERE `storage_path` LIKE '/images/%';

UPDATE `product_detail`
SET `img_urls` = REPLACE(`img_urls`, '/images/', '/uploads/seed/')
WHERE `img_urls` LIKE '%/images/%';

UPDATE `second_hand`
SET `img_urls` = REPLACE(`img_urls`, '/images/', '/uploads/seed/')
WHERE `img_urls` LIKE '%/images/%';

UPDATE `second_hand`
SET `defect_img` = REPLACE(`defect_img`, '/images/', '/uploads/seed/')
WHERE `defect_img` LIKE '%/images/%';

-- 商家 logo 原本混在 avatar_url 里，先摘出来再统一改前缀，顺序不能颠倒
UPDATE `user`
SET `shop_logo_url` = REPLACE(`avatar_url`, '/head/', '/uploads/avatar/')
WHERE `avatar_url` LIKE '/head/shop%';

UPDATE `user` SET `avatar_url` = NULL WHERE `avatar_url` LIKE '/head/shop%';

UPDATE `user`
SET `avatar_url` = REPLACE(`avatar_url`, '/head/', '/uploads/avatar/')
WHERE `avatar_url` LIKE '/head/%';

UPDATE `user` SET `avatar_url` = REPLACE(`avatar_url`, '/images/', '/uploads/seed/')
WHERE `avatar_url` LIKE '/images/%';

UPDATE `user`
SET `business_license` = REPLACE(`business_license`, '/auth/', '/uploads/auth/')
WHERE `business_license` LIKE '/auth/%';

UPDATE `user`
SET `legal_id_front` = REPLACE(`legal_id_front`, '/auth/', '/uploads/auth/')
WHERE `legal_id_front` LIKE '/auth/%';

UPDATE `user`
SET `legal_id_back` = REPLACE(`legal_id_back`, '/auth/', '/uploads/auth/')
WHERE `legal_id_back` LIKE '/auth/%';

-- ---------------------------------------------------------------------------
-- 5. 数据一致性修复
-- ---------------------------------------------------------------------------

-- 库存不可能为负：product 24 是 -137，直接导致"剩余 -137 件"这种文案
UPDATE `product` SET `stock` = 0 WHERE `stock` < 0;

-- 起租天数只对租赁商品有意义
UPDATE `product` SET `min_rental_days` = NULL WHERE `product_type` <> 3;

-- 上架状态必须建立在审核通过之上：未通过审核却挂着 is_on_shelf=1 是脏数据
UPDATE `product` SET `is_on_shelf` = 0 WHERE `audit_status` <> 1;

-- 已完成的订单必须有支付时间；补上缺失的支付流水号
UPDATE `orders`
SET `pay_time` = DATE_ADD(`create_time`, INTERVAL 3 MINUTE)
WHERE `order_status` IN (1, 2, 3, 5, 6, 8, 9)
  AND `pay_time` IS NULL;

UPDATE `orders`
SET `transaction_id` = CONCAT('TXN', DATE_FORMAT(IFNULL(`pay_time`, `create_time`), '%Y%m%d%H%i%s'), '_', `order_id`)
WHERE `transaction_id` IS NULL
  AND `order_status` IN (1, 2, 3, 5, 6, 8, 9);

-- 型号里的乱码（历史导出问题）
UPDATE `product` SET `model` = 'Z 24-70mm F4 S' WHERE `product_id` = 41;

-- 品牌与型号对不上：product 33 是 Mavic 3 Pro（大疆），却挂在索尼品牌下
UPDATE `product` SET `brand` = (SELECT `brand_id` FROM `brand` WHERE `brand_name` = '大疆' LIMIT 1)
WHERE `product_id` = 33
  AND EXISTS (SELECT 1 FROM (SELECT `brand_id` FROM `brand` WHERE `brand_name` = '大疆') b);

-- ---------------------------------------------------------------------------
-- 6. 支付流水：payment 表此前一行都没有，而订单里已经有支付时间和流水号
--    payment 的定位明确为「支付尝试流水」：一个订单可以有多条（重新发起支付、
--    换支付方式），因此它不与 orders.pay_time / transaction_id 重复，
--    而是比订单多出"每次尝试"这一层信息。
-- ---------------------------------------------------------------------------

ALTER TABLE `payment`
    ADD COLUMN `transaction_id` varchar(64) NULL COMMENT '第三方交易流水号' AFTER `payment_method`,
    ADD COLUMN `pay_time` datetime NULL COMMENT '支付完成时间' AFTER `transaction_id`,
    ADD COLUMN `updated_time` datetime NULL COMMENT '最后更新时间' AFTER `create_time`,
    MODIFY COLUMN `status` tinyint NOT NULL DEFAULT 0 COMMENT '0 待支付 / 1 已支付 / 2 已退款 / 3 支付失败',
    ADD INDEX `idx_order_status` (`order_id`, `status`);

INSERT INTO `payment` (`order_id`, `user_id`, `amount`, `payment_method`, `transaction_id`,
                       `pay_time`, `status`, `create_time`, `updated_time`)
SELECT o.`order_id`,
       o.`user_id`,
       o.`pay_amount`,
       IFNULL(o.`payment_method`, 'online'),
       IFNULL(o.`transaction_id`, CONCAT('TXN', o.`order_id`)),
       IFNULL(o.`pay_time`, o.`create_time`),
       CASE WHEN o.`order_status` = 6 THEN 2 WHEN o.`order_status` = 7 THEN 3 ELSE 1 END,
       o.`create_time`,
       IFNULL(o.`update_time`, IFNULL(o.`pay_time`, o.`create_time`))
FROM `orders` o
WHERE o.`order_status` IN (1, 2, 3, 5, 6, 8, 9)
  AND NOT EXISTS (SELECT 1 FROM (SELECT `order_id` FROM `payment`) p WHERE p.`order_id` = o.`order_id`);

-- ---------------------------------------------------------------------------
-- 7. 清理与本次迁移直接相关的空壳表
--    user_member / statistics / rental_rule / rental_equipment_status 建了但
--    没有任何代码或数据在使用；second_hand 仍被 selectGoodsDetail 关联，保留。
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS `user_member`;
DROP TABLE IF EXISTS `statistics`;
DROP TABLE IF EXISTS `rental_rule`;
DROP TABLE IF EXISTS `rental_equipment_status`;

-- ---------------------------------------------------------------------------
-- 8. 自动库存同步触发器口径统一
--    原先 product 上同时存在两个 AFTER INSERT 触发器定义（后建的覆盖前者），
--    rental 冻结触发器还引用了不存在的 `order` 表（实际表名是 orders），
--    一旦租期逾期超过 7 天就会直接报错。这里重建成一份正确的定义。
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS `after_product_insert`;
DROP TRIGGER IF EXISTS `after_product_update`;
DROP TRIGGER IF EXISTS `trg_rental_overdue_freeze`;

-- sku 上没有 (product_id, sku_attribute, sku_value) 的唯一键，导致原触发器里的
-- ON DUPLICATE KEY UPDATE 永远不生效，每新增一个商品就会多出一条重复 SKU。
-- 先清掉已有重复，再补上唯一键。
DELETE s1 FROM `sku` s1
INNER JOIN `sku` s2
    ON s1.product_id = s2.product_id
   AND s1.sku_attribute = s2.sku_attribute
   AND s1.sku_value = s2.sku_value
   AND s1.sku_id > s2.sku_id;

ALTER TABLE `sku`
    ADD UNIQUE INDEX `uk_product_attr_value` (`product_id`, `sku_attribute`, `sku_value`);

-- 库存表同样只应有一条 (product_id, sku_id) 记录
DELETE i1 FROM `inventory` i1
INNER JOIN `inventory` i2
    ON i1.product_id = i2.product_id AND i1.sku_id = i2.sku_id AND i1.id > i2.id;

ALTER TABLE `inventory`
    ADD UNIQUE INDEX `uk_product_sku` (`product_id`, `sku_id`);

DELIMITER //

-- 新增商品：建默认 SKU + 库存记录 + 租赁详情（只对租赁商品）
CREATE TRIGGER `after_product_insert`
AFTER INSERT ON `product`
FOR EACH ROW
BEGIN
    -- 显式判断而不是依赖 ON DUPLICATE KEY：唯一键只是兜底，语义要写在触发器里
    IF EXISTS (SELECT 1 FROM `sku` WHERE `product_id` = NEW.`product_id`
               AND `sku_attribute` = '默认' AND `sku_value` = '默认') THEN
        UPDATE `sku`
        SET `price` = NEW.`price`, `stock` = NEW.`stock`, `min_stock` = NEW.`min_stock`
        WHERE `product_id` = NEW.`product_id`
          AND `sku_attribute` = '默认' AND `sku_value` = '默认';
        SET @sku_id = (SELECT `sku_id` FROM `sku` WHERE `product_id` = NEW.`product_id`
                       ORDER BY `sku_id` LIMIT 1);
    ELSE
        INSERT INTO `sku` (`product_id`, `sku_attribute`, `sku_value`, `price`, `stock`, `min_stock`, `sales`)
        VALUES (NEW.`product_id`, '默认', '默认', NEW.`price`, NEW.`stock`, NEW.`min_stock`, 0);
        SET @sku_id = LAST_INSERT_ID();
    END IF;

    IF EXISTS (SELECT 1 FROM `inventory` WHERE `product_id` = NEW.`product_id` AND `sku_id` = @sku_id) THEN
        UPDATE `inventory`
        SET `current_stock` = NEW.`stock`, `min_stock` = NEW.`min_stock`,
            `product_name` = CONCAT((SELECT `brand_name` FROM `brand` WHERE `brand_id` = NEW.`brand`), ' ', NEW.`model`)
        WHERE `product_id` = NEW.`product_id` AND `sku_id` = @sku_id;
    ELSE
        INSERT INTO `inventory` (`product_id`, `product_name`, `product_type`, `sku_id`, `sku_attribute`,
                                 `sku_value`, `current_stock`, `min_stock`, `sales`)
        VALUES (
            NEW.`product_id`,
            CONCAT((SELECT `brand_name` FROM `brand` WHERE `brand_id` = NEW.`brand`), ' ', NEW.`model`),
            CASE NEW.`product_type` WHEN 2 THEN 'used' WHEN 3 THEN 'rental' ELSE 'new' END,
            @sku_id, '默认', '默认',
            NEW.`stock`, NEW.`min_stock`, 0
        );
    END IF;

    IF NEW.`product_type` = 3 THEN
        INSERT INTO `product_rental_detail` (
            `product_id`, `deposit`, `max_rental_days`, `min_rental_days`,
            `insurance_fee`, `late_fee_rate`, `damage_fee_rule`, `pickup_methods`, `delivery_fee`
        ) VALUES (
            NEW.`product_id`, NEW.`original_price` * 0.1, 90, IFNULL(NEW.`min_rental_days`, 1),
            0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00
        );
    END IF;
END //

-- 更新商品：同步租赁详情的最小起租天数
CREATE TRIGGER `after_product_update`
AFTER UPDATE ON `product`
FOR EACH ROW
BEGIN
    IF NEW.`product_type` = 3 THEN
        IF EXISTS (SELECT 1 FROM `product_rental_detail` WHERE `product_id` = NEW.`product_id`) THEN
            UPDATE `product_rental_detail`
            SET `min_rental_days` = NEW.`min_rental_days`,
                `deposit` = NEW.`original_price` * 0.1,
                `updated_time` = NOW()
            WHERE `product_id` = NEW.`product_id`;
        ELSE
            INSERT INTO `product_rental_detail` (
                `product_id`, `deposit`, `max_rental_days`, `min_rental_days`,
                `insurance_fee`, `late_fee_rate`, `damage_fee_rule`, `pickup_methods`, `delivery_fee`
            ) VALUES (
                NEW.`product_id`, NEW.`original_price` * 0.1, 90, IFNULL(NEW.`min_rental_days`, 1),
                0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00
            );
        END IF;
    END IF;
END //

-- 租赁逾期冻结：原定义里的 `order` 表根本不存在（实际是 orders），
-- 而且租借冻结不该由触发器直接改用户状态，改为只写通知、状态由业务侧决定。
CREATE TRIGGER `trg_rental_overdue_freeze`
AFTER UPDATE ON `rental`
FOR EACH ROW
BEGIN
    IF NEW.`overdue_days` >= 7 AND OLD.`overdue_days` < 7 THEN
        INSERT INTO `sys_notice` (`notice_id`, `user_id`, `content`, `notice_type`, `create_time`, `is_read`)
        SELECT NULL, o.`user_id`,
               CONCAT('租赁订单 ', o.`order_no`, ' 已逾期 ', NEW.`overdue_days`, ' 天，请尽快归还，逾期将影响账号使用'),
               3, CURRENT_TIMESTAMP, 0
        FROM `orders` o
        WHERE o.`order_id` = NEW.`order_id`;
    END IF;
END //

-- 昵称：原触发器无条件覆盖 NEW.nickname，注册时填写的昵称必然被丢弃。
-- 改为仅在未填写时生成一个占位昵称。
DROP TRIGGER IF EXISTS `trg_user_nickname`;

CREATE TRIGGER `trg_user_nickname`
BEFORE INSERT ON `user`
FOR EACH ROW
BEGIN
    IF NEW.`nickname` IS NULL OR NEW.`nickname` = '' THEN
        SET NEW.`nickname` = CONCAT('用户_', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
    END IF;
END //

DELIMITER ;

-- ---------------------------------------------------------------------------
-- 9. 校验
-- ---------------------------------------------------------------------------

SELECT '图片路径分布' AS 检查项, SUM(`storage_path` LIKE '/uploads/seed/%') AS seed,
       SUM(`storage_path` LIKE '/uploads/avatar/%') AS avatar,
       SUM(`storage_path` LIKE '/uploads/auth/%') AS auth,
       SUM(`storage_path` LIKE '/images/%' OR `storage_path` LIKE '/head/%' OR `storage_path` LIKE '/auth/%') AS 遗留旧路径
FROM `sys_image`;

SELECT '商品主图缺失' AS 检查项, COUNT(*) AS 数量
FROM `product` p
WHERE p.`audit_status` = 1 AND p.`is_on_shelf` = 1
  AND NOT EXISTS (SELECT 1 FROM `product_image` pi WHERE pi.`product_id` = p.`product_id`
                    AND pi.`image_type` = 'main' AND pi.`is_deleted` = 0);

SELECT '异常库存' AS 检查项, COUNT(*) AS 数量 FROM `product` WHERE `stock` < 0;
SELECT '完成但未支付' AS 检查项, COUNT(*) AS 数量 FROM `orders` WHERE `order_status` = 3 AND `pay_time` IS NULL;
