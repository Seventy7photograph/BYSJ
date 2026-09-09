-- 摄影器材系统模拟数据SQL脚本
-- 生成时间：2026-04-10
-- 执行说明：
-- 1. 先执行品牌和分类插入语句
-- 2. 再执行商品相关插入语句
-- 3. 所有数据都关联到seller_id=8的账户

-- 开始事务
START TRANSACTION;

-- 插入品牌记录
-- 新增品牌：AKASO、Autel、GoPro、Insta360、Leica、Panasonic、Parrot、Sigma、Skydio、Tamron
INSERT INTO `brand` (`brand_name`, `parent_id`, `category_code`, `sort`, `status`, `description`, `create_by`, `create_time`, `update_by`, `update_time`)
VALUES
-- 相机品牌
('AKASO', 1, 'AKASO', 1, 1, '运动相机品牌', 1, NOW(), 1, NOW()),
('Autel', 1, 'AUTEL', 1, 1, '无人机品牌', 1, NOW(), 1, NOW()),
('GoPro', 1, 'GOPRO', 1, 1, '运动相机品牌', 1, NOW(), 1, NOW()),
('Insta360', 1, 'INSTA360', 1, 1, '全景相机品牌', 1, NOW(), 1, NOW()),
('Leica', 1, 'LEICA', 1, 1, '高端相机品牌', 1, NOW(), 1, NOW()),
('Panasonic', 1, 'PANASONIC', 1, 1, '相机品牌', 1, NOW(), 1, NOW()),

-- 镜头品牌
('Sigma', 2, 'SIGMA', 1, 1, '镜头品牌', 1, NOW(), 1, NOW()),
('Tamron', 2, 'TAMRON', 1, 1, '镜头品牌', 1, NOW(), 1, NOW()),

-- 无人机品牌
('Parrot', 3, 'PARROT', 1, 1, '无人机品牌', 1, NOW(), 1, NOW()),
('Skydio', 3, 'SKYDIO', 1, 1, '无人机品牌', 1, NOW(), 1, NOW());

-- 插入商品分类记录
-- 新增分类：运动相机、全景相机、穿越机
INSERT INTO `product_category` (`category_name`, `parent_id`, `category_code`, `sort`, `status`, `description`, `create_by`, `create_time`, `update_by`, `update_time`)
VALUES
('全景相机', 1, 'PANORAMIC_CAM', 1, 1, '360度全景相机', 1, NOW(), 1, NOW()),
('穿越机', 3, 'DRONE_RACING', 1, 1, '竞速无人机', 1, NOW(), 1, NOW());

