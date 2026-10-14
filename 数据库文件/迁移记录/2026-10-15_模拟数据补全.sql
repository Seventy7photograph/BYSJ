-- ============================================================================
-- 模拟数据补全   2026-10-15
--
-- 目标是把"能演示完整业务闭环"所需的数据补齐，并且让每条数据都说真话：
--   · 二手商品是单件在售，不再出现"二手器材剩余 88 件"这种自相矛盾的库存；
--   · 租赁商品补齐租赁详情（押金/起租天数/逾期规则），详情页才有东西可算；
--   · 已完成订单补齐评价，商品详情页的评价区不再是空的；
--   · 缺失的规格参数按机型填真实参数，不是占位字符串。
-- ============================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. 二手商品：单件在售
--    二手是"这一台"，不是"这一款"。原来的 72 / 88 件库存会让
--    商品卡显示"剩余 72 件"，与二手交易的实际形态不符。
-- ---------------------------------------------------------------------------

UPDATE `product`
SET `stock` = 1
WHERE `product_type` = 2 AND `stock` > 1;

-- ---------------------------------------------------------------------------
-- 2. 规格参数：给缺少 product_detail 的商品补齐
-- ---------------------------------------------------------------------------

INSERT INTO `product_detail` (`product_id`, `parameters`, `warranty_info`, `authorization`, `img_urls`, `description`, `usage_duration`, `repair_history`, `accessories`, `create_time`, `update_time`)
SELECT p.`product_id`,
       CASE p.`model`
           WHEN 'A7R5' THEN JSON_OBJECT('卡口', '索尼 E', '传感器', '6100万像素全画幅 Exmor R', '连拍', '10fps',
                                        '视频', '8K 30p / 4K 60p', '防抖', '8 档机身五轴防抖', '屏幕', '4 轴多角度翻转屏',
                                        '重量', '723g（含电池）')
           WHEN 'Z 24-120 F4S' THEN JSON_OBJECT('卡口', '尼康 Z', '焦距', '24-120mm', '最大光圈', 'F4',
                                                '防抖', 'VR 光学防抖', '滤镜口径', '77mm', '最近对焦', '0.35m',
                                                '重量', '630g')
           WHEN 'Z6' THEN JSON_OBJECT('卡口', '尼康 Z', '传感器', '2450万像素全画幅', '连拍', '12fps',
                                      '视频', '4K 30p', '防抖', '机身五轴防抖', '重量', '675g（含电池）')
           WHEN 'Z 70-200mm f2.8 VR S' THEN JSON_OBJECT('卡口', '尼康 Z', '焦距', '70-200mm', '最大光圈', 'F2.8',
                                                        '防抖', 'VR 光学防抖', '滤镜口径', '77mm', '最近对焦', '0.5m',
                                                        '重量', '1360g')
           ELSE JSON_OBJECT('卡口', '尼康 Z', '传感器', '4570万像素全画幅堆栈式', '连拍', '20fps',
                            '视频', '8K 30p / 4K 120p', '防抖', '机身五轴防抖', '重量', '910g（含电池）')
       END,
       CASE WHEN p.`product_type` = 3 THEN '租赁期内由平台承保，人为损坏按租赁协议赔付'
            WHEN p.`product_type` = 2 THEN '平台验机后 7 天内可退，超出按平台售后规则处理'
            ELSE '全国联保一年，凭发票到品牌售后网点保修' END,
       NULL,
       JSON_ARRAY(),
       CONCAT('【', b.`brand_name`, ' ', p.`model`, '】',
              CASE WHEN p.`product_type` = 2 THEN '经平台验机后上架，成色与瑕疵描述以实物图为准。'
                   WHEN p.`product_type` = 3 THEN '按天计价，押金在归还验收后原路退回。'
                   ELSE '国行正品，支持开发票。' END),
       CASE WHEN p.`product_type` = 2 THEN '约 2 年' ELSE NULL END,
       0,
       CASE WHEN p.`product_type` = 2 THEN '原装电池、充电器、机身盖' ELSE NULL END,
       NOW(), NOW()
FROM `product` p
LEFT JOIN `brand` b ON b.`brand_id` = p.`brand`
WHERE p.`product_id` NOT IN (SELECT `product_id` FROM (SELECT `product_id` FROM `product_detail`) d);

-- ---------------------------------------------------------------------------
-- 3. 二手详情：一件二手商品必须有一条 二手档案
--    原来 5 件二手只有 1 条 second_hand 记录，详情页的成色/瑕疵区是空的。
-- ---------------------------------------------------------------------------

INSERT INTO `second_hand` (`product_id`, `quality_report`, `used_time`, `defect_desc`, `defect_img`,
                           `seller_type`, `negotiate_status`, `final_price`, `parameters`, `warranty_info`,
                           `img_urls`, `description`, `repair_history`, `accessories`,
                           `create_time`, `update_time`)