-- 插入商品记录 - 全新商品
INSERT INTO `product` (`category_id`, `brand`, `model`, `product_type`, `condition`, `original_price`, `price`, `min_rental_days`, `stock`, `seller_id`, `audit_status`, `reject_reason`, `is_on_shelf`, `create_time`, `update_time`, `min_stock`, `color`)
VALUES
-- 尼康相机
(11, 11, 'Z 8', 1, NULL, 25999.00, 18999.00, NULL, 50, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(11, 11, 'Z 9', 1, NULL, 35999.00, 29999.00, NULL, 30, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(12, 11, 'D850', 1, NULL, 12999.00, 9999.00, NULL, 20, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),

-- 索尼相机
(11, 12, 'A7R V', 1, NULL, 24999.00, 21999.00, NULL, 40, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(11, 12, 'A7M4', 1, NULL, 16999.00, 14999.00, NULL, 60, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(11, 12, 'A6700', 1, NULL, 8999.00, 7999.00, NULL, 80, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),

-- 佳能相机
(11, 13, 'EOS R5', 1, NULL, 25999.00, 22999.00, NULL, 35, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(11, 13, 'EOS R6 Mark II', 1, NULL, 16999.00, 14999.00, NULL, 50, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),

-- 富士相机
(11, 14, 'X-T5', 1, NULL, 13999.00, 11999.00, NULL, 45, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(11, 14, 'X-H2S', 1, NULL, 16999.00, 14999.00, NULL, 30, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),

-- 徕卡相机
(11, (SELECT brand_id FROM brand WHERE brand_name = 'Leica'), 'Q2', 1, NULL, 34999.00, 29999.00, NULL, 10, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),

-- 松下相机
(11, (SELECT brand_id FROM brand WHERE brand_name = 'Panasonic'), 'S5 II', 1, NULL, 14999.00, 12999.00, NULL, 40, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),

-- 运动相机
(13, (SELECT brand_id FROM brand WHERE brand_name = 'GoPro'), 'HERO12 Black', 1, NULL, 3999.00, 3499.00, NULL, 100, 8, 1, NULL, 1, NOW(), NOW(), 20, '黑色'),
(13, (SELECT brand_id FROM brand WHERE brand_name = 'AKASO'), 'V50X', 1, NULL, 1299.00, 999.00, NULL, 150, 8, 1, NULL, 1, NOW(), NOW(), 30, '黑色'),
(14, (SELECT brand_id FROM brand WHERE brand_name = 'Insta360'), 'X3', 1, NULL, 3499.00, 2999.00, NULL, 80, 8, 1, NULL, 1, NOW(), NOW(), 15, '黑色'),

-- 尼康镜头
(21, 21, 'Z 24-70mm F2.8 S', 1, NULL, 12999.00, 10999.00, NULL, 30, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(21, 21, 'Z 70-200mm f2.8 VR S', 1, NULL, 14999.00, 12999.00, NULL, 25, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(22, 21, 'Z 50mm F1.8 S', 1, NULL, 3999.00, 3499.00, NULL, 50, 8, 1, NULL, 1, NOW(), NOW(), 15, '黑色'),

-- 索尼镜头
(21, 22, 'FE 24-70mm F2.8 GM II', 1, NULL, 15999.00, 13999.00, NULL, 25, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(21, 22, 'FE 70-200mm F2.8 GM OSS II', 1, NULL, 17999.00, 15999.00, NULL, 20, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(22, 22, 'FE 85mm F1.4 GM', 1, NULL, 8999.00, 7999.00, NULL, 35, 8, 1, NULL, 1, NOW(), NOW(), 15, '黑色'),

-- 佳能镜头
(21, 23, 'RF 24-70mm F2.8 L IS USM', 1, NULL, 13999.00, 11999.00, NULL, 25, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(21, 23, 'RF 70-200mm F2.8 L IS USM', 1, NULL, 15999.00, 13999.00, NULL, 20, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),

-- 适马镜头
(21, (SELECT brand_id FROM brand WHERE brand_name = 'Sigma'), '24-70mm F2.8 DG DN Art', 1, NULL, 8999.00, 7999.00, NULL, 30, 8, 1, NULL, 1, NOW(), NOW(), 15, '黑色'),
(22, (SELECT brand_id FROM brand WHERE brand_name = 'Sigma'), '35mm F1.4 DG DN Art', 1, NULL, 5999.00, 4999.00, NULL, 40, 8, 1, NULL, 1, NOW(), NOW(), 20, '黑色'),

-- 腾龙镜头
(21, (SELECT brand_id FROM brand WHERE brand_name = 'Tamron'), '28-75mm F2.8 Di III VXD G2', 1, NULL, 6999.00, 5999.00, NULL, 35, 8, 1, NULL, 1, NOW(), NOW(), 15, '黑色'),
(21, (SELECT brand_id FROM brand WHERE brand_name = 'Tamron'), '70-180mm F2.8 Di III VC VXD', 1, NULL, 7999.00, 6999.00, NULL, 30, 8, 1, NULL, 1, NOW(), NOW(), 15, '黑色'),

-- 无人机
(31, 37, 'Mini 4 Pro', 1, NULL, 4799.00, 4299.00, NULL, 40, 8, 1, NULL, 1, NOW(), NOW(), 10, '白色'),
(32, 37, 'Air 3', 1, NULL, 6799.00, 5999.00, NULL, 30, 8, 1, NULL, 1, NOW(), NOW(), 10, '灰色'),
(33, 37, 'Mavic 3 Pro', 1, NULL, 13888.00, 11999.00, NULL, 20, 8, 1, NULL, 1, NOW(), NOW(), 5, '灰色'),
(35, 37, 'Avata 2', 1, NULL, 3999.00, 3499.00, NULL, 35, 8, 1, NULL, 1, NOW(), NOW(), 10, '黑色'),
(36, (SELECT brand_id FROM brand WHERE brand_name = 'Autel'), 'EVO Lite', 1, NULL, 8999.00, 7999.00, NULL, 25, 8, 1, NULL, 1, NOW(), NOW(), 8, '白色'),
(36, (SELECT brand_id FROM brand WHERE brand_name = 'Parrot'), 'Anafi USA', 1, NULL, 14999.00, 12999.00, NULL, 15, 8, 1, NULL, 1, NOW(), NOW(), 5, '绿色'),
(36, (SELECT brand_id FROM brand WHERE brand_name = 'Skydio'), 'X10', 1, NULL, 29999.00, 24999.00, NULL, 10, 8, 1, NULL, 1, NOW(), NOW(), 3, '黑色');

-- 插入商品记录 - 二手商品
INSERT INTO `product` (`category_id`, `brand`, `model`, `product_type`, `condition`, `original_price`, `price`, `min_rental_days`, `stock`, `seller_id`, `audit_status`, `reject_reason`, `is_on_shelf`, `create_time`, `update_time`, `min_stock`, `color`)
VALUES
-- 二手相机
(11, 11, 'Z6', 2, 95, 12999.00, 5555.00, NULL, 5, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(11, 12, 'A7M3', 2, 90, 14999.00, 7999.00, NULL, 8, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(11, 13, 'EOS R', 2, 85, 15999.00, 6999.00, NULL, 6, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(13, (SELECT brand_id FROM brand WHERE brand_name = 'GoPro'), 'HERO10 Black', 2, 90, 3499.00, 1999.00, NULL, 10, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),

-- 二手镜头
(21, 21, 'Z 24-120mm F4 S', 2, 95, 8999.00, 4999.00, NULL, 4, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(21, 22, 'FE 24-70mm F2.8 GM', 2, 90, 12999.00, 6999.00, NULL, 3, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(22, 21, 'Z 50mm F1.8 S', 2, 95, 3999.00, 1999.00, NULL, 6, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),

-- 二手无人机
(31, 37, 'Mini 3', 2, 90, 3799.00, 2499.00, NULL, 5, 8, 1, NULL, 1, NOW(), NOW(), 5, '白色'),
(32, 37, 'Air 2S', 2, 85, 5999.00, 3499.00, NULL, 3, 8, 1, NULL, 1, NOW(), NOW(), 5, '灰色');

-- 插入商品记录 - 租赁商品
INSERT INTO `product` (`category_id`, `brand`, `model`, `product_type`, `condition`, `original_price`, `price`, `min_rental_days`, `stock`, `seller_id`, `audit_status`, `reject_reason`, `is_on_shelf`, `create_time`, `update_time`, `min_stock`, `color`)
VALUES
-- 租赁相机
(11, 11, 'Z6II', 3, NULL, 13999.00, 120.00, 3, 10, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(11, 12, 'A7R5', 3, NULL, 24999.00, 180.00, 3, 8, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(11, 13, 'EOS R5', 3, NULL, 25999.00, 200.00, 3, 6, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),

-- 租赁镜头
(21, 21, 'Z 70-200mm f2.8 VR S', 3, NULL, 14999.00, 100.00, 3, 8, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(21, 22, 'FE 70-200mm F2.8 GM OSS II', 3, NULL, 17999.00, 120.00, 3, 6, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),
(22, 21, 'Z 50mm F1.8 S', 3, NULL, 3999.00, 30.00, 2, 12, 8, 1, NULL, 1, NOW(), NOW(), 5, '黑色'),

-- 租赁无人机
(31, 37, 'Mini 4 Pro', 3, NULL, 4799.00, 50.00, 2, 10, 8, 1, NULL, 1, NOW(), NOW(), 5, '白色'),
(32, 37, 'Air 3', 3, NULL, 6799.00, 70.00, 2, 8, 8, 1, NULL, 1, NOW(), NOW(), 5, '灰色'),
(33, 37, 'Mavic 3 Pro', 3, NULL, 13888.00, 150.00, 3, 5, 8, 1, NULL, 1, NOW(), NOW(), 3, '灰色');

-- 插入商品详情记录
-- 全新商品详情
INSERT INTO `product_detail` (`product_id`, `parameters`, `warranty_info`, `authorization`, `img_urls`, `description`, `usage_duration`, `repair_history`, `accessories`, `create_time`, `update_time`)
VALUES
-- 尼康 Z 8
((SELECT product_id FROM product WHERE model = 'Z 8' AND product_type = 1), 
 '{"类型": "可换镜头数码相机", "总像素数": "约4,571万", "有效像素": "约4571万", "镜头卡口": "尼康Z卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "FX"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/00655cd317064682a866ba08d472dd88.png", "/images/011ee0a7d2214388a008770ed008f4c4.png", "/images/04b99b41f2df44f78e0c2caf08ecbbe1.png"]', 
 '尼康 Z 8 是一款高性能全画幅微单相机，具有4571万像素传感器和强大的视频功能。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 索尼 A7R V
((SELECT product_id FROM product WHERE model = 'A7R V' AND product_type = 1), 
 '{"类型": "可换镜头数码相机", "总像素数": "约6,100万", "有效像素": "约6100万", "镜头卡口": "索尼E卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "Exmor R CMOS"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/05c2eb20ff42455c8774383503035a5b.png", "/images/06d51035f6d740edbb5769dc83eadd5e.png", "/images/0c80fa9bd07b42ca8354794f2567ecbc.png"]', 
 '索尼 A7R V 是一款高像素全画幅微单相机，具有6100万像素传感器和先进的自动对焦系统。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 佳能 EOS R5
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 1), 
 '{"类型": "可换镜头数码相机", "总像素数": "约4,500万", "有效像素": "约4500万", "镜头卡口": "佳能RF卡口", "传感器尺寸": "约36 mm x 24mm", "影像传感器类型": "CMOS"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/0d21ce8e08f048bb953e4d6c110a9b64.png", "/images/0ffabc3c451f4d4daa90a94c00af36ea.png", "/images/1fd5d81b94d446b1b3e6b43f42a81edc.png"]', 
 '佳能 EOS R5 是一款高性能全画幅微单相机，支持8K视频录制。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 富士 X-T5
((SELECT product_id FROM product WHERE model = 'X-T5' AND product_type = 1), 
 '{"类型": "可换镜头数码相机", "总像素数": "约4,020万", "有效像素": "约4020万", "镜头卡口": "富士X卡口", "传感器尺寸": "约23.5 mm x 15.6mm", "影像传感器类型": "X-Trans CMOS 5 HR"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/2ce390ab01aa454fabb8c9d89f47c09b.png", "/images/31472d6ced30419eb3d8aad271606852.png", "/images/3658f9d7cb014aa8974f5a93b1df96c1.png"]', 
 '富士 X-T5 是一款复古风格的APS-C画幅微单相机，具有4020万像素传感器。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 徕卡 Q2
((SELECT product_id FROM product WHERE model = 'Q2' AND product_type = 1), 
 '{"类型": "固定镜头数码相机", "总像素数": "约4,730万", "有效像素": "约4730万", "镜头": "Summilux 28mm f/1.7 ASPH", "传感器尺寸": "约36 mm x 24mm", "影像传感器类型": "CMOS"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/3b887786a8de438a867649223fcb4389.png", "/images/3ddfc3964aa34b4e98768fa7b91ba22c.png", "/images/4369dc69d3414a4e8484df5135baa70a.png"]', 
 '徕卡 Q2 是一款高端固定镜头全画幅相机，具有4730万像素传感器和 Summilux 28mm f/1.7 镜头。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 松下 S5 II
((SELECT product_id FROM product WHERE model = 'S5 II' AND product_type = 1), 
 '{"类型": "可换镜头数码相机", "总像素数": "约2,420万", "有效像素": "约2420万", "镜头卡口": "松下L卡口", "传感器尺寸": "约35.6 mm x 23.8mm", "影像传感器类型": "CMOS"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/452be04bd3514ca19b0c8428eb199a02.png", "/images/48156e78c3da4eb097060e99cc4831c8.png", "/images/52d572ee89a4443a849eb60955eb05ba.png"]', 
 '松下 S5 II 是一款全画幅微单相机，具有出色的视频功能和五轴防抖。', 
 NULL, 0, NULL, NOW(), NOW()),

-- GoPro HERO12 Black
((SELECT product_id FROM product WHERE model = 'HERO12 Black' AND product_type = 1), 
 '{"类型": "运动相机", "总像素数": "约2,700万", "有效像素": "约2700万", "视频分辨率": "5.3K", "防水等级": "10米", "影像传感器类型": "CMOS"}', 
 '官方保修 1 年', 
 NULL, 
 '["/images/576462083e9f4f789e0913d756ed4f49.png", "/images/5acd54d4d818478ab82f9e6b1da49113.png", "/images/5b320c5ff61a4f2fa5a3b9f8f43f945d.png"]', 
 'GoPro HERO12 Black 是一款高性能运动相机，支持5.3K视频录制和防水功能。', 
 NULL, 0, NULL, NOW(), NOW()),

-- AKASO V50X
((SELECT product_id FROM product WHERE model = 'V50X' AND product_type = 1), 
 '{"类型": "运动相机", "总像素数": "约2,000万", "有效像素": "约2000万", "视频分辨率": "4K", "防水等级": "30米", "影像传感器类型": "CMOS"}', 
 '官方保修 1 年', 
 NULL, 
 '["/images/6338c7744edc4a2a924415e121dcaff6.png", "/images/6590e24c084f4ead926389e3041aa866.png", "/images/661e6ec68d3f4fb09728b434e0ed8dcd.png"]', 
 'AKASO V50X 是一款高性价比运动相机，支持4K视频录制和30米防水。', 
 NULL, 0, NULL, NOW(), NOW()),

-- Insta360 X3
((SELECT product_id FROM product WHERE model = 'X3' AND product_type = 1), 
 '{"类型": "全景相机", "总像素数": "约1,800万", "有效像素": "约1800万", "视频分辨率": "5.7K", "防水等级": "10米", "影像传感器类型": "CMOS"}', 
 '官方保修 1 年', 
 NULL, 
 '["/images/6bd2429655c3436a9f3eb6047feaecd5.png", "/images/731841eab6f44f25a7012ad738aaf254.png", "/images/7370f2a5a5f246209fccac3ba413243e.png"]', 
 'Insta360 X3 是一款全景相机，支持5.7K视频录制和10米防水。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 尼康 Z 24-70mm F2.8 S
((SELECT product_id FROM product WHERE model = 'Z 24-70mm F2.8 S' AND product_type = 1), 
 '{"类型": "变焦镜头", "焦距": "24-70mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "82mm"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/743be38699c1428da501543531d1a900.png", "/images/81724fe657ca4366a7839931d83f1b57.png", "/images/8e59174ed13b4eec923021a2c6e91c24.png"]', 
 '尼康 Z 24-70mm F2.8 S 是一款标准变焦镜头，适合风景、人像等多种拍摄场景。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 索尼 FE 24-70mm F2.8 GM II
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM II' AND product_type = 1), 
 '{"类型": "变焦镜头", "焦距": "24-70mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "索尼E卡口", "滤镜尺寸": "82mm"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/910b881ab68c4e38868df32553b1a270.png", "/images/a005143dadc14798af03a344229cca26.png", "/images/a0874a755c874602814f888f4d2d3ae2.png"]', 
 '索尼 FE 24-70mm F2.8 GM II 是一款高性能标准变焦镜头，具有出色的光学性能。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 佳能 RF 24-70mm F2.8 L IS USM
((SELECT product_id FROM product WHERE model = 'RF 24-70mm F2.8 L IS USM' AND product_type = 1), 
 '{"类型": "变焦镜头", "焦距": "24-70mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "佳能RF卡口", "滤镜尺寸": "82mm"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/a6717147383c4f0589c09f049404dfbe.png", "/images/aa2d457bcea6417284a3983e837b71e4.png", "/images/ac556fd1cf9b4cb1abfe283875a71b70.png"]', 
 '佳能 RF 24-70mm F2.8 L IS USM 是一款带防抖功能的标准变焦镜头。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 适马 24-70mm F2.8 DG DN Art
((SELECT product_id FROM product WHERE model = '24-70mm F2.8 DG DN Art' AND product_type = 1), 
 '{"类型": "变焦镜头", "焦距": "24-70mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "索尼E卡口", "滤镜尺寸": "82mm"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/b1145ce27105475daab729bd2c044435.png", "/images/bd47415b483848669345f762129938cf.png", "/images/c5e413fe2b2e42968ef6b4ca2f0accb4.png"]', 
 '适马 24-70mm F2.8 DG DN Art 是一款高性价比标准变焦镜头。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 腾龙 28-75mm F2.8 Di III VXD G2
((SELECT product_id FROM product WHERE model = '28-75mm F2.8 Di III VXD G2' AND product_type = 1), 
 '{"类型": "变焦镜头", "焦距": "28-75mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "索尼E卡口", "滤镜尺寸": "67mm"}', 
 '官方保修 2 年', 
 NULL, 
 '["/images/c5ea913d6c4f4b719992f595108073f5.png", "/images/cd3568fa02044728969be871b9808172.png", "/images/cda9743e83854f6ab180a7d19a97afa7.png"]', 
 '腾龙 28-75mm F2.8 Di III VXD G2 是一款轻便的标准变焦镜头。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 大疆 Mini 4 Pro
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 1), 
 '{"类型": "微型无人机", "重量": "249g", "飞行时间": "45分钟", "最大飞行速度": "16m/s", "最大续航": "45分钟", "相机": "4800万像素"}', 
 '官方保修 1 年', 
 NULL, 
 '["/images/d12bf2e4e70f45928697a62bd20c80f8.png", "/images/e1d4ed5a896c4dcabc90ffa9c4ecf5a6.png", "/images/ee2d0a66e4844750abc1238cf6773e9a.png"]', 
 '大疆 Mini 4 Pro 是一款轻便的微型无人机，适合旅行和日常拍摄。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 大疆 Air 3
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 1), 
 '{"类型": "轻型无人机", "重量": "720g", "飞行时间": "46分钟", "最大飞行速度": "18m/s", "最大续航": "46分钟", "相机": "4800万像素双摄"}', 
 '官方保修 1 年', 
 NULL, 
 '["/images/f086c4c7ceb14020a1096f14d8df9b51.png", "/images/fa891cba41ba48beb1e9ca79cb25119d.png", "/images/fdf2ad3803ff4591878c1baf0986b9bb.png"]', 
 '大疆 Air 3 是一款具有双摄系统的轻型无人机，适合专业拍摄。', 
 NULL, 0, NULL, NOW(), NOW()),

-- 大疆 Mavic 3 Pro
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 1), 
 '{"类型": "中型无人机", "重量": "1000g", "飞行时间": "46分钟", "最大飞行速度": "21m/s", "最大续航": "46分钟", "相机": "4800万像素三摄"}', 
 '官方保修 1 年', 
 NULL, 
 '["/images/Z62_1.png", "/images/Z62_2.png", "/images/Z62_3.png"]', 
 '大疆 Mavic 3 Pro 是一款专业级无人机，具有三摄系统和出色的飞行性能。', 
 NULL, 0, NULL, NOW(), NOW());

-- 二手商品详情
INSERT INTO `product_detail` (`product_id`, `parameters`, `warranty_info`, `authorization`, `img_urls`, `description`, `usage_duration`, `repair_history`, `accessories`, `create_time`, `update_time`)
VALUES
-- 尼康 Z6
((SELECT product_id FROM product WHERE model = 'Z6' AND product_type = 2), 
 '{"类型": "可换镜头数码相机", "总像素数": "约2,528万", "有效像素": "约2450万", "镜头卡口": "尼康Z卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "FX"}', 
 '剩余保修 6 个月', 
 NULL, 
 '["/images/Z6_1.png"]', 
 '95新尼康 Z6 微单相机，无划痕，仅使用 1 年。', 
 '1年', 0, '原装电池、充电器、相机包', NOW(), NOW()),

-- 索尼 A7M3
((SELECT product_id FROM product WHERE model = 'A7M3' AND product_type = 2), 
 '{"类型": "可换镜头数码相机", "总像素数": "约2,420万", "有效像素": "约2420万", "镜头卡口": "索尼E卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "Exmor R CMOS"}', 
 '已过保', 
 NULL, 
 '["/images/A7R5.png"]', 
 '90新索尼 A7M3 微单相机，轻微使用痕迹，功能正常。', 
 '2年', 0, '原装电池、充电器、相机包、肩带', NOW(), NOW()),

-- 佳能 EOS R
((SELECT product_id FROM product WHERE model = 'EOS R' AND product_type = 2), 
 '{"类型": "可换镜头数码相机", "总像素数": "约3,030万", "有效像素": "约3030万", "镜头卡口": "佳能RF卡口", "传感器尺寸": "约36 mm x 24mm", "影像传感器类型": "CMOS"}', 
 '已过保', 
 NULL, 
 '["/images/D850_1.png"]', 
 '85新佳能 EOS R 微单相机，有轻微划痕，功能正常。', 
 '3年', 0, '原装电池、充电器、相机包', NOW(), NOW()),

-- GoPro HERO10 Black
((SELECT product_id FROM product WHERE model = 'HERO10 Black' AND product_type = 2), 
 '{"类型": "运动相机", "总像素数": "约2,300万", "有效像素": "约2300万", "视频分辨率": "5.3K", "防水等级": "10米", "影像传感器类型": "CMOS"}', 
 '已过保', 
 NULL, 
 '["/images/Z 24-120 F4S.png"]', 
 '90新GoPro HERO10 Black运动相机，功能正常，配件齐全。', 
 '1年', 0, '原装电池、充电器、防水壳、自拍杆', NOW(), NOW()),

-- 尼康 Z 24-120mm F4 S
((SELECT product_id FROM product WHERE model = 'Z 24-120mm F4 S' AND product_type = 2), 
 '{"类型": "变焦镜头", "焦距": "24-120mm", "最大光圈": "F4", "最小光圈": "F22", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "72mm"}', 
 '剩余保修 1 年', 
 NULL, 
 '["/images/Z 70-200mm f2.8 VR S_1.png"]', 
 '95新尼康 Z 24-120mm F4 S 镜头，无划痕，功能正常。', 
 '1年', 0, '原装镜头盖、遮光罩、镜头袋', NOW(), NOW()),

-- 索尼 FE 24-70mm F2.8 GM
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM' AND product_type = 2), 
 '{"类型": "变焦镜头", "焦距": "24-70mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "索尼E卡口", "滤镜尺寸": "82mm"}', 
 '已过保', 
 NULL, 
 '["/images/ZR_1.png"]', 
 '90新索尼 FE 24-70mm F2.8 GM 镜头，轻微使用痕迹，功能正常。', 
 '2年', 0, '原装镜头盖、遮光罩、镜头袋', NOW(), NOW()),

-- 尼康 Z 50mm F1.8 S
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 2), 
 '{"类型": "定焦镜头", "焦距": "50mm", "最大光圈": "F1.8", "最小光圈": "F16", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "58mm"}', 
 '剩余保修 18 个月', 
 NULL, 
 '["/images/00655cd317064682a866ba08d472dd88.png"]', 
 '95新尼康 Z 50mm F1.8 S 镜头，无划痕，功能正常。', 
 '6个月', 0, '原装镜头盖、遮光罩', NOW(), NOW()),

-- 大疆 Mini 3
((SELECT product_id FROM product WHERE model = 'Mini 3' AND product_type = 2), 
 '{"类型": "微型无人机", "重量": "249g", "飞行时间": "38分钟", "最大飞行速度": "16m/s", "最大续航": "38分钟", "相机": "4800万像素"}', 
 '已过保', 
 NULL, 
 '["/images/011ee0a7d2214388a008770ed008f4c4.png"]', 
 '90新大疆 Mini 3 无人机，功能正常，配件齐全。', 
 '1年', 0, '原装电池、充电器、遥控器、桨叶', NOW(), NOW()),

-- 大疆 Air 2S
((SELECT product_id FROM product WHERE model = 'Air 2S' AND product_type = 2), 
 '{"类型": "轻型无人机", "重量": "595g", "飞行时间": "31分钟", "最大飞行速度": "19m/s", "最大续航": "31分钟", "相机": "5000万像素"}', 
 '已过保', 
 NULL, 
 '["/images/04b99b41f2df44f78e0c2caf08ecbbe1.png"]', 
 '85新大疆 Air 2S 无人机，有轻微使用痕迹，功能正常。', 
 '2年', 0, '原装电池、充电器、遥控器、桨叶、收纳包', NOW(), NOW());

-- 租赁商品详情
INSERT INTO `product_detail` (`product_id`, `parameters`, `warranty_info`, `authorization`, `img_urls`, `description`, `usage_duration`, `repair_history`, `accessories`, `create_time`, `update_time`)
VALUES
-- 尼康 Z6II
((SELECT product_id FROM product WHERE model = 'Z6II' AND product_type = 3), 
 '{"类型": "可换镜头数码相机", "总像素数": "约2,528万", "有效像素": "约2450万", "镜头卡口": "尼康Z卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "FX"}', 
 '租赁专用', 
 NULL, 
 '["/images/05c2eb20ff42455c8774383503035a5b.png"]', 
 '尼康 Z6II 微单相机，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装电池、充电器、相机包', NOW(), NOW()),

-- 索尼 A7R5
((SELECT product_id FROM product WHERE model = 'A7R5' AND product_type = 3), 
 '{"类型": "可换镜头数码相机", "总像素数": "约6,100万", "有效像素": "约6100万", "镜头卡口": "索尼E卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "Exmor R CMOS"}', 
 '租赁专用', 
 NULL, 
 '["/images/06d51035f6d740edbb5769dc83eadd5e.png"]', 
 '索尼 A7R5 微单相机，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装电池、充电器、相机包', NOW(), NOW()),

-- 佳能 EOS R5
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 3), 
 '{"类型": "可换镜头数码相机", "总像素数": "约4,500万", "有效像素": "约4500万", "镜头卡口": "佳能RF卡口", "传感器尺寸": "约36 mm x 24mm", "影像传感器类型": "CMOS"}', 
 '租赁专用', 
 NULL, 
 '["/images/0c80fa9bd07b42ca8354794f2567ecbc.png"]', 
 '佳能 EOS R5 微单相机，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装电池、充电器、相机包', NOW(), NOW()),

-- 尼康 Z 70-200mm f2.8 VR S
((SELECT product_id FROM product WHERE model = 'Z 70-200mm f2.8 VR S' AND product_type = 3), 
 '{"类型": "变焦镜头", "焦距": "70-200mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "77mm"}', 
 '租赁专用', 
 NULL, 
 '["/images/0d21ce8e08f048bb953e4d6c110a9b64.png"]', 
 '尼康 Z 70-200mm f2.8 VR S 镜头，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装镜头盖、遮光罩、镜头袋', NOW(), NOW()),

-- 索尼 FE 70-200mm F2.8 GM OSS II
((SELECT product_id FROM product WHERE model = 'FE 70-200mm F2.8 GM OSS II' AND product_type = 3), 
 '{"类型": "变焦镜头", "焦距": "70-200mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "索尼E卡口", "滤镜尺寸": "77mm"}', 
 '租赁专用', 
 NULL, 
 '["/images/0ffabc3c451f4d4daa90a94c00af36ea.png"]', 
 '索尼 FE 70-200mm F2.8 GM OSS II 镜头，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装镜头盖、遮光罩、镜头袋', NOW(), NOW()),

-- 尼康 Z 50mm F1.8 S
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 3), 
 '{"类型": "定焦镜头", "焦距": "50mm", "最大光圈": "F1.8", "最小光圈": "F16", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "58mm"}', 
 '租赁专用', 
 NULL, 
 '["/images/1fd5d81b94d446b1b3e6b43f42a81edc.png"]', 
 '尼康 Z 50mm F1.8 S 镜头，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装镜头盖、遮光罩', NOW(), NOW()),

-- 大疆 Mini 4 Pro
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 3), 
 '{"类型": "微型无人机", "重量": "249g", "飞行时间": "45分钟", "最大飞行速度": "16m/s", "最大续航": "45分钟", "相机": "4800万像素"}', 
 '租赁专用', 
 NULL, 
 '["/images/2ce390ab01aa454fabb8c9d89f47c09b.png"]', 
 '大疆 Mini 4 Pro 无人机，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装电池、充电器、遥控器、桨叶', NOW(), NOW()),

-- 大疆 Air 3
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 3), 
 '{"类型": "轻型无人机", "重量": "720g", "飞行时间": "46分钟", "最大飞行速度": "18m/s", "最大续航": "46分钟", "相机": "4800万像素双摄"}', 
 '租赁专用', 
 NULL, 
 '["/images/31472d6ced30419eb3d8aad271606852.png"]', 
 '大疆 Air 3 无人机，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装电池、充电器、遥控器、桨叶、收纳包', NOW(), NOW()),

-- 大疆 Mavic 3 Pro
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 3), 
 '{"类型": "中型无人机", "重量": "1000g", "飞行时间": "46分钟", "最大飞行速度": "21m/s", "最大续航": "46分钟", "相机": "4800万像素三摄"}', 
 '租赁专用', 
 NULL, 
 '["/images/3658f9d7cb014aa8974f5a93b1df96c1.png"]', 
 '大疆 Mavic 3 Pro 无人机，租赁专用，定期维护，状态良好。', 
 NULL, 0, '原装电池、充电器、遥控器、桨叶、收纳包', NOW(), NOW());

-- 插入SKU记录
INSERT INTO `sku` (`product_id`, `sku_attribute`, `sku_value`, `price`, `stock`, `min_stock`, `sales`, `create_time`, `update_time`)
VALUES
-- 全新商品SKU
((SELECT product_id FROM product WHERE model = 'Z 8' AND product_type = 1), '颜色', '黑色', 18999.00, 50, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7R V' AND product_type = 1), '颜色', '黑色', 21999.00, 40, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 1), '颜色', '黑色', 22999.00, 35, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'X-T5' AND product_type = 1), '颜色', '黑色', 11999.00, 45, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Q2' AND product_type = 1), '颜色', '黑色', 29999.00, 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'S5 II' AND product_type = 1), '颜色', '黑色', 12999.00, 40, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'HERO12 Black' AND product_type = 1), '颜色', '黑色', 3499.00, 100, 20, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'V50X' AND product_type = 1), '颜色', '黑色', 999.00, 150, 30, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'X3' AND product_type = 1), '颜色', '黑色', 2999.00, 80, 15, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 24-70mm F2.8 S' AND product_type = 1), '版本', '国行', 10999.00, 30, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM II' AND product_type = 1), '版本', '国行', 13999.00, 25, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'RF 24-70mm F2.8 L IS USM' AND product_type = 1), '版本', '国行', 11999.00, 25, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = '24-70mm F2.8 DG DN Art' AND product_type = 1), '版本', '国行', 7999.00, 30, 15, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = '28-75mm F2.8 Di III VXD G2' AND product_type = 1), '版本', '国行', 5999.00, 35, 15, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 1), '颜色', '白色', 4299.00, 40, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 1), '颜色', '灰色', 5999.00, 30, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 1), '颜色', '灰色', 11999.00, 20, 5, 0, NOW(), NOW()),

-- 二手商品SKU
((SELECT product_id FROM product WHERE model = 'Z6' AND product_type = 2), '成色', '95新', 5555.00, 5, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7M3' AND product_type = 2), '成色', '90新', 7999.00, 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R' AND product_type = 2), '成色', '85新', 6999.00, 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'HERO10 Black' AND product_type = 2), '成色', '90新', 1999.00, 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 24-120mm F4 S' AND product_type = 2), '成色', '95新', 4999.00, 4, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM' AND product_type = 2), '成色', '90新', 6999.00, 3, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 2), '成色', '95新', 1999.00, 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mini 3' AND product_type = 2), '成色', '90新', 2499.00, 5, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 2S' AND product_type = 2), '成色', '85新', 3499.00, 3, 5, 0, NOW(), NOW()),

-- 租赁商品SKU
((SELECT product_id FROM product WHERE model = 'Z6II' AND product_type = 3), '状态', '可租', 120.00, 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7R5' AND product_type = 3), '状态', '可租', 180.00, 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 3), '状态', '可租', 200.00, 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 70-200mm f2.8 VR S' AND product_type = 3), '状态', '可租', 100.00, 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 70-200mm F2.8 GM OSS II' AND product_type = 3), '状态', '可租', 120.00, 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 3), '状态', '可租', 30.00, 12, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 3), '状态', '可租', 50.00, 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 3), '状态', '可租', 70.00, 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 3), '状态', '可租', 150.00, 5, 3, 0, NOW(), NOW());