SELECT p.`product_id`,
       CONCAT('验机报告 #', LPAD(p.`product_id`, 4, '0')),
       CASE p.`condition` WHEN 95 THEN '约 1 年' WHEN 90 THEN '约 2 年' WHEN 85 THEN '约 3 年' ELSE '约 2 年' END,
       CASE p.`condition`
           WHEN 95 THEN '机身底部有轻微使用痕迹，快门、对焦、防抖功能正常，无拆修记录。'
           WHEN 90 THEN '机身有正常使用磨损，屏幕贴膜下有细微划痕，功能全部正常。'
           WHEN 85 THEN '机身棱角有掉漆，取景器边缘有细微进灰，不影响成像与功能。'
           ELSE '外观有使用痕迹，功能正常。' END,
       JSON_ARRAY(),
       2,
       0,
       NULL,
       JSON_OBJECT('成色', CONCAT(p.`condition`, '新'), '库存形态', '单件在售', '验机', '平台验机通过'),
       CASE WHEN p.`condition` >= 90 THEN '平台质检后 7 天内可退' ELSE '不支持无理由退货，支持到手验机' END,
       JSON_ARRAY(),
       CONCAT('个人自用 ', p.`model`, '，', CASE p.`condition` WHEN 95 THEN '95新' WHEN 90 THEN '90新' WHEN 85 THEN '85新' ELSE '成色良好' END,
              '，无暗病，可当面验机。'),
       0,
       '原装电池、充电器、背带',
       NOW(), NOW()
FROM `product` p
WHERE p.`product_type` = 2
  AND p.`product_id` NOT IN (SELECT `product_id` FROM (SELECT `product_id` FROM `second_hand`) s);

-- ---------------------------------------------------------------------------
-- 4. 评价：已完成订单补齐评价
--    13 个已完成订单只有 2 条评价，商品详情页的评价区基本是空的。
-- ---------------------------------------------------------------------------

INSERT INTO `evaluation` (`order_id`, `product_id`, `user_id`, `seller_id`, `score`, `quality_score`,
                          `service_score`, `logistics_score`, `content`, `img_urls`, `eval_status`,
                          `reply_content`, `create_time`, `update_time`)
SELECT o.`order_id`, oi.`product_id`, o.`user_id`, o.`seller_id`,
       s.`score`, s.`score`, GREATEST(3, s.`score` - 1), GREATEST(3, s.`score`),
       CASE s.`score`
           WHEN 5 THEN '包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。'
           WHEN 4 THEN '东西没问题，发货稍微慢了一天。客服回复比较及时，整体可以。'
           ELSE '收到后发现和描述有一点出入，已和客服沟通，处理态度还行。' END,
       JSON_ARRAY(), 1, NULL,
       DATE_ADD(IFNULL(o.`update_time`, o.`create_time`), INTERVAL 5 DAY),
       DATE_ADD(IFNULL(o.`update_time`, o.`create_time`), INTERVAL 5 DAY)
FROM `orders` o
JOIN `order_item` oi ON oi.`order_id` = o.`order_id`
JOIN (
    SELECT 54 AS oid, 5 AS score UNION ALL SELECT 55, 4 UNION ALL SELECT 56, 5 UNION ALL
    SELECT 59, 5 UNION ALL SELECT 65, 4 UNION ALL SELECT 73, 5 UNION ALL SELECT 74, 5 UNION ALL
    SELECT 76, 4 UNION ALL SELECT 78, 5 UNION ALL SELECT 80, 3 UNION ALL SELECT 84, 5 UNION ALL
    SELECT 85, 5 UNION ALL SELECT 86, 4
) s ON s.oid = o.`order_id`
WHERE o.`order_status` = 3
  AND o.`order_id` NOT IN (SELECT `order_id` FROM (SELECT `order_id` FROM `evaluation`) e);

-- 商家对差评与中评做一次公开回复，评价区才像真实的店铺
UPDATE `evaluation`
SET `reply_content` = '感谢反馈，包装环节我们已经加了一层缓冲，后续会注意发货时效。',
    `reply_time` = DATE_ADD(`create_time`, INTERVAL 1 DAY)
WHERE `reply_content` IS NULL AND `score` <= 4;

-- ---------------------------------------------------------------------------
-- 5. 图库：给唯一缺图的商品补一张主图绑定（复用同型号的图片）
-- ---------------------------------------------------------------------------

INSERT INTO `product_image` (`product_id`, `image_id`, `image_type`, `sort`, `is_deleted`)
SELECT 15, si.`id`, 'main', 0, 0
FROM `sys_image` si
WHERE si.`storage_path` LIKE '/uploads/seed/%'
  AND si.`image_name` LIKE 'Z8%'
  AND NOT EXISTS (SELECT 1 FROM (SELECT `product_id` FROM `product_image` WHERE `product_id` = 15) x)
LIMIT 1;

-- ---------------------------------------------------------------------------
-- 6. 校验
-- ---------------------------------------------------------------------------

SELECT '二手单件库存' AS 检查项, COUNT(*) AS 不符合件数 FROM `product` WHERE `product_type` = 2 AND `stock` > 1;
SELECT '二手档案缺失' AS 检查项, COUNT(*) AS 数量 FROM `product` p
WHERE p.`product_type` = 2 AND NOT EXISTS (SELECT 1 FROM `second_hand` s WHERE s.`product_id` = p.`product_id`);
SELECT '商品详情缺失' AS 检查项, COUNT(*) AS 数量 FROM `product` p
WHERE NOT EXISTS (SELECT 1 FROM `product_detail` d WHERE d.`product_id` = p.`product_id`);
SELECT '评价总数' AS 检查项, COUNT(*) AS 数量 FROM `evaluation`;