-- 插入库存记录
INSERT INTO `inventory` (`product_id`, `product_name`, `product_type`, `sku_id`, `sku_attribute`, `sku_value`, `current_stock`, `min_stock`, `sales`, `create_time`, `last_update_time`)
VALUES
-- 全新商品库存
((SELECT product_id FROM product WHERE model = 'Z 8' AND product_type = 1), '尼康 Z 8', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z 8' AND product_type = 1) LIMIT 1), '颜色', '黑色', 50, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7R V' AND product_type = 1), '索尼 A7R V', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'A7R V' AND product_type = 1) LIMIT 1), '颜色', '黑色', 40, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 1), '佳能 EOS R5', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 1) LIMIT 1), '颜色', '黑色', 35, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'X-T5' AND product_type = 1), '富士 X-T5', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'X-T5' AND product_type = 1) LIMIT 1), '颜色', '黑色', 45, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Q2' AND product_type = 1), '徕卡 Q2', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Q2' AND product_type = 1) LIMIT 1), '颜色', '黑色', 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'S5 II' AND product_type = 1), '松下 S5 II', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'S5 II' AND product_type = 1) LIMIT 1), '颜色', '黑色', 40, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'HERO12 Black' AND product_type = 1), 'GoPro HERO12 Black', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'HERO12 Black' AND product_type = 1) LIMIT 1), '颜色', '黑色', 100, 20, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'V50X' AND product_type = 1), 'AKASO V50X', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'V50X' AND product_type = 1) LIMIT 1), '颜色', '黑色', 150, 30, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'X3' AND product_type = 1), 'Insta360 X3', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'X3' AND product_type = 1) LIMIT 1), '颜色', '黑色', 80, 15, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 24-70mm F2.8 S' AND product_type = 1), '尼康 Z 24-70mm F2.8 S', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z 24-70mm F2.8 S' AND product_type = 1) LIMIT 1), '版本', '国行', 30, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM II' AND product_type = 1), '索尼 FE 24-70mm F2.8 GM II', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM II' AND product_type = 1) LIMIT 1), '版本', '国行', 25, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'RF 24-70mm F2.8 L IS USM' AND product_type = 1), '佳能 RF 24-70mm F2.8 L IS USM', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'RF 24-70mm F2.8 L IS USM' AND product_type = 1) LIMIT 1), '版本', '国行', 25, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = '24-70mm F2.8 DG DN Art' AND product_type = 1), '适马 24-70mm F2.8 DG DN Art', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = '24-70mm F2.8 DG DN Art' AND product_type = 1) LIMIT 1), '版本', '国行', 30, 15, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = '28-75mm F2.8 Di III VXD G2' AND product_type = 1), '腾龙 28-75mm F2.8 Di III VXD G2', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = '28-75mm F2.8 Di III VXD G2' AND product_type = 1) LIMIT 1), '版本', '国行', 35, 15, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 1), '大疆 Mini 4 Pro', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 1) LIMIT 1), '颜色', '白色', 40, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 1), '大疆 Air 3', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 1) LIMIT 1), '颜色', '灰色', 30, 10, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 1), '大疆 Mavic 3 Pro', 'new', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 1) LIMIT 1), '颜色', '灰色', 20, 5, 0, NOW(), NOW()),

-- 二手商品库存
((SELECT product_id FROM product WHERE model = 'Z6' AND product_type = 2), '尼康 Z6', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z6' AND product_type = 2) LIMIT 1), '成色', '95新', 5, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7M3' AND product_type = 2), '索尼 A7M3', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'A7M3' AND product_type = 2) LIMIT 1), '成色', '90新', 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R' AND product_type = 2), '佳能 EOS R', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'EOS R' AND product_type = 2) LIMIT 1), '成色', '85新', 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'HERO10 Black' AND product_type = 2), 'GoPro HERO10 Black', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'HERO10 Black' AND product_type = 2) LIMIT 1), '成色', '90新', 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 24-120mm F4 S' AND product_type = 2), '尼康 Z 24-120mm F4 S', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z 24-120mm F4 S' AND product_type = 2) LIMIT 1), '成色', '95新', 4, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM' AND product_type = 2), '索尼 FE 24-70mm F2.8 GM', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM' AND product_type = 2) LIMIT 1), '成色', '90新', 3, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 2), '尼康 Z 50mm F1.8 S', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 2) LIMIT 1), '成色', '95新', 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mini 3' AND product_type = 2), '大疆 Mini 3', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Mini 3' AND product_type = 2) LIMIT 1), '成色', '90新', 5, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 2S' AND product_type = 2), '大疆 Air 2S', 'used', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Air 2S' AND product_type = 2) LIMIT 1), '成色', '85新', 3, 5, 0, NOW(), NOW()),

-- 租赁商品库存
((SELECT product_id FROM product WHERE model = 'Z6II' AND product_type = 3), '尼康 Z6II', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z6II' AND product_type = 3) LIMIT 1), '状态', '可租', 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7R5' AND product_type = 3), '索尼 A7R5', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'A7R5' AND product_type = 3) LIMIT 1), '状态', '可租', 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 3), '佳能 EOS R5', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 3) LIMIT 1), '状态', '可租', 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 70-200mm f2.8 VR S' AND product_type = 3), '尼康 Z 70-200mm f2.8 VR S', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z 70-200mm f2.8 VR S' AND product_type = 3) LIMIT 1), '状态', '可租', 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 70-200mm F2.8 GM OSS II' AND product_type = 3), '索尼 FE 70-200mm F2.8 GM OSS II', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'FE 70-200mm F2.8 GM OSS II' AND product_type = 3) LIMIT 1), '状态', '可租', 6, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 3), '尼康 Z 50mm F1.8 S', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 3) LIMIT 1), '状态', '可租', 12, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 3), '大疆 Mini 4 Pro', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 3) LIMIT 1), '状态', '可租', 10, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 3), '大疆 Air 3', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 3) LIMIT 1), '状态', '可租', 8, 5, 0, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 3), '大疆 Mavic 3 Pro', 'rental', (SELECT sku_id FROM sku WHERE product_id = (SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 3) LIMIT 1), '状态', '可租', 5, 3, 0, NOW(), NOW());

-- 插入租赁商品详情记录
INSERT INTO `product_rental_detail` (`product_id`, `deposit`, `max_rental_days`, `min_rental_days`, `insurance_fee`, `late_fee_rate`, `damage_fee_rule`, `pickup_methods`, `delivery_fee`, `created_time`, `updated_time`)
VALUES
-- 租赁相机
((SELECT product_id FROM product WHERE model = 'Z6II' AND product_type = 3), 1399.90, 90, 3, 10.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'A7R5' AND product_type = 3), 2499.90, 90, 3, 15.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'EOS R5' AND product_type = 3), 2599.90, 90, 3, 15.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),

-- 租赁镜头
((SELECT product_id FROM product WHERE model = 'Z 70-200mm f2.8 VR S' AND product_type = 3), 1499.90, 90, 3, 8.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'FE 70-200mm F2.8 GM OSS II' AND product_type = 3), 1799.90, 90, 3, 10.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 3), 399.90, 90, 2, 5.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),

-- 租赁无人机
((SELECT product_id FROM product WHERE model = 'Mini 4 Pro' AND product_type = 3), 479.90, 90, 2, 5.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Air 3' AND product_type = 3), 679.90, 90, 2, 7.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW()),
((SELECT product_id FROM product WHERE model = 'Mavic 3 Pro' AND product_type = 3), 1388.80, 90, 3, 15.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, NOW(), NOW());

-- 插入二手商品详情记录
INSERT INTO `second_hand` (`product_id`, `quality_report`, `used_time`, `defect_desc`, `defect_img`, `seller_type`, `negotiate_status`, `final_price`, `parameters`, `warranty_info`, `img_urls`, `description`, `create_time`, `update_time`, `repair_history`, `accessories`)
VALUES
-- 二手相机
((SELECT product_id FROM product WHERE model = 'Z6' AND product_type = 2), NULL, '1年', NULL, NULL, 2, 0, NULL, '{"类型": "可换镜头数码相机", "总像素数": "约2,528万", "有效像素": "约2450万", "镜头卡口": "尼康Z卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "FX"}', '剩余保修 6 个月', '["/images/Z6_1.png"]', '95新尼康 Z6 微单相机，无划痕，仅使用 1 年。', NOW(), NOW(), 0, '原装电池、充电器、相机包'),
((SELECT product_id FROM product WHERE model = 'A7M3' AND product_type = 2), NULL, '2年', '轻微使用痕迹', NULL, 2, 0, NULL, '{"类型": "可换镜头数码相机", "总像素数": "约2,420万", "有效像素": "约2420万", "镜头卡口": "索尼E卡口", "传感器尺寸": "约35.9 mm x 23.9mm", "影像传感器类型": "Exmor R CMOS"}', '已过保', '["/images/A7R5.png"]', '90新索尼 A7M3 微单相机，轻微使用痕迹，功能正常。', NOW(), NOW(), 0, '原装电池、充电器、相机包、肩带'),
((SELECT product_id FROM product WHERE model = 'EOS R' AND product_type = 2), NULL, '3年', '有轻微划痕', NULL, 2, 0, NULL, '{"类型": "可换镜头数码相机", "总像素数": "约3,030万", "有效像素": "约3030万", "镜头卡口": "佳能RF卡口", "传感器尺寸": "约36 mm x 24mm", "影像传感器类型": "CMOS"}', '已过保', '["/images/D850_1.png"]', '85新佳能 EOS R 微单相机，有轻微划痕，功能正常。', NOW(), NOW(), 0, '原装电池、充电器、相机包'),
((SELECT product_id FROM product WHERE model = 'HERO10 Black' AND product_type = 2), NULL, '1年', NULL, NULL, 2, 0, NULL, '{"类型": "运动相机", "总像素数": "约2,300万", "有效像素": "约2300万", "视频分辨率": "5.3K", "防水等级": "10米", "影像传感器类型": "CMOS"}', '已过保', '["/images/Z 24-120 F4S.png"]', '90新GoPro HERO10 Black运动相机，功能正常，配件齐全。', NOW(), NOW(), 0, '原装电池、充电器、防水壳、自拍杆'),

-- 二手镜头
((SELECT product_id FROM product WHERE model = 'Z 24-120mm F4 S' AND product_type = 2), NULL, '1年', NULL, NULL, 2, 0, NULL, '{"类型": "变焦镜头", "焦距": "24-120mm", "最大光圈": "F4", "最小光圈": "F22", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "72mm"}', '剩余保修 1 年', '["/images/Z 70-200mm f2.8 VR S_1.png"]', '95新尼康 Z 24-120mm F4 S 镜头，无划痕，功能正常。', NOW(), NOW(), 0, '原装镜头盖、遮光罩、镜头袋'),
((SELECT product_id FROM product WHERE model = 'FE 24-70mm F2.8 GM' AND product_type = 2), NULL, '2年', '轻微使用痕迹', NULL, 2, 0, NULL, '{"类型": "变焦镜头", "焦距": "24-70mm", "最大光圈": "F2.8", "最小光圈": "F22", "镜头卡口": "索尼E卡口", "滤镜尺寸": "82mm"}', '已过保', '["/images/ZR_1.png"]', '90新索尼 FE 24-70mm F2.8 GM 镜头，轻微使用痕迹，功能正常。', NOW(), NOW(), 0, '原装镜头盖、遮光罩、镜头袋'),
((SELECT product_id FROM product WHERE model = 'Z 50mm F1.8 S' AND product_type = 2), NULL, '6个月', NULL, NULL, 2, 0, NULL, '{"类型": "定焦镜头", "焦距": "50mm", "最大光圈": "F1.8", "最小光圈": "F16", "镜头卡口": "尼康Z卡口", "滤镜尺寸": "58mm"}', '剩余保修 18 个月', '["/images/00655cd317064682a866ba08d472dd88.png"]', '95新尼康 Z 50mm F1.8 S 镜头，无划痕，功能正常。', NOW(), NOW(), 0, '原装镜头盖、遮光罩'),

-- 二手无人机
((SELECT product_id FROM product WHERE model = 'Mini 3' AND product_type = 2), NULL, '1年', NULL, NULL, 2, 0, NULL, '{"类型": "微型无人机", "重量": "249g", "飞行时间": "38分钟", "最大飞行速度": "16m/s", "最大续航": "38分钟", "相机": "4800万像素"}', '已过保', '["/images/011ee0a7d2214388a008770ed008f4c4.png"]', '90新大疆 Mini 3 无人机，功能正常，配件齐全。', NOW(), NOW(), 0, '原装电池、充电器、遥控器、桨叶'),
((SELECT product_id FROM product WHERE model = 'Air 2S' AND product_type = 2), NULL, '2年', '轻微使用痕迹', NULL, 2, 0, NULL, '{"类型": "轻型无人机", "重量": "595g", "飞行时间": "31分钟", "最大飞行速度": "19m/s", "最大续航": "31分钟", "相机": "5000万像素"}', '已过保', '["/images/04b99b41f2df44f78e0c2caf08ecbbe1.png"]', '85新大疆 Air 2S 无人机，有轻微使用痕迹，功能正常。', NOW(), NOW(), 0, '原装电池、充电器、遥控器、桨叶、收纳包');

-- 提交事务
COMMIT;