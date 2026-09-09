/*
 Navicat Premium Data Transfer

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80030
 Source Host           : localhost:3306
 Source Schema         : db_bysj_pets

 Target Server Type    : MySQL
 Target Server Version : 80030
 File Encoding         : 65001

 Date: 11/04/2026 02:12:33
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for brand
-- ----------------------------
DROP TABLE IF EXISTS `brand`;
CREATE TABLE `brand`  (
  `brand_id` int NOT NULL AUTO_INCREMENT COMMENT '品牌ID',
  `brand_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '品牌名称',
  `parent_id` int NULL DEFAULT NULL COMMENT '外键，父类ID（相机-尼康；镜头-适马）',
  `category_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类编码，按层级规则生成（如顶级分类 “相机” 编码为 “CAM”，子分类 “全画幅相机” 编码为 “CAM-FULL”）',
  `sort` int NOT NULL DEFAULT 0 COMMENT '分类排序（数值越小越靠前）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '分类状态：\r\n- 1 = 启用（可被商品关联、前端展示）\r\n- 0 = 禁用（不可关联商品、前端隐藏）',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '分类描述',
  `create_by` bigint NOT NULL COMMENT '外键,分类创建人 ID，关联user.user_id（仅管理员可创建分类）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类创建时间',
  `update_by` bigint NULL DEFAULT NULL COMMENT '外键,分类更新人 ID，关联user.user_id（仅管理员可更新分类',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类更新时间',
  PRIMARY KEY (`brand_id`) USING BTREE,
  UNIQUE INDEX `category_name`(`brand_name`, `category_code`) USING BTREE,
  INDEX `parent_id`(`parent_id`, `sort`, `status`, `create_by`, `update_by`) USING BTREE,
  INDEX `create_by`(`create_by`) USING BTREE,
  INDEX `product_category_ibfk_3`(`update_by`) USING BTREE,
  INDEX `parent_id_2`(`parent_id`) USING BTREE,
  CONSTRAINT `brand_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `brand` (`brand_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `brand_ibfk_2` FOREIGN KEY (`create_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `brand_ibfk_3` FOREIGN KEY (`update_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 38 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储品牌分类（如相机-尼康、镜头-适马、灯光设备-神牛），为product提供分类关联。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of brand
-- ----------------------------
INSERT INTO `brand` VALUES (1, '相机', NULL, 'CAM', 0, 1, NULL, 1, '2026-03-07 22:23:22', 2, '2026-03-07 22:23:23');
INSERT INTO `brand` VALUES (2, '镜头', NULL, 'LEN', 0, 1, NULL, 1, '2026-01-06 23:41:05', 1, '2026-01-06 23:41:06');
INSERT INTO `brand` VALUES (3, '无人机', NULL, 'DRONE', 0, 1, NULL, 1, '2026-04-10 18:22:07', NULL, '2026-04-10 18:22:10');
INSERT INTO `brand` VALUES (11, '尼康', 1, 'NIKON', 1, 1, NULL, 1, '2026-01-06 23:44:36', 1, '2026-01-06 23:44:37');
INSERT INTO `brand` VALUES (12, '索尼', 1, 'SONY', 1, 1, '刀法', 1, '2026-01-11 16:20:07', 1, '2026-01-11 16:20:08');
INSERT INTO `brand` VALUES (13, '佳能', 1, 'CANON', 1, 1, NULL, 1, '2026-04-10 18:20:36', 1, '2026-04-10 18:20:36');
INSERT INTO `brand` VALUES (14, '富士', 1, 'FUJIFILM', 1, 1, NULL, 1, '2026-04-10 18:21:24', NULL, '2026-04-10 18:21:26');
INSERT INTO `brand` VALUES (21, '尼克尔', 2, 'NIKKOR', 1, 1, '尼康-尼克尔镜头', 1, '2026-01-11 16:19:50', 1, '2026-01-11 16:19:51');
INSERT INTO `brand` VALUES (22, '索尼', 2, 'SONY_LENS', 1, 1, '', 1, '2026-01-11 16:20:03', 1, '2026-01-11 16:20:04');
INSERT INTO `brand` VALUES (23, '佳能', 2, 'CANON_LENS', 1, 1, NULL, 1, '2026-04-10 18:20:31', 1, '2026-04-10 18:20:31');
INSERT INTO `brand` VALUES (31, '三脚架', NULL, 'TRIPOD', 0, 1, '', 1, '2026-01-11 16:12:44', NULL, '2026-01-11 16:12:44');
INSERT INTO `brand` VALUES (34, '闪光灯', NULL, 'FLASHLIGHT', 0, 1, '', 1, '2026-01-11 16:18:19', NULL, '2026-01-11 16:18:19');
INSERT INTO `brand` VALUES (35, '斯莫格', 31, 'SMALLRIG', 1, 1, '斯莫格', 1, '2026-01-11 16:19:31', 1, '2026-01-11 16:19:31');
INSERT INTO `brand` VALUES (37, '大疆', 3, 'DJI', 1, 1, NULL, 1, '2026-04-10 18:23:03', NULL, '2026-04-10 18:23:05');
INSERT INTO `brand` VALUES (41, '大疆-Action', 1, 'DJI-ACTION', 1, 1, '111111111111', 1, '2026-04-10 22:38:40', NULL, '2026-04-10 22:38:40');

-- ----------------------------
-- Table structure for cart
-- ----------------------------
DROP TABLE IF EXISTS `cart`;
CREATE TABLE `cart`  (
  `cart_id` bigint NOT NULL AUTO_INCREMENT COMMENT '购物车记录唯一标识',
  `user_id` bigint NOT NULL COMMENT '外键,关联user.user_id，用户删除时同步清空购物车',
  `product_id` bigint NOT NULL COMMENT '外键,关联product.product_id，商品下架时标记 “已下架”',
  `quantity` int NOT NULL DEFAULT 1 COMMENT '商品数量（购买场景）或租赁数量（租赁场景，默认 1）',
  `lease_term` int NULL DEFAULT 1 COMMENT '租期（仅租赁场景用，单位：天，如 1-90 天）',
  `select_status` tinyint NOT NULL DEFAULT 1 COMMENT '是否勾选结算：0 - 未勾选，1 - 已勾选',
  `preoccupy_time` datetime NULL DEFAULT NULL COMMENT '租赁商品预占库存时间（加入购物车后 24 小时内有效，超时自动释放）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '加入购物车时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '购物车信息更新时间',
  PRIMARY KEY (`cart_id`) USING BTREE,
  INDEX `user_id`(`user_id`, `product_id`, `preoccupy_time`) USING BTREE,
  INDEX `product_id`(`product_id`) USING BTREE,
  CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 37 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储用户加入购物车的商品信息，支持购买 / 租赁场景的临时数据存储与状态同步。\r\n备注：商品下架或库存不足时，select_status自动设为 0，不可结算；未登录用户购物车存储于本地，登录后通过user_id合并至该表。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of cart
-- ----------------------------
INSERT INTO `cart` VALUES (30, 1, 1, 1, 1, 1, NULL, '2025-12-29 21:43:29', '2025-12-29 21:43:29');
INSERT INTO `cart` VALUES (31, 7, 2, 2, 1, 1, NULL, '2025-12-30 21:13:08', '2026-01-12 00:36:41');
INSERT INTO `cart` VALUES (32, 7, 4, 1, 1, 1, NULL, '2025-12-30 21:13:14', '2025-12-30 21:13:14');
INSERT INTO `cart` VALUES (34, 7, 5, 1, 1, 1, NULL, '2026-02-08 17:36:04', '2026-02-08 17:36:04');
INSERT INTO `cart` VALUES (37, 7, 1, 1, 1, 1, NULL, '2026-04-10 21:02:22', '2026-04-10 21:02:22');

-- ----------------------------
-- Table structure for evaluation
-- ----------------------------
DROP TABLE IF EXISTS `evaluation`;
CREATE TABLE `evaluation`  (
  `eval_id` bigint NOT NULL AUTO_INCREMENT COMMENT '评价唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联order.order_id，订单删除时同步删除评价',
  `product_id` bigint NOT NULL COMMENT '关联product.product_id，商品下架不影响评价展示',
  `user_id` bigint NOT NULL COMMENT '关联user.user_id，评价归属用户',
  `seller_id` bigint NOT NULL COMMENT '关联user.user_id，评价对应的商家',
  `score` tinyint NOT NULL COMMENT '综合评分（1-5 星，1 星最差，5 星最好）',
  `quality_score` tinyint NOT NULL COMMENT '器材质量评分（1-5 星，仅购买 / 租赁 / 二手场景）',
  `service_score` tinyint NOT NULL COMMENT '商家服务评分（1-5 星，所有场景）',
  `logistics_score` tinyint NULL DEFAULT NULL COMMENT '物流速度评分（1-5 星，仅购买 / 二手场景，自提为 5 星）',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '评价内容（≥10 字，禁止辱骂、虚假内容）',
  `img_urls` json NULL COMMENT '评价图片路径（JSON 数组，≤5 张）',
  `eval_status` tinyint NOT NULL DEFAULT 1 COMMENT '评价状态：0 - 已删除，1 - 正常展示，2 - 违规隐藏（管理员操作）',
  `reply_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '商家回复内容',
  `reply_time` datetime NULL DEFAULT NULL COMMENT '商家回复时间',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '评价提交时间',
  `update_time` datetime NOT NULL COMMENT '评价状态更新时间',
  PRIMARY KEY (`eval_id`) USING BTREE,
  UNIQUE INDEX `order_id`(`order_id`) USING BTREE,
  INDEX `product_id`(`product_id`, `user_id`, `seller_id`, `score`, `eval_status`, `create_time`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  INDEX `seller_id`(`seller_id`) USING BTREE,
  CONSTRAINT `evaluation_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `evaluation_ibfk_3` FOREIGN KEY (`seller_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `evaluation_ibfk_4` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `evaluation_ibfk_5` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储用户对订单的评价与评分，关联商品与商家，支撑消费信任体系。\r\n备注：订单完成后 7 天内可提交评价，提交后 24 小时内可删除重评；评分低于 3 星的 “差评”，系统提醒商家 48 小时内回复。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of evaluation
-- ----------------------------
INSERT INTO `evaluation` VALUES (6, 54, 1, 7, 1, 5, 5, 5, 5, '好好好好好好好好好好', NULL, 1, NULL, NULL, '2026-03-07 19:48:08', '2026-03-07 19:48:08');

-- ----------------------------
-- Table structure for favorite
-- ----------------------------
DROP TABLE IF EXISTS `favorite`;
CREATE TABLE `favorite`  (
  `favorite_id` bigint NOT NULL AUTO_INCREMENT COMMENT '收藏记录唯一标识',
  `user_id` bigint NOT NULL COMMENT '用户ID，关联user.user_id',
  `product_id` bigint NOT NULL COMMENT '商品ID，关联product.product_id',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`favorite_id`) USING BTREE,
  UNIQUE INDEX `user_product_unique`(`user_id`, `product_id`) USING BTREE COMMENT '用户对同一商品只能收藏一次',
  INDEX `product_id`(`product_id`) USING BTREE,
  CONSTRAINT `favorite_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `favorite_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 59 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储用户收藏的商品信息' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of favorite
-- ----------------------------
INSERT INTO `favorite` VALUES (12, 1, 2, '2025-12-25 01:06:42');
INSERT INTO `favorite` VALUES (15, 1, 4, '2025-12-27 19:07:00');
INSERT INTO `favorite` VALUES (20, 1, 5, '2025-12-28 00:05:32');
INSERT INTO `favorite` VALUES (21, 1, 6, '2025-12-28 20:33:59');
INSERT INTO `favorite` VALUES (22, 1, 1, '2025-12-29 21:43:30');
INSERT INTO `favorite` VALUES (23, 1, 3, '2025-12-29 21:43:35');
INSERT INTO `favorite` VALUES (31, 7, 7, '2026-02-08 01:06:51');
INSERT INTO `favorite` VALUES (42, 7, 4, '2026-02-08 19:06:54');
INSERT INTO `favorite` VALUES (43, 7, 5, '2026-02-08 19:07:42');
INSERT INTO `favorite` VALUES (50, 7, 3, '2026-02-08 19:36:28');
INSERT INTO `favorite` VALUES (51, 11, 1, '2026-02-09 20:13:20');
INSERT INTO `favorite` VALUES (56, 7, 2, '2026-03-17 21:10:30');
INSERT INTO `favorite` VALUES (57, 7, 6, '2026-03-17 21:16:34');
INSERT INTO `favorite` VALUES (58, 7, 1, '2026-03-17 21:35:21');

-- ----------------------------
-- Table structure for inventory
-- ----------------------------
DROP TABLE IF EXISTS `inventory`;
CREATE TABLE `inventory`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '库存ID',
  `product_id` bigint NOT NULL COMMENT '商品ID',
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '商品名称',
  `product_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '商品类型(new:全新, used:二手, rental:租赁)',
  `sku_id` bigint NOT NULL COMMENT 'SKU ID',
  `sku_attribute` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT 'SKU属性',
  `sku_value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT 'SKU值',
  `current_stock` int NOT NULL COMMENT '当前库存',
  `min_stock` int NOT NULL DEFAULT 10 COMMENT '安全库存',
  `sales` int NOT NULL DEFAULT 0 COMMENT '销量',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_product_id`(`product_id`) USING BTREE,
  INDEX `idx_sku_id`(`sku_id`) USING BTREE,
  INDEX `idx_product_type`(`product_type`) USING BTREE,
  INDEX `idx_min_stock`(`min_stock`) USING BTREE,
  INDEX `idx_current_stock`(`current_stock`) USING BTREE,
  INDEX `idx_last_update_time`(`last_update_time`) USING BTREE,
  INDEX `idx_product_name`(`product_name`(100)) USING BTREE,
  CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_inventory_sku` FOREIGN KEY (`sku_id`) REFERENCES `sku` (`sku_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '库存表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of inventory
-- ----------------------------
INSERT INTO `inventory` VALUES (1, 1, '尼康 Z6II', 'new', 1, '颜色', '黑色', 82, 11, 120, '2026-01-02 19:43:23', '2026-04-08 21:01:18');
INSERT INTO `inventory` VALUES (2, 2, '尼康 Z 24-120 F4S', 'new', 2, '版本', '国行', 9, 10, 95, '2026-01-02 19:43:23', '2026-01-11 16:32:51');
INSERT INTO `inventory` VALUES (3, 3, '索尼 A7R5', 'new', 3, '套餐', '单机', 99, 10, 88, '2026-01-02 19:43:23', '2026-01-02 20:49:41');
INSERT INTO `inventory` VALUES (4, 4, '尼康 D850', 'used', 4, '成色', '95新', 4, 5, 45, '2026-01-02 19:43:23', '2026-01-11 16:25:57');
INSERT INTO `inventory` VALUES (5, 5, '尼康 Z6', 'used', 5, '成色', '90新', 9, 10, 67, '2026-01-02 19:43:23', '2026-01-11 16:25:17');
INSERT INTO `inventory` VALUES (6, 6, '尼康 ZR', 'rental', 6, '状态', '可租', 10, 5, 32, '2026-01-02 19:43:23', '2026-03-17 21:21:48');
INSERT INTO `inventory` VALUES (7, 7, '尼康 Z 70-200mm f2.8 VR S', 'rental', 7, '状态', '可租', 11, 20, 56, '2026-01-02 19:43:23', '2026-01-11 16:26:30');
INSERT INTO `inventory` VALUES (9, 8, '尼康 Z8', 'new', 11, '默认', '默认', 88, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (10, 15, '尼康 Z8', 'new', 12, '默认', '默认', 88, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (11, 20, '尼康 z8', 'new', 13, '默认', '默认', 8555, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (12, 21, '索尼 A7M4', 'new', 14, '默认', '默认', 220, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (13, 22, '尼康 Z72', 'used', 15, '默认', '默认', 72, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (14, 23, '尼康 ZR', 'new', 9, '默认', '默认', 111, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (15, 24, '尼康 Z63', 'new', 16, '默认', '默认', -137, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (16, 25, '尼克尔 50mm F1.8 S', 'new', 17, '默认', '默认', 90, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (17, 26, '佳能 EOS R5 Mark II', 'used', 18, '默认', '默认', 88, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (18, 27, '大疆-Action Action 4', 'new', 19, '默认', '默认', 200, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (19, 28, '佳能 EOS R6 Mark II', 'new', 20, '默认', '默认', 99, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (20, 29, '索尼 ZV-E1', 'new', 21, '默认', '默认', 99, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (21, 30, '大疆-Action ACTION 4', 'used', 22, '默认', '默认', 0, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (22, 31, '大疆-Action ACTION 6', 'new', 23, '默认', '默认', 22, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (23, 32, '大疆 Mavic 4 Pro', 'new', 24, '默认', '默认', 82, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `inventory` VALUES (24, 33, '索尼 Mavic 3 Pro', 'rental', 26, '默认', '默认', 2, 10, 0, '2026-04-11 01:30:41', '2026-04-11 01:30:41');
INSERT INTO `inventory` VALUES (25, 34, '索尼 FE 24-70mm F2.8 GM II', 'rental', 27, '默认', '默认', 66, 10, 0, '2026-04-11 01:32:44', '2026-04-11 01:32:44');
INSERT INTO `inventory` VALUES (26, 35, '索尼 A7M4', 'rental', 28, '默认', '默认', 3, 10, 0, '2026-04-11 01:34:24', '2026-04-11 01:34:24');
INSERT INTO `inventory` VALUES (27, 36, '富士 X-T4', 'rental', 29, '默认', '默认', 50, 10, 0, '2026-04-11 01:37:35', '2026-04-11 01:37:35');
INSERT INTO `inventory` VALUES (28, 37, '大疆 Mini 4K', 'rental', 30, '默认', '默认', 88, 10, 0, '2026-04-11 01:40:28', '2026-04-11 01:40:28');
INSERT INTO `inventory` VALUES (29, 38, '佳能 EOS R6 Mark II', 'rental', 31, '默认', '默认', 88, 10, 0, '2026-04-11 01:41:35', '2026-04-11 01:41:35');
INSERT INTO `inventory` VALUES (30, 39, '佳能 EF 50mm F1.2 L USM', 'rental', 32, '默认', '默认', 5555, 10, 0, '2026-04-11 01:42:46', '2026-04-11 01:42:46');
INSERT INTO `inventory` VALUES (31, 40, '尼康 Z63', 'rental', 33, '默认', '默认', 63, 10, 0, '2026-04-11 01:44:45', '2026-04-11 01:44:45');
INSERT INTO `inventory` VALUES (32, 41, '尼克尔 尼克尔 Z 24-70mm F4 S', 'rental', 34, '默认', '默认', 11, 10, 0, '2026-04-11 01:47:17', '2026-04-11 01:47:17');

-- ----------------------------
-- Table structure for inventory_history
-- ----------------------------
DROP TABLE IF EXISTS `inventory_history`;
CREATE TABLE `inventory_history`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '历史记录ID',
  `inventory_id` bigint NOT NULL COMMENT '库存ID',
  `change_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变更时间',
  `change_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '变更类型(增加, 减少, 直接设置)',
  `before_stock` int NOT NULL COMMENT '变更前库存',
  `after_stock` int NOT NULL COMMENT '变更后库存',
  `change_quantity` int NOT NULL COMMENT '变更数量',
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '变更原因',
  `operator` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作人',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_inventory_id`(`inventory_id`) USING BTREE,
  INDEX `idx_change_time`(`change_time`) USING BTREE,
  INDEX `idx_change_type`(`change_type`) USING BTREE,
  INDEX `idx_operator`(`operator`) USING BTREE,
  CONSTRAINT `fk_inventory_history_inventory` FOREIGN KEY (`inventory_id`) REFERENCES `inventory` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 34 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '库存历史记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of inventory_history
-- ----------------------------
INSERT INTO `inventory_history` VALUES (1, 7, '2026-01-02 20:05:55', '减少', 20, 0, -20, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (2, 7, '2026-01-02 20:06:15', '增加', 0, 21, 21, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (3, 3, '2026-01-02 20:06:18', '减少', 99, 0, -99, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (4, 1, '2026-01-02 20:20:56', '增加', 72, 77, 5, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (5, 1, '2026-01-02 20:20:56', '增加', 72, 77, 5, '', '管理员');
INSERT INTO `inventory_history` VALUES (6, 1, '2026-01-02 20:23:50', '减少', 77, 72, -5, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (15, 1, '2026-01-02 20:42:15', '增加', 72, 77, 5, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (16, 1, '2026-01-02 20:42:16', '增加', 72, 77, 5, '', '管理员');
INSERT INTO `inventory_history` VALUES (17, 1, '2026-01-02 20:42:41', '减少', 77, 72, -5, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (18, 1, '2026-01-02 20:43:43', '增加', 72, 77, 5, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (20, 1, '2026-01-02 20:47:08', '减少', 77, 72, -5, '自动记录库存变更', '系统');
INSERT INTO `inventory_history` VALUES (22, 1, '2026-01-02 20:53:43', '增加', 72, 77, 5, '', '管理员');
INSERT INTO `inventory_history` VALUES (23, 2, '2026-01-08 22:19:49', '直接设置', 87, 9, -78, '', '管理员');
INSERT INTO `inventory_history` VALUES (24, 2, '2026-01-08 22:20:48', '增加', 9, 109, 100, '', '管理员');
INSERT INTO `inventory_history` VALUES (25, 6, '2026-01-08 22:21:56', '减少', 6, 4, 2, '', '管理员');
INSERT INTO `inventory_history` VALUES (26, 5, '2026-01-11 16:25:18', '直接设置', 55, 9, -46, '', '管理员');
INSERT INTO `inventory_history` VALUES (27, 4, '2026-01-11 16:25:49', '直接设置', 4, 666, 662, '', '管理员');
INSERT INTO `inventory_history` VALUES (28, 4, '2026-01-11 16:25:57', '直接设置', 666, 4, -662, '', '管理员');
INSERT INTO `inventory_history` VALUES (29, 7, '2026-01-11 16:26:30', '直接设置', 20, 11, -9, '', '管理员');
INSERT INTO `inventory_history` VALUES (30, 6, '2026-01-11 16:26:58', '直接设置', 44, 4, -40, '', '管理员');
INSERT INTO `inventory_history` VALUES (31, 6, '2026-03-17 21:20:30', '增加', 4, 9, 5, '', '管理员');
INSERT INTO `inventory_history` VALUES (32, 6, '2026-03-17 21:21:49', '增加', 9, 10, 1, '', '管理员');
INSERT INTO `inventory_history` VALUES (33, 1, '2026-04-08 21:01:19', '增加', 77, 82, 5, '', '管理员');

-- ----------------------------
-- Table structure for order_item
-- ----------------------------
DROP TABLE IF EXISTS `order_item`;
CREATE TABLE `order_item`  (
  `item_id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单项唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联order.order_id，订单删除时同步删除订单项',
  `product_id` bigint NOT NULL COMMENT '关联product.product_id，商品下架不影响已生成订单项',
  `quantity` int NOT NULL DEFAULT 1 COMMENT '商品数量（购买 / 二手场景）或租赁数量（租赁场景）',
  `unit_price` decimal(12, 2) NOT NULL DEFAULT 0.00 COMMENT '商品单价（下单时的价格，不受后续商品调价影响）',
  `deposit` decimal(12, 2) NULL DEFAULT 0.00 COMMENT '租赁押金（仅租赁场景用，按器材价值 50%-80% 计算，会员享减免）',
  `freight` decimal(10, 2) NULL DEFAULT 0.00 COMMENT '运费（购买 / 二手场景，租赁场景可为 0，自提）	',
  `item_status` tinyint NOT NULL DEFAULT 0 COMMENT '订单项状态：0 - 待履约，1 - 已发货 / 已出租，2 - 已完成，3 - 售后中',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '订单项创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '订单项状态更新时间',
  `lease_term` int NULL DEFAULT NULL COMMENT '租赁天数',
  PRIMARY KEY (`item_id`) USING BTREE,
  INDEX `order_id`(`order_id`, `product_id`, `item_status`) USING BTREE,
  INDEX `product_id`(`product_id`) USING BTREE,
  CONSTRAINT `order_item_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `order_item_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 79 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储订单中的商品明细（如多件商品合并下单），与order一对多关联，支持分商品履约。\r\n' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of order_item
-- ----------------------------
INSERT INTO `order_item` VALUES (60, 54, 1, 1, 9200.00, 0.00, 0.00, 3, '2026-01-22 23:24:26', '2026-01-23 00:36:49', NULL);
INSERT INTO `order_item` VALUES (61, 55, 1, 1, 9200.00, 0.00, 0.00, 3, '2026-01-23 00:32:45', '2026-04-07 16:46:03', NULL);
INSERT INTO `order_item` VALUES (62, 56, 1, 1, 9200.00, 0.00, 0.00, 3, '2026-02-08 00:42:57', '2026-03-07 21:41:48', NULL);
INSERT INTO `order_item` VALUES (63, 57, 1, 1, 9200.00, 0.00, 0.00, 4, '2026-02-08 17:38:18', '2026-02-08 17:38:30', NULL);
INSERT INTO `order_item` VALUES (64, 58, 6, 1, 120.09, 1399.90, 0.00, 2, '2026-02-09 20:13:50', '2026-02-09 20:26:47', NULL);
INSERT INTO `order_item` VALUES (65, 59, 2, 1, 7999.00, 0.00, 0.00, 3, '2026-02-09 20:26:18', '2026-02-09 20:38:11', NULL);
INSERT INTO `order_item` VALUES (66, 60, 5, 1, 5555.00, 0.00, 0.00, 1, '2026-02-09 20:40:42', '2026-02-09 20:40:44', NULL);
INSERT INTO `order_item` VALUES (67, 61, 1, 1, 9200.00, 0.00, 0.00, 1, '2026-02-26 22:19:51', '2026-02-26 22:19:58', NULL);
INSERT INTO `order_item` VALUES (68, 62, 6, 5, 120.09, 1399.90, 0.00, 1, '2026-03-17 21:11:37', '2026-03-17 21:11:50', NULL);
INSERT INTO `order_item` VALUES (69, 63, 7, 1, 100.00, 1499.90, 0.00, 1, '2026-03-17 21:17:50', '2026-03-17 21:17:53', NULL);
INSERT INTO `order_item` VALUES (70, 64, 7, 1, 100.00, 1499.90, 0.00, 1, '2026-03-17 21:18:20', '2026-03-17 21:18:23', NULL);
INSERT INTO `order_item` VALUES (71, 65, 1, 1, 9200.00, 0.00, 0.00, 3, '2026-03-17 21:35:49', '2026-03-17 21:37:03', NULL);
INSERT INTO `order_item` VALUES (72, 66, 1, 1, 9200.00, 0.00, 0.00, 4, '2026-03-17 21:39:39', '2026-04-07 15:21:00', NULL);
INSERT INTO `order_item` VALUES (74, 68, 1, 2, 9200.00, 0.00, 0.00, 5, '2026-04-07 17:52:48', '2026-04-07 17:53:29', NULL);
INSERT INTO `order_item` VALUES (75, 69, 25, 5, 3299.00, 0.00, 0.00, 5, '2026-04-07 17:54:45', '2026-04-07 17:55:18', NULL);
INSERT INTO `order_item` VALUES (76, 70, 21, 1, 14999.00, 0.00, 0.00, 5, '2026-04-07 17:56:37', '2026-04-07 17:56:48', NULL);
INSERT INTO `order_item` VALUES (77, 71, 24, 100, 14449.00, 0.00, 0.00, 5, '2026-04-07 17:57:24', '2026-04-07 17:57:33', NULL);
INSERT INTO `order_item` VALUES (78, 72, 1, 199, 9200.00, 0.00, 0.00, 5, '2026-04-07 17:57:50', '2026-04-07 17:58:16', NULL);
INSERT INTO `order_item` VALUES (79, 73, 30, 1, 999.00, 0.00, 0.00, 3, '2026-04-11 00:18:03', '2026-04-11 00:18:43', NULL);
INSERT INTO `order_item` VALUES (80, 74, 7, 1, 100.00, 1499.90, 0.00, 3, '2026-04-11 00:21:04', '2026-04-11 00:23:02', NULL);
INSERT INTO `order_item` VALUES (81, 75, 32, 1, 18999.00, 0.00, 0.00, 4, '2026-04-11 00:24:11', '2026-04-11 00:24:32', NULL);
INSERT INTO `order_item` VALUES (82, 76, 32, 3, 18999.00, 0.00, 0.00, 3, '2026-04-11 00:24:39', '2026-04-11 00:25:13', NULL);
INSERT INTO `order_item` VALUES (83, 77, 6, 1, 120.09, 1399.90, 0.00, 5, '2026-04-11 00:50:07', '2026-04-11 00:50:20', NULL);
INSERT INTO `order_item` VALUES (84, 78, 6, 1, 120.09, 1399.90, 0.00, 3, '2026-04-11 00:50:30', '2026-04-11 00:51:30', NULL);
INSERT INTO `order_item` VALUES (85, 79, 6, 1, 120.09, 1399.90, 0.00, 5, '2026-04-11 00:55:21', '2026-04-11 00:56:10', NULL);
INSERT INTO `order_item` VALUES (86, 80, 7, 1, 100.00, 1499.90, 0.00, 3, '2026-04-11 01:01:15', '2026-04-11 01:02:25', NULL);
INSERT INTO `order_item` VALUES (87, 81, 6, 1, 120.09, 1399.90, 0.00, 2, '2026-04-11 01:03:01', '2026-04-11 01:03:30', NULL);

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders`  (
  `order_id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单唯一标识',
  `order_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '订单编号',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `seller_id` bigint NOT NULL COMMENT '商家ID，关联user.user_id',
  `total_amount` decimal(12, 2) NOT NULL DEFAULT 0.00 COMMENT '订单总金额',
  `shipping_fee` decimal(12, 2) NOT NULL DEFAULT 0.00 COMMENT '运费',
  `pay_amount` decimal(12, 2) NOT NULL DEFAULT 0.00 COMMENT '实付金额',
  `order_status` tinyint NOT NULL DEFAULT 0 COMMENT '订单状态：0-待支付，1-已支付，2-已发货，3-已完成，4-已取消',
  `payment_method` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '支付方式',
  `address_id` bigint NULL DEFAULT NULL COMMENT '收货地址ID',
  `recipient` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '收件人',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '联系电话',
  `province` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '省份',
  `city` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '城市',
  `district` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '区/县',
  `detail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '详细地址',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `pay_time` datetime NULL DEFAULT NULL COMMENT '支付时间',
  `transaction_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '支付流水号',
  PRIMARY KEY (`order_id`) USING BTREE,
  UNIQUE INDEX `order_no`(`order_no`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  INDEX `orders_ibfk_2`(`address_id`) USING BTREE,
  INDEX `orders_ibfk_3`(`seller_id`) USING BTREE,
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `user_address` (`address_id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`seller_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 73 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of orders
-- ----------------------------
INSERT INTO `orders` VALUES (54, 'ORD2601222324263185720001', 7, 8, 9200.00, 0.00, 9200.00, 3, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-01-22 23:24:26', '2026-01-23 00:36:49', NULL, NULL);
INSERT INTO `orders` VALUES (55, 'ORD2601230032452411440001', 7, 8, 9200.00, 0.00, 9200.00, 3, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-01-23 00:32:45', '2026-04-07 16:46:03', NULL, NULL);
INSERT INTO `orders` VALUES (56, 'ORD2602080042573563520001', 7, 8, 9200.00, 0.00, 9200.00, 3, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-02-08 00:42:57', '2026-03-07 21:41:48', NULL, NULL);
INSERT INTO `orders` VALUES (57, 'ORD2602081738176351120001', 7, 8, 9200.00, 0.00, 9200.00, 4, 'online', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-02-08 17:38:18', '2026-02-08 17:38:30', NULL, NULL);
INSERT INTO `orders` VALUES (58, 'ORD2602092013502041560001', 11, 8, 2240.53, 0.00, 2240.53, 2, 'wechat', 18, '111', '18344551994', '11', '1101', '110101', '111', '2026-02-09 20:13:50', '2026-02-09 20:26:47', NULL, NULL);
INSERT INTO `orders` VALUES (59, 'ORD2602092026175626320001', 11, 8, 7999.00, 0.00, 7999.00, 3, 'wechat', 18, '111', '18344551994', '11', '1101', '110101', '111', '2026-02-09 20:26:18', '2026-02-09 20:38:11', '2026-02-09 20:26:20', 'TXN1770639980194_59');
INSERT INTO `orders` VALUES (60, 'ORD2602092040416936320002', 11, 8, 5555.00, 0.00, 5555.00, 1, 'wechat', 18, '111', '18344551994', '11', '1101', '110101', '111', '2026-02-09 20:40:42', '2026-02-09 20:40:44', '2026-02-09 20:40:44', 'TXN1770640843753_60');
INSERT INTO `orders` VALUES (61, 'ORD2602262219506819920001', 7, 8, 9200.00, 0.00, 9200.00, 1, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-02-26 22:19:51', '2026-02-26 22:19:58', '2026-02-26 22:19:58', 'TXN1772115597653_61');
INSERT INTO `orders` VALUES (62, 'ORD2603172111368371280001', 7, 8, 11202.65, 0.00, 11202.65, 1, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-03-17 21:11:37', '2026-03-17 21:11:50', '2026-03-17 21:11:50', 'TXN1773753109564_62');
INSERT INTO `orders` VALUES (63, 'ORD2603172117502881280002', 7, 8, 1799.90, 0.00, 1799.90, 1, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-03-17 21:17:50', '2026-03-17 21:17:53', '2026-03-17 21:17:53', 'TXN1773753472965_63');
INSERT INTO `orders` VALUES (64, 'ORD2603172118201101280003', 7, 8, 1799.90, 0.00, 1799.90, 1, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-03-17 21:18:20', '2026-03-17 21:18:23', '2026-03-17 21:18:23', 'TXN1773753503085_64');
INSERT INTO `orders` VALUES (65, 'ORD2603172135491762320001', 7, 8, 9200.00, 0.00, 9200.00, 3, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-03-17 21:35:49', '2026-03-17 21:37:03', '2026-03-17 21:36:04', 'TXN1773754563779_65');
INSERT INTO `orders` VALUES (66, 'ORD2603172139389312320002', 7, 8, 9200.00, 0.00, 9200.00, 4, 'online', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-03-17 21:39:39', '2026-04-07 15:21:00', NULL, NULL);
INSERT INTO `orders` VALUES (68, 'ORD2604071752477505240001', 7, 8, 18400.00, 0.00, 18400.00, 7, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-07 17:52:48', '2026-04-07 17:53:29', '2026-04-07 17:52:53', 'TXN1775555572645_68');
INSERT INTO `orders` VALUES (69, 'ORD2604071754446915240002', 7, 8, 16495.00, 0.00, 16495.00, 6, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-07 17:54:45', '2026-04-07 17:55:18', '2026-04-07 17:54:47', 'TXN1775555687281_69');
INSERT INTO `orders` VALUES (70, 'ORD2604071756373235240003', 7, 8, 14999.00, 0.00, 14999.00, 5, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-07 17:56:37', '2026-04-07 17:56:48', '2026-04-07 17:56:42', 'TXN1775555801538_70');
INSERT INTO `orders` VALUES (71, 'ORD2604071757238925240004', 7, 19, 1444900.00, 0.00, 1444900.00, 5, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-07 17:57:24', '2026-04-07 17:57:33', '2026-04-07 17:57:28', 'TXN1775555847986_71');
INSERT INTO `orders` VALUES (72, 'ORD2604071757498845240005', 7, 8, 1830800.00, 0.00, 1830800.00, 7, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-07 17:57:50', '2026-04-07 17:58:16', '2026-04-07 17:57:53', 'TXN1775555872849_72');
INSERT INTO `orders` VALUES (73, 'ORD2604110018032950760001', 7, 8, 999.00, 0.00, 999.00, 3, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:18:03', '2026-04-11 00:18:43', '2026-04-11 00:18:08', 'TXN1775837887692_73');
INSERT INTO `orders` VALUES (74, 'ORD2604110021040350760002', 7, 8, 3699.90, 0.00, 3699.90, 3, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:21:04', '2026-04-11 00:23:02', '2026-04-11 00:21:10', 'TXN1775838069529_74');
INSERT INTO `orders` VALUES (75, 'ORD2604110024111560760003', 7, 8, 18999.00, 0.00, 18999.00, 4, 'online', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:24:11', '2026-04-11 00:24:32', NULL, NULL);
INSERT INTO `orders` VALUES (76, 'ORD2604110024391070760004', 7, 8, 56997.00, 0.00, 56997.00, 3, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:24:39', '2026-04-11 00:25:13', '2026-04-11 00:24:45', 'TXN1775838284667_76');
INSERT INTO `orders` VALUES (77, 'ORD2604110050071717440001', 7, 8, 4402.15, 0.00, 4402.15, 5, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:50:07', '2026-04-11 00:50:20', '2026-04-11 00:50:11', 'TXN1775839811170_77');
INSERT INTO `orders` VALUES (78, 'ORD2604110050303197440002', 7, 8, 4642.33, 0.00, 4642.33, 3, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:50:30', '2026-04-11 00:51:30', '2026-04-11 00:50:34', 'TXN1775839833517_78');
INSERT INTO `orders` VALUES (79, 'ORD2604110055214447440003', 7, 8, 5362.87, 0.00, 5362.87, 9, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 00:55:21', '2026-04-11 00:56:10', '2026-04-11 00:55:27', 'TXN1775840126564_79');
INSERT INTO `orders` VALUES (80, 'ORD2604110101153077440004', 7, 8, 2499.90, 0.00, 2499.90, 3, 'wechat', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 01:01:15', '2026-04-11 01:02:25', '2026-04-11 01:01:21', 'TXN1775840480670_80');
INSERT INTO `orders` VALUES (81, 'ORD2604110103012297440005', 7, 8, 5362.87, 0.00, 5362.87, 2, 'alipay', 17, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', '2026-04-11 01:03:01', '2026-04-11 01:03:30', '2026-04-11 01:03:07', 'TXN1775840586757_81');

-- ----------------------------
-- Table structure for payment
-- ----------------------------
DROP TABLE IF EXISTS `payment`;
CREATE TABLE `payment`  (
  `payment_id` bigint NOT NULL AUTO_INCREMENT COMMENT '支付记录ID',
  `order_id` bigint NOT NULL COMMENT '订单ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `amount` decimal(12, 2) NOT NULL COMMENT '支付金额',
  `payment_method` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '支付方式',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '支付状态：0-待支付，1-成功，2-失败',
  `qr_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '支付二维码',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`payment_id`) USING BTREE,
  INDEX `order_id`(`order_id`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of payment
-- ----------------------------

-- ----------------------------
-- Table structure for permission
-- ----------------------------
DROP TABLE IF EXISTS `permission`;
CREATE TABLE `permission`  (
  `permission_id` int NOT NULL AUTO_INCREMENT COMMENT '权限唯一标识',
  `permission_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '权限名称（如 “商品审核”“订单删除”“数据统计查看”）',
  `permission_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '权限编码（如 “PRODUCT_AUDIT”“ORDER_DELETE”“STAT_VIEW”）',
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '权限对应的后端接口 URL（如 “/admin/product/audit”“/admin/order/delete”）',
  `method` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '接口请求方式（如 “GET”“POST”“PUT”“DELETE”）',
  `parent_id` int NULL DEFAULT NULL COMMENT '外键,父权限 ID（用于权限层级，如 “商品管理” 是 “商品审核” 的父权限，NULL 表示顶级权限）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '权限创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '权限信息更新时间',
  PRIMARY KEY (`permission_id`) USING BTREE,
  UNIQUE INDEX `permission_name`(`permission_name`, `permission_code`) USING BTREE,
  INDEX `parent_id`(`parent_id`) USING BTREE,
  CONSTRAINT `permission_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `permission` (`permission_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 131 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储系统功能权限（如商品审核、订单查看、数据统计），与role通过中间表关联。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of permission
-- ----------------------------
INSERT INTO `permission` VALUES (42, '系统权限', 'SYSTEM_ROOT', '/', '*', NULL, '2026-01-04 22:22:51', '2026-01-04 22:22:51');
INSERT INTO `permission` VALUES (89, '系统管理', 'SYSTEM_MANAGE', '/super-admin/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (90, '管理员管理', 'ADMIN_MANAGE', '/super-admin/admins/**', '*', 89, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (91, '权限管理', 'PERMISSION_MANAGE', '/super-admin/permissions/**', '*', 89, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (92, '角色管理', 'ROLE_MANAGE', '/super-admin/roles/**', '*', 89, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (93, '系统配置', 'SYSTEM_CONFIG', '/super-admin/config/**', '*', 89, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (94, '操作日志', 'SYSTEM_LOG', '/super-admin/logs/**', '*', 89, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (95, '用户管理', 'USER_MANAGE', '/admin/users/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (96, '用户查看', 'USER_VIEW', '/admin/users', 'GET', 95, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (97, '用户详情', 'USER_DETAIL', '/admin/users/{userId}', 'GET', 95, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (98, '用户状态更新', 'USER_STATUS_UPDATE', '/admin/users/{userId}/status', 'PUT', 95, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (99, '用户信息更新', 'USER_INFO_UPDATE', '/admin/users/{userId}', 'PUT', 95, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (100, '用户删除', 'USER_DELETE', '/admin/users/{userId}', 'DELETE', 95, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (101, '商家管理', 'MERCHANT_MANAGE', '/admin/merchants/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (102, '商家列表查看', 'MERCHANT_LIST_VIEW', '/admin/merchants', 'GET', 101, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (103, '商家审核列表', 'MERCHANT_AUDIT_LIST', '/admin/merchants/audit', 'GET', 101, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (104, '商家详情', 'MERCHANT_DETAIL', '/admin/merchants/{merchantId}', 'GET', 101, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (105, '商家审核', 'MERCHANT_AUDIT', '/admin/merchants/{merchantId}/audit', 'PUT', 101, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (106, '商家状态更新', 'MERCHANT_STATUS_UPDATE', '/admin/merchants/{merchantId}/status', 'PUT', 101, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (107, '商家禁用', 'MERCHANT_DISABLE', '/admin/merchants/{merchantId}/disable', 'PUT', 101, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (108, '商品管理', 'PRODUCT_MANAGE', '/admin/products/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (109, '商品列表查看', 'PRODUCT_LIST_VIEW', '/admin/products', 'GET', 108, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (110, '商品审核列表', 'PRODUCT_AUDIT_LIST', '/admin/products/audit', 'GET', 108, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (111, '商品详情', 'PRODUCT_DETAIL', '/admin/products/{productId}', 'GET', 108, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (112, '商品审核', 'PRODUCT_AUDIT', '/admin/products/{productId}/audit', 'PUT', 108, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (113, '商品上架/下架', 'PRODUCT_SHELF', '/admin/products/{productId}/shelf', 'PUT', 108, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (114, '商品删除', 'PRODUCT_DELETE', '/admin/products/{productId}', 'DELETE', 108, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (115, '分类管理', 'CATEGORY_MANAGE', '/admin/categories/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (116, '分类树查看', 'CATEGORY_TREE_VIEW', '/admin/categories/tree', 'GET', 115, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (117, '分类添加', 'CATEGORY_ADD', '/admin/categories', 'POST', 115, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (118, '分类更新', 'CATEGORY_UPDATE', '/admin/categories/{categoryId}', 'PUT', 115, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (119, '分类删除', 'CATEGORY_DELETE', '/admin/categories/{categoryId}', 'DELETE', 115, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (120, '公告管理', 'NOTICE_MANAGE', '/admin/notices/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (121, '公告列表查看', 'NOTICE_LIST_VIEW', '/admin/notices', 'GET', 120, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (122, '公告详情', 'NOTICE_DETAIL', '/admin/notices/{noticeId}', 'GET', 120, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (123, '公告添加', 'NOTICE_ADD', '/admin/notices', 'POST', 120, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (124, '公告更新', 'NOTICE_UPDATE', '/admin/notices/{noticeId}', 'PUT', 120, '2026-03-08 01:07:05', '2026-03-08 02:36:22');
INSERT INTO `permission` VALUES (125, '公告删除', 'NOTICE_DELETE', '/admin/notices/{noticeId}', 'DELETE', 120, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (126, '公告发布', 'NOTICE_PUBLISH', '/admin/notices/{noticeId}/publish', 'PUT', 120, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (127, '数据统计', 'STATISTICS_MANAGE', '/admin/statistics/**', '*', 42, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (128, '仪表盘数据', 'DASHBOARD_VIEW', '/admin/dashboard', 'GET', 127, '2026-03-08 01:07:05', '2026-03-08 01:07:05');
INSERT INTO `permission` VALUES (129, '超级管理员仪表盘', 'SUPER_ADMIN_DASHBOARD', '/admin/super-admin/dashboard', 'GET', 127, '2026-03-08 01:07:05', '2026-03-08 01:07:05');

-- ----------------------------
-- Table structure for product
-- ----------------------------
DROP TABLE IF EXISTS `product`;
CREATE TABLE `product`  (
  `product_id` bigint NOT NULL AUTO_INCREMENT COMMENT '商品唯一标识',
  `category_id` int NOT NULL COMMENT '外键，商品分类 ID（关联product_category.category_id，如 1 - 相机、2 - 镜头）',
  `brand` int NOT NULL COMMENT '器材品牌（如佳能、索尼、尼康）',
  `model` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '器材型号（如佳能 R5、索尼 24-70F2.8）',
  `product_type` tinyint NOT NULL COMMENT '商品类型：1 - 全新器材，2 - 二手器材，3 - 租赁专用器材',
  `condition` tinyint NULL DEFAULT NULL COMMENT '成色（仅二手 / 租赁用）：1-99 新，2-95 新，3-9 新，4-8 新',
  `original_price` decimal(12, 2) NOT NULL COMMENT '原价',
  `price` decimal(12, 2) NOT NULL COMMENT '售价（全新 / 二手）或租赁单价（元 / 天，租赁专用）',
  `min_rental_days` int NULL DEFAULT 3 COMMENT '最短租赁期限（天）',
  `stock` int NOT NULL DEFAULT 0 COMMENT '库存数量（租赁专用器材为 “可租数量”）',
  `seller_id` bigint NOT NULL COMMENT '外键,商家 ID（关联user.user_id，仅企业用户可作为卖家）',
  `audit_status` tinyint NOT NULL DEFAULT 0 COMMENT '审核状态：0 - 待审核，1 - 审核通过，2 - 审核驳回（管理员审核）',
  `reject_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '审核驳回原因（如 “缺少保修证明”）',
  `is_on_shelf` tinyint NOT NULL DEFAULT 0 COMMENT '是否上架：0 - 下架，1 - 上架（审核通过后可手动上架）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '商品创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '商品信息更新时间',
  `min_stock` int NOT NULL DEFAULT 10 COMMENT '安全库存数量（库存低于此值时系统自动提醒补货）',
  `color` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '商品颜色（仅全新商品使用）',
  PRIMARY KEY (`product_id`) USING BTREE,
  INDEX `category_id`(`category_id`, `brand`, `model`, `product_type`, `condition`, `stock`, `seller_id`, `audit_status`, `is_on_shelf`) USING BTREE,
  INDEX `seller_id`(`seller_id`) USING BTREE,
  INDEX `brand`(`brand`) USING BTREE,
  INDEX `stock`(`stock`) USING BTREE,
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `product_category` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_ibfk_2` FOREIGN KEY (`seller_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_ibfk_3` FOREIGN KEY (`brand`) REFERENCES `brand` (`brand_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 26 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储摄影器材的核心基础信息，区分全新 / 二手 / 租赁三种商品类型，是商品管理与交易的核心表。\r\n备注：全新器材需关联品牌授权证明（存储于product_detail），否则audit_status驳回；库存低于 5 件时，系统自动提醒seller_id对应的商家补货。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of product
-- ----------------------------
INSERT INTO `product` VALUES (1, 11, 11, 'Z62', 1, NULL, 13999.00, 9200.00, NULL, 82, 8, 1, NULL, 1, '2026-04-08 21:01:18', '2026-04-11 02:11:08', 10, '');
INSERT INTO `product` VALUES (2, 21, 21, 'Z 24-120 F4S', 1, NULL, 8999.00, 7999.00, NULL, 7, 8, 1, NULL, 1, '2026-01-11 16:32:51', '2026-01-11 16:32:51', 10, '默认颜色');
INSERT INTO `product` VALUES (3, 11, 12, 'A7R5', 1, NULL, 17999.00, 16300.00, NULL, 99, 8, 1, NULL, 1, '2026-01-02 21:39:24', '2026-01-02 21:39:24', 10, '默认颜色');
INSERT INTO `product` VALUES (4, 12, 11, 'D850', 2, 85, 12999.00, 5999.00, NULL, 4, 8, 1, NULL, 1, '2026-01-11 16:25:57', '2026-04-11 02:11:14', 10, '');
INSERT INTO `product` VALUES (5, 11, 11, 'Z6', 2, 95, 12999.00, 5555.00, NULL, 7, 8, 1, NULL, 1, '2026-01-26 17:42:53', '2026-01-26 17:42:53', 10, '');
INSERT INTO `product` VALUES (6, 11, 11, 'ZR', 3, NULL, 13999.00, 120.09, 1, 3, 8, 1, NULL, 1, '2026-03-17 21:21:48', '2026-03-17 21:21:48', 10, '');
INSERT INTO `product` VALUES (7, 21, 21, 'Z 70-200mm f2.8 VR S', 3, NULL, 14999.00, 100.00, 3, 4, 8, 1, NULL, 1, '2026-01-11 16:26:30', '2026-01-11 16:26:30', 10, '');
INSERT INTO `product` VALUES (8, 11, 11, 'Z8', 1, 90, 25999.00, 18999.00, 3, 88, 8, 1, NULL, 1, '2026-01-11 21:15:42', '2026-03-08 01:53:50', 10, '');
INSERT INTO `product` VALUES (15, 11, 11, 'Z8', 1, 90, 25999.00, 15999.00, 3, 88, 8, 2, '111111', 1, '2026-01-22 00:54:16', '2026-04-11 01:35:01', 10, '');
INSERT INTO `product` VALUES (20, 11, 11, 'z8', 1, 90, 28888.00, 18888.00, 3, 8555, 8, 1, NULL, 0, '2026-02-09 22:23:10', '2026-02-09 22:46:49', 10, '');
INSERT INTO `product` VALUES (21, 11, 12, 'A7M4', 1, 90, 19999.00, 14999.00, 3, 220, 8, 1, NULL, 1, '2026-02-09 22:56:07', '2026-02-09 23:40:26', 10, '');
INSERT INTO `product` VALUES (22, 11, 11, 'Z72', 2, 90, 17999.00, 9999.00, 3, 72, 8, 1, NULL, 1, '2026-02-10 00:42:13', '2026-02-10 00:42:13', 10, NULL);
INSERT INTO `product` VALUES (23, 11, 11, 'ZR', 1, 90, 14999.00, 12999.00, 3, 111, 8, 1, NULL, 1, '2026-02-10 00:44:06', '2026-02-10 00:44:06', 10, '');
INSERT INTO `product` VALUES (24, 11, 11, 'Z63', 1, 90, 16999.00, 14449.00, 3, -137, 19, 1, '管理员强制下架', 1, '2026-02-10 01:52:29', '2026-02-10 01:52:29', 10, NULL);
INSERT INTO `product` VALUES (25, 27, 21, '50mm F1.8 S', 1, 90, 3999.00, 3299.00, 3, 90, 8, 1, NULL, 1, '2026-03-08 01:35:03', '2026-03-08 02:00:34', 10, '');
INSERT INTO `product` VALUES (26, 11, 13, 'EOS R5 Mark II', 2, 90, 15999.00, 9999.00, 3, 88, 8, 1, NULL, 1, '2026-04-10 22:31:28', '2026-04-10 22:31:28', 10, NULL);
INSERT INTO `product` VALUES (27, 13, 41, 'Action 4', 1, 90, 1999.00, 1499.00, 3, 200, 8, 1, NULL, 1, '2026-04-10 22:40:07', '2026-04-10 22:40:07', 10, NULL);
INSERT INTO `product` VALUES (28, 11, 13, 'EOS R6 Mark II', 1, 90, 25999.00, 22999.00, 3, 99, 8, 1, NULL, 1, '2026-04-10 22:46:25', '2026-04-10 22:46:25', 10, NULL);
INSERT INTO `product` VALUES (29, 11, 12, 'ZV-E1', 1, 90, 21999.00, 18999.00, 3, 99, 8, 1, NULL, 1, '2026-04-10 22:49:11', '2026-04-10 22:49:11', 10, NULL);
INSERT INTO `product` VALUES (30, 13, 41, 'ACTION 4', 2, 90, 1599.00, 999.00, 3, 0, 8, 1, NULL, 1, '2026-04-10 23:05:35', '2026-04-10 23:05:35', 10, NULL);
INSERT INTO `product` VALUES (31, 13, 41, 'ACTION 6', 1, 90, 2999.00, 2899.00, 3, 22, 8, 1, NULL, 1, '2026-04-10 23:10:59', '2026-04-10 23:10:59', 10, NULL);
INSERT INTO `product` VALUES (32, 32, 37, 'Mavic 4 Pro', 1, 90, 18999.00, 18999.00, 3, 82, 8, 1, NULL, 1, '2026-04-10 23:36:42', '2026-04-10 23:36:42', 10, NULL);
INSERT INTO `product` VALUES (33, 11, 12, 'Mavic 3 Pro', 3, 90, 29999.00, 109.00, 6, 2, 8, 1, NULL, 1, '2026-04-11 01:30:42', '2026-04-11 01:55:55', 10, NULL);
INSERT INTO `product` VALUES (34, 21, 12, 'FE 24-70mm F2.8 GM II', 3, 90, 15999.00, 56.00, 3, 66, 8, 1, NULL, 1, '2026-04-11 01:32:45', '2026-04-11 01:32:45', 10, NULL);
INSERT INTO `product` VALUES (35, 11, 12, 'A7M4', 3, 90, 18999.00, 80.00, 3, 3, 8, 1, NULL, 1, '2026-04-11 01:34:25', '2026-04-11 01:34:25', 10, NULL);
INSERT INTO `product` VALUES (36, 11, 14, 'X-T4', 3, 90, 15999.00, 90.00, 3, 50, 8, 1, NULL, 1, '2026-04-11 01:37:36', '2026-04-11 01:37:36', 10, NULL);
INSERT INTO `product` VALUES (37, 32, 37, 'Mini 4K', 3, 90, 8999.00, 32.00, 3, 88, 8, 1, NULL, 1, '2026-04-11 01:40:28', '2026-04-11 01:40:28', 10, NULL);
INSERT INTO `product` VALUES (38, 11, 13, 'EOS R6 Mark II', 3, 90, 29999.00, 150.00, 3, 88, 8, 1, NULL, 1, '2026-04-11 01:41:35', '2026-04-11 01:41:35', 10, NULL);
INSERT INTO `product` VALUES (39, 27, 23, 'EF 50mm F1.2 L USM', 3, 90, 3000.00, 20.00, 3, 5555, 8, 1, NULL, 1, '2026-04-11 01:42:47', '2026-04-11 01:42:47', 10, NULL);
INSERT INTO `product` VALUES (40, 11, 11, 'Z63', 3, 90, 18999.00, 70.00, 7, 63, 8, 1, NULL, 1, '2026-04-11 01:45:50', '2026-04-11 01:45:50', 10, NULL);
INSERT INTO `product` VALUES (41, 21, 21, '尼克尔 Z 24-70mm F4 S', 3, 90, 4999.00, 40.00, 3, 11, 8, 0, NULL, 0, '2026-04-11 01:47:18', '2026-04-11 01:47:18', 10, NULL);
INSERT INTO `product` VALUES (42, 11, 41, 'ACTION 5 PRO', 3, 90, 2199.00, 21.00, 3, 55, 8, 0, NULL, 0, '2026-04-11 02:09:56', '2026-04-11 02:09:56', 10, NULL);
INSERT INTO `product` VALUES (43, 11, 41, 'ACTION 5 PRO', 3, 90, 2199.00, 21.00, 3, 55, 8, 0, NULL, 0, '2026-04-11 02:10:05', '2026-04-11 02:10:05', 10, NULL);
INSERT INTO `product` VALUES (44, 11, 41, 'ACTION 5 PRO', 1, 90, 2199.00, 2000.00, 3, 55, 8, 0, NULL, 0, '2026-04-11 02:10:45', '2026-04-11 02:10:45', 10, NULL);

-- ----------------------------
-- Table structure for product_category
-- ----------------------------
DROP TABLE IF EXISTS `product_category`;
CREATE TABLE `product_category`  (
  `category_id` int NOT NULL AUTO_INCREMENT COMMENT '分类唯一标识',
  `category_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类名称（如 “相机”“镜头”“三脚架”“灯光设备”）',
  `parent_id` int NULL DEFAULT 0 COMMENT '外键,父分类 ID（如 “全画幅相机” 父分类为 “相机”）',
  `category_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类编码，按层级规则生成（如顶级分类 “相机” 编码为 “CAM”，子分类 “全画幅相机” 编码为 “CAM-FULL”）',
  `sort` int NOT NULL DEFAULT 0 COMMENT '分类排序（数值越小越靠前）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '分类状态：\r\n- 1 = 启用（可被商品关联、前端展示）\r\n- 0 = 禁用（不可关联商品、前端隐藏）',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '分类描述，说明分类涵盖的器材范围（如 “全画幅相机：传感器尺寸为 36×24mm 左右的专业相机”）',
  `create_by` bigint NOT NULL COMMENT '外键,分类创建人 ID，关联user.user_id（仅管理员可创建分类）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类创建时间',
  `update_by` bigint NULL DEFAULT NULL COMMENT '外键,分类更新人 ID，关联user.user_id（仅管理员可更新分类）',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类更新时间',
  PRIMARY KEY (`category_id`) USING BTREE,
  UNIQUE INDEX `category_name`(`category_name`, `category_code`) USING BTREE,
  INDEX `parent_id`(`parent_id`, `sort`, `status`, `create_by`, `update_by`) USING BTREE,
  INDEX `create_by`(`create_by`) USING BTREE,
  INDEX `product_category_ibfk_3`(`update_by`) USING BTREE,
  CONSTRAINT `product_category_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `product_category` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_category_ibfk_2` FOREIGN KEY (`create_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_category_ibfk_3` FOREIGN KEY (`update_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 43 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储摄影器材分类（如相机、镜头、灯光设备），为product提供分类关联。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of product_category
-- ----------------------------
INSERT INTO `product_category` VALUES (1, '相机', NULL, 'CAM', 0, 1, '', 1, '2026-01-06 22:07:12', 1, '2026-01-06 22:07:12');
INSERT INTO `product_category` VALUES (2, '镜头', NULL, 'LEN', 0, 1, NULL, 1, '2025-12-20 16:59:02', 1, '2025-12-20 16:59:10');
INSERT INTO `product_category` VALUES (3, '无人机', NULL, 'DRONE', 0, 1, NULL, 1, '2026-04-10 18:25:30', NULL, '2026-04-10 18:25:32');
INSERT INTO `product_category` VALUES (11, '微单相机', 1, 'MCAM', 1, 1, NULL, 1, '2025-12-21 13:12:38', 1, '2025-12-21 13:12:43');
INSERT INTO `product_category` VALUES (12, '单反相机', 1, 'SLR', 1, 1, '', 1, '2026-01-06 22:07:17', 1, '2026-01-06 22:07:17');
INSERT INTO `product_category` VALUES (13, '运动相机', 1, 'ACTION_CAM', 1, 1, NULL, 1, '2026-04-10 18:25:59', NULL, '2026-04-10 18:25:59');
INSERT INTO `product_category` VALUES (21, '变焦镜头', 2, 'ZLEN', 1, 1, NULL, 1, '2025-12-21 15:18:11', 1, '2025-12-21 15:18:11');
INSERT INTO `product_category` VALUES (22, '定焦镜头', 2, 'PLEN', 1, 1, NULL, 1, '2025-12-21 15:18:50', 1, '2025-12-21 15:18:55');
INSERT INTO `product_category` VALUES (27, '50mm', 22, '50mm', 2, 1, '', 1, '2026-01-06 22:43:05', NULL, '2026-01-06 22:43:05');
INSERT INTO `product_category` VALUES (31, '微型无人机', 3, 'DRONE_WEI', 1, 1, NULL, 1, '2026-04-10 18:26:45', NULL, '2026-04-10 18:26:45');
INSERT INTO `product_category` VALUES (32, '轻型无人机', 3, 'DRONE_QING', 1, 1, NULL, 1, '2026-04-10 18:29:10', NULL, '2026-04-10 18:29:10');
INSERT INTO `product_category` VALUES (33, '中型无人机', 3, 'DRONE_ZHONG', 1, 1, NULL, 1, '2026-04-10 18:28:01', NULL, '2026-04-10 18:28:03');
INSERT INTO `product_category` VALUES (34, '大型无人机', 3, 'DRONE_DA', 1, 1, NULL, 1, '2026-04-10 18:28:31', NULL, '2026-04-10 18:28:32');
INSERT INTO `product_category` VALUES (35, '穿越机', 3, 'DRONE_CHUAN', 1, 1, NULL, 1, '2026-04-10 18:29:04', NULL, '2026-04-10 18:29:05');
INSERT INTO `product_category` VALUES (40, '三脚架', NULL, 'TRIPOD', 0, 1, '', 1, '2026-01-06 22:55:29', NULL, '2026-01-06 22:55:29');
INSERT INTO `product_category` VALUES (41, '铝合金三脚架', 40, 'ALU-TRIPOD', 1, 1, '', 1, '2026-01-06 22:57:19', NULL, '2026-01-06 22:57:19');
INSERT INTO `product_category` VALUES (42, '碳纤维三脚架', 40, 'CAR-F-TRIPOD', 1, 1, '', 1, '2026-01-06 22:58:20', NULL, '2026-01-06 22:58:20');

-- ----------------------------
-- Table structure for product_detail
-- ----------------------------
DROP TABLE IF EXISTS `product_detail`;
CREATE TABLE `product_detail`  (
  `detail_id` bigint NOT NULL AUTO_INCREMENT COMMENT '详情记录唯一标识',
  `product_id` bigint NOT NULL COMMENT '外键，关联product.product_id，删除商品时同步删除详情',
  `parameters` json NOT NULL COMMENT '专业参数（JSON 格式，如{\"画幅\":\"全画幅\",\"焦距\":\"24-70mm\",\"光圈\":\"F2.8\"}）',
  `warranty_info` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '保修信息（如 “官方保修 1 年，2025-12-31 到期”）',
  `authorization` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '品牌授权证明路径（仅全新器材需上传）',
  `img_urls` json NOT NULL COMMENT '器材实拍图路径（JSON 数组，至少 3 张，含细节图，如[\"/img/1.jpg\",\"/img/2.jpg\"]）',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '商品描述（商家自定义，如 “95 新镜头，无划痕，仅使用 3 次”）',
  `usage_duration` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '使用时长（二手商品专用，如\"1年\"）',
  `repair_history` tinyint NULL DEFAULT 0 COMMENT '维修记录：0-无维修记录，1-有维修记录（二手商品专用）',
  `accessories` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '配件清单（二手商品专用，如\"原装电池、充电器、相机包\"）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '详情创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '详情更新时间',
  PRIMARY KEY (`detail_id`) USING BTREE,
  UNIQUE INDEX `product_id`(`product_id`) USING BTREE,
  CONSTRAINT `product_detail_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储摄影器材的专业参数、保修信息、图片等详细内容，与product一对一关联，避免基础表字段冗余。\r\n' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of product_detail
-- ----------------------------
INSERT INTO `product_detail` VALUES (1, 1, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/Z62_1.png\", \"/images/Z62_2.png\", \"/images/Z62_3.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:59:42', '2026-04-11 02:11:08');
INSERT INTO `product_detail` VALUES (2, 15, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:42', '2026-04-11 01:35:01');
INSERT INTO `product_detail` VALUES (3, 8, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/a005143dadc14798af03a344229cca26.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:44', '2026-04-10 22:56:44');
INSERT INTO `product_detail` VALUES (4, 4, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/D850_1.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:45', '2026-04-11 02:11:14');
INSERT INTO `product_detail` VALUES (5, 6, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:47', '2026-04-10 22:56:47');
INSERT INTO `product_detail` VALUES (7, 20, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/661e6ec68d3f4fb09728b434e0ed8dcd.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:48', '2026-04-10 22:56:48');
INSERT INTO `product_detail` VALUES (8, 21, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/ac556fd1cf9b4cb1abfe283875a71b70.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:50', '2026-04-10 22:56:50');
INSERT INTO `product_detail` VALUES (9, 22, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 22:56:51', '2026-04-10 22:56:51');
INSERT INTO `product_detail` VALUES (10, 23, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/d12bf2e4e70f45928697a62bd20c80f8.png\", \"/images/06d51035f6d740edbb5769dc83eadd5e.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:52', '2026-04-10 22:56:52');
INSERT INTO `product_detail` VALUES (11, 24, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 22:56:53', '2026-04-10 22:56:53');
INSERT INTO `product_detail` VALUES (12, 25, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[\"/images/c5ea913d6c4f4b719992f595108073f5.png\", \"/images/52d572ee89a4443a849eb60955eb05ba.png\"]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', '', 0, '', '2026-04-10 22:56:56', '2026-04-10 22:56:56');
INSERT INTO `product_detail` VALUES (13, 26, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 22:57:28', '2026-04-10 22:57:28');
INSERT INTO `product_detail` VALUES (14, 27, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 22:57:30', '2026-04-10 22:57:30');
INSERT INTO `product_detail` VALUES (15, 28, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 22:57:32', '2026-04-10 22:57:32');
INSERT INTO `product_detail` VALUES (16, 29, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', NULL, NULL, '[]', '1111111111111111111111111将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 22:57:48', '2026-04-10 22:57:48');
INSERT INTO `product_detail` VALUES (17, 30, '{}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\n\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\n- MB-N11电池匣（另购）提供舒适安心的竖拍\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\n\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 23:05:35', '2026-04-10 23:05:35');
INSERT INTO `product_detail` VALUES (18, 31, '{}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\n\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\n- MB-N11电池匣（另购）提供舒适安心的竖拍\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\n\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 23:10:59', '2026-04-10 23:10:59');
INSERT INTO `product_detail` VALUES (19, 32, '{}', NULL, NULL, '[]', '将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\n\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\n- MB-N11电池匣（另购）提供舒适安心的竖拍\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\n\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\n*3 需另外收费升级后使用，同时需使用另购的外录设备。', NULL, NULL, NULL, '2026-04-10 23:36:42', '2026-04-10 23:36:42');
INSERT INTO `product_detail` VALUES (20, 33, '{}', NULL, NULL, '[\"/images/fc0ee5a8bc2c456aa7b4e8d9d68ab0ea.png\"]', '111111111111111111测试', '', 0, '', '2026-04-11 01:30:42', '2026-04-11 01:55:55');
INSERT INTO `product_detail` VALUES (21, 34, '{}', NULL, NULL, '[]', '测试1111111111111111', NULL, NULL, NULL, '2026-04-11 01:32:45', '2026-04-11 01:32:45');
INSERT INTO `product_detail` VALUES (22, 35, '{}', NULL, NULL, '[]', 'M44444444444', NULL, NULL, NULL, '2026-04-11 01:34:25', '2026-04-11 01:34:25');
INSERT INTO `product_detail` VALUES (23, 36, '{}', NULL, NULL, '[]', '111111111111111111111111111', NULL, NULL, NULL, '2026-04-11 01:37:36', '2026-04-11 01:37:36');
INSERT INTO `product_detail` VALUES (24, 37, '{}', NULL, NULL, '[]', '4kkkkkkkkkkkkkkkk', NULL, NULL, NULL, '2026-04-11 01:40:28', '2026-04-11 01:40:28');
INSERT INTO `product_detail` VALUES (25, 38, '{}', NULL, NULL, '[]', 'R66666666666666662', NULL, NULL, NULL, '2026-04-11 01:41:35', '2026-04-11 01:41:35');
INSERT INTO `product_detail` VALUES (26, 39, '{}', NULL, NULL, '[]', 'aaaaaaaaaaaaaaaaaaa', NULL, NULL, NULL, '2026-04-11 01:42:47', '2026-04-11 01:42:47');
INSERT INTO `product_detail` VALUES (27, 40, '{}', NULL, NULL, '[]', '6333333333333333333Z', NULL, NULL, NULL, '2026-04-11 01:44:46', '2026-04-11 01:44:46');
INSERT INTO `product_detail` VALUES (28, 41, '{}', NULL, NULL, '[]', 'sssssssssssssss', NULL, NULL, NULL, '2026-04-11 01:47:18', '2026-04-11 01:47:18');
INSERT INTO `product_detail` VALUES (29, 42, '{}', NULL, NULL, '[]', '5555555555555', NULL, NULL, NULL, '2026-04-11 02:09:56', '2026-04-11 02:09:56');
INSERT INTO `product_detail` VALUES (30, 43, '{}', NULL, NULL, '[]', '5555555555555', NULL, NULL, NULL, '2026-04-11 02:10:05', '2026-04-11 02:10:05');
INSERT INTO `product_detail` VALUES (31, 44, '{}', NULL, NULL, '[]', '5555555555555', NULL, NULL, NULL, '2026-04-11 02:10:45', '2026-04-11 02:10:45');

-- ----------------------------
-- Table structure for product_image
-- ----------------------------
DROP TABLE IF EXISTS `product_image`;
CREATE TABLE `product_image`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `product_id` bigint NOT NULL COMMENT '商品ID（关联product表）',
  `image_id` bigint NOT NULL COMMENT '图片ID（关联sys_image表）',
  `image_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '图片类型（main：主图；detail：详情图；gallery：图库图）',
  `sort` int NULL DEFAULT 0 COMMENT '排序号（用于图片展示顺序）',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `is_deleted` tinyint(3) UNSIGNED ZEROFILL NULL DEFAULT 000 COMMENT '逻辑删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_product_id`(`product_id`) USING BTREE,
  INDEX `idx_image_id`(`image_id`) USING BTREE,
  CONSTRAINT `product_image_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `product_image_ibfk_2` FOREIGN KEY (`image_id`) REFERENCES `sys_image` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 47 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '商品图片关联表，实现商品与图片的一对多关联' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of product_image
-- ----------------------------
INSERT INTO `product_image` VALUES (1, 1, 1, 'main', 0, '2025-12-18 22:58:55', 001);
INSERT INTO `product_image` VALUES (2, 2, 2, 'main', 0, '2025-12-20 17:05:12', 000);
INSERT INTO `product_image` VALUES (3, 3, 3, 'main', 0, '2025-12-20 17:16:05', 000);
INSERT INTO `product_image` VALUES (4, 4, 4, 'main', 0, '2025-12-27 17:16:56', 001);
INSERT INTO `product_image` VALUES (5, 5, 5, 'main', 0, '2025-12-27 18:58:00', 000);
INSERT INTO `product_image` VALUES (6, 6, 6, 'main', 0, '2025-12-28 18:28:20', 000);
INSERT INTO `product_image` VALUES (7, 7, 7, 'main', 0, '2025-12-28 18:28:31', 000);
INSERT INTO `product_image` VALUES (25, 20, 38, 'main', 0, '2026-02-09 22:22:59', NULL);
INSERT INTO `product_image` VALUES (26, 20, 39, 'main', 0, '2026-02-09 22:46:49', NULL);
INSERT INTO `product_image` VALUES (27, 21, 40, 'main', 0, '2026-02-09 22:56:02', NULL);
INSERT INTO `product_image` VALUES (28, 21, 41, 'main', 0, '2026-02-09 23:40:26', NULL);
INSERT INTO `product_image` VALUES (29, 22, 42, 'main', 0, '2026-02-10 00:42:05', 000);
INSERT INTO `product_image` VALUES (30, 23, 43, 'main', 0, '2026-02-10 00:43:31', 001);
INSERT INTO `product_image` VALUES (31, 23, 43, 'main', 0, '2026-02-10 00:43:44', NULL);
INSERT INTO `product_image` VALUES (32, 23, 44, 'main', 1, '2026-02-10 00:43:44', NULL);
INSERT INTO `product_image` VALUES (33, 24, 45, 'main', 0, '2026-02-10 00:52:09', 000);
INSERT INTO `product_image` VALUES (34, 24, 46, 'main', 1, '2026-02-10 00:52:09', 000);
INSERT INTO `product_image` VALUES (35, 24, 47, 'main', 2, '2026-02-10 00:52:09', 000);
INSERT INTO `product_image` VALUES (36, 24, 48, 'main', 3, '2026-02-10 00:52:09', 000);
INSERT INTO `product_image` VALUES (37, 25, 49, 'main', 0, '2026-03-08 01:35:03', 001);
INSERT INTO `product_image` VALUES (38, 25, 50, 'main', 1, '2026-03-08 01:35:03', 001);
INSERT INTO `product_image` VALUES (39, 8, 51, 'main', 0, '2026-03-08 01:52:54', NULL);
INSERT INTO `product_image` VALUES (40, 8, 52, 'main', 0, '2026-03-08 01:53:05', NULL);
INSERT INTO `product_image` VALUES (41, 8, 53, 'main', 0, '2026-03-08 01:53:39', NULL);
INSERT INTO `product_image` VALUES (42, 8, 54, 'main', 1, '2026-03-08 01:53:39', NULL);
INSERT INTO `product_image` VALUES (43, 8, 55, 'main', 0, '2026-03-08 01:53:50', NULL);
INSERT INTO `product_image` VALUES (44, 25, 49, 'main', 0, '2026-03-08 02:00:34', NULL);
INSERT INTO `product_image` VALUES (45, 25, 50, 'main', 1, '2026-03-08 02:00:34', NULL);
INSERT INTO `product_image` VALUES (46, 1, 1, 'main', 0, '2026-03-17 20:24:43', NULL);
INSERT INTO `product_image` VALUES (47, 26, 56, 'main', 0, '2026-04-10 22:31:28', 000);
INSERT INTO `product_image` VALUES (48, 26, 57, 'main', 1, '2026-04-10 22:31:28', 000);
INSERT INTO `product_image` VALUES (49, 27, 58, 'main', 0, '2026-04-10 22:40:07', 000);
INSERT INTO `product_image` VALUES (50, 27, 59, 'main', 1, '2026-04-10 22:40:07', 000);
INSERT INTO `product_image` VALUES (51, 28, 60, 'main', 0, '2026-04-10 22:46:25', 000);
INSERT INTO `product_image` VALUES (52, 28, 61, 'main', 1, '2026-04-10 22:46:25', 000);
INSERT INTO `product_image` VALUES (53, 29, 62, 'main', 0, '2026-04-10 22:49:11', 000);
INSERT INTO `product_image` VALUES (54, 29, 63, 'main', 1, '2026-04-10 22:49:11', 000);
INSERT INTO `product_image` VALUES (55, 30, 64, 'main', 0, '2026-04-10 23:05:35', 000);
INSERT INTO `product_image` VALUES (56, 31, 65, 'main', 0, '2026-04-10 23:10:59', 000);
INSERT INTO `product_image` VALUES (57, 32, 66, 'main', 0, '2026-04-10 23:36:42', 000);
INSERT INTO `product_image` VALUES (58, 33, 67, 'main', 0, '2026-04-11 01:30:42', 001);
INSERT INTO `product_image` VALUES (59, 34, 68, 'main', 0, '2026-04-11 01:32:45', 000);
INSERT INTO `product_image` VALUES (60, 34, 69, 'main', 1, '2026-04-11 01:32:45', 000);
INSERT INTO `product_image` VALUES (61, 35, 70, 'main', 0, '2026-04-11 01:34:25', 000);
INSERT INTO `product_image` VALUES (62, 36, 71, 'main', 0, '2026-04-11 01:37:36', 000);
INSERT INTO `product_image` VALUES (63, 37, 72, 'main', 0, '2026-04-11 01:40:28', 000);
INSERT INTO `product_image` VALUES (64, 38, 73, 'main', 0, '2026-04-11 01:41:35', 000);
INSERT INTO `product_image` VALUES (65, 39, 74, 'main', 0, '2026-04-11 01:42:47', 000);
INSERT INTO `product_image` VALUES (66, 40, 75, 'main', 0, '2026-04-11 01:44:46', 000);
INSERT INTO `product_image` VALUES (67, 41, 76, 'main', 0, '2026-04-11 01:47:18', 000);
INSERT INTO `product_image` VALUES (68, 33, 67, 'main', 0, '2026-04-11 01:47:44', NULL);
INSERT INTO `product_image` VALUES (69, 42, 77, 'main', 0, '2026-04-11 02:09:56', 000);
INSERT INTO `product_image` VALUES (70, 43, 77, 'main', 0, '2026-04-11 02:10:05', 000);
INSERT INTO `product_image` VALUES (71, 44, 77, 'main', 0, '2026-04-11 02:10:45', 000);
INSERT INTO `product_image` VALUES (72, 44, 78, 'main', 1, '2026-04-11 02:10:45', 000);
INSERT INTO `product_image` VALUES (73, 4, 4, 'main', 0, '2026-04-11 02:11:14', NULL);

-- ----------------------------
-- Table structure for product_rental_detail
-- ----------------------------
DROP TABLE IF EXISTS `product_rental_detail`;
CREATE TABLE `product_rental_detail`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `product_id` bigint NOT NULL COMMENT '外键，关联product.product_id',
  `deposit` decimal(12, 2) NOT NULL COMMENT '租赁押金（元）',
  `max_rental_days` int NOT NULL COMMENT '最长租赁期限（天）',
  `min_rental_days` int NOT NULL COMMENT '最短租赁期限（天）',
  `insurance_fee` decimal(12, 2) NOT NULL COMMENT '保险费用（元/天）',
  `late_fee_rate` decimal(5, 2) NOT NULL COMMENT '逾期违约金率（每天按租金的百分比计算）',
  `damage_fee_rule` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '损坏赔偿规则',
  `pickup_methods` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '取货方式：delivery-配送上门, store_pickup-门店自取',
  `delivery_fee` decimal(12, 2) NOT NULL COMMENT '配送费用（元）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `product_id`(`product_id`) USING BTREE,
  CONSTRAINT `product_rental_detail_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '租赁商品详情表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of product_rental_detail
-- ----------------------------
INSERT INTO `product_rental_detail` VALUES (1, 6, 1399.90, 90, 1, 10.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, '2025-12-29 23:21:28', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (2, 7, 1499.90, 90, 3, 8.00, 0.05, '根据损坏程度，按商品原价的10%-100%赔偿', 'delivery', 50.00, '2025-12-29 23:21:39', '2025-12-29 23:21:39');
INSERT INTO `product_rental_detail` VALUES (3, 33, 2999.90, 90, 6, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (4, 34, 1599.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (5, 35, 1899.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (6, 36, 1599.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (7, 37, 899.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (8, 38, 2999.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (9, 39, 300.00, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (10, 40, 1899.90, 90, 7, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (11, 41, 499.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:06:36', '2026-04-11 02:06:36');
INSERT INTO `product_rental_detail` VALUES (18, 42, 219.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:09:55', '2026-04-11 02:09:55');
INSERT INTO `product_rental_detail` VALUES (19, 43, 219.90, 90, 3, 0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00, '2026-04-11 02:10:04', '2026-04-11 02:10:04');

-- ----------------------------
-- Table structure for refund
-- ----------------------------
DROP TABLE IF EXISTS `refund`;
CREATE TABLE `refund`  (
  `refund_id` bigint NOT NULL AUTO_INCREMENT,
  `order_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `refund_amount` decimal(10, 2) NOT NULL,
  `refund_status` int NOT NULL COMMENT '0: 申请中, 1: 退款成功, 2: 退款失败',
  `refund_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `refund_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL,
  `refund_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `apply_time` datetime NULL DEFAULT NULL,
  `refund_time` datetime NULL DEFAULT NULL,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`refund_id`) USING BTREE,
  INDEX `idx_order_id`(`order_id`) USING BTREE,
  INDEX `idx_user_id`(`user_id`) USING BTREE,
  INDEX `idx_refund_status`(`refund_status`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '退款表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of refund
-- ----------------------------
INSERT INTO `refund` VALUES (2, 67, 7, 9200.00, 2, '其他原因', '11111111111111', 'wechat', '2026-04-07 17:10:06', '2026-04-07 17:46:08', '2026-04-07 17:10:06', '2026-04-07 17:46:08');
INSERT INTO `refund` VALUES (4, 69, 7, 16495.00, 1, '物流问题', '阿大撒', 'wechat', '2026-04-07 17:54:57', '2026-04-07 17:55:18', '2026-04-07 17:54:57', '2026-04-07 17:55:18');
INSERT INTO `refund` VALUES (5, 70, 7, 14999.00, 0, '商品质量问题', '', 'wechat', '2026-04-07 17:56:48', NULL, '2026-04-07 17:56:48', '2026-04-07 17:56:48');
INSERT INTO `refund` VALUES (6, 71, 7, 1444900.00, 0, '商品与描述不符', '', 'alipay', '2026-04-07 17:57:33', NULL, '2026-04-07 17:57:33', '2026-04-07 17:57:33');
INSERT INTO `refund` VALUES (7, 72, 7, 1830800.00, 2, '拍错商品', '', 'alipay', '2026-04-07 17:58:10', '2026-04-07 17:58:16', '2026-04-07 17:58:10', '2026-04-07 17:58:16');
INSERT INTO `refund` VALUES (8, 77, 7, 4402.15, 0, '拍错商品', '', 'wechat', '2026-04-11 00:50:20', NULL, '2026-04-11 00:50:20', '2026-04-11 00:50:20');

-- ----------------------------
-- Table structure for rental
-- ----------------------------
DROP TABLE IF EXISTS `rental`;
CREATE TABLE `rental`  (
  `rental_id` bigint NOT NULL AUTO_INCREMENT COMMENT '租赁记录唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联order.order_id，订单删除时同步删除租赁记录',
  `start_date` datetime NOT NULL COMMENT '起租时间（用户选择或商家确认）',
  `end_date` datetime NOT NULL COMMENT '到期时间（start_date + lease_term天，用于到期提醒）',
  `lease_term` int NOT NULL COMMENT '租期（单位：天，1-90 天）',
  `rent` decimal(12, 2) NOT NULL DEFAULT 0.00 COMMENT '总租金（unit_price × lease_term，会员享折扣）',
  `pickup_type` tinyint NOT NULL COMMENT '取货方式：1 - 上门取件，2 - 快递配送',
  `return_type` tinyint NOT NULL COMMENT '归还方式：1 - 上门还件，2 - 自行寄送',
  `return_status` tinyint NOT NULL DEFAULT 0 COMMENT '归还状态：0 - 未归还，1 - 待验收，2 - 验收通过（押金退还），3 - 验收异常（扣押金）',
  `renew_status` tinyint NOT NULL DEFAULT 0 COMMENT '续租状态：0 - 无续租，1 - 续租申请中，2 - 续租通过，3 - 续租驳回',
  `overdue_days` int NOT NULL DEFAULT 0 COMMENT '逾期天数（end_date后未归还的天数，按日租金 1.5 倍收滞纳金）',
  `initial_img` json NOT NULL COMMENT '出租时器材初始状态图（JSON 数组，用于归还验收对比）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '租赁记录创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '租赁状态更新时间',
  PRIMARY KEY (`rental_id`) USING BTREE,
  UNIQUE INDEX `order_id`(`order_id`) USING BTREE,
  INDEX `start_date`(`start_date`, `end_date`, `return_status`, `renew_status`) USING BTREE,
  CONSTRAINT `rental_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储租赁订单的专属信息（租期、归还状态等），与order一对一关联（仅order_type=2时存在）。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of rental
-- ----------------------------
INSERT INTO `rental` VALUES (2, 58, '2026-02-09 20:13:50', '2026-02-16 20:13:50', 7, 840.63, 2, 2, 0, 0, 0, '[]', '2026-02-09 20:13:50', '2026-02-09 20:13:54');
INSERT INTO `rental` VALUES (3, 62, '2026-03-17 21:11:37', '2026-03-24 21:11:37', 7, 4203.15, 2, 2, 0, 0, 0, '[]', '2026-03-17 21:11:37', '2026-03-17 21:11:50');
INSERT INTO `rental` VALUES (4, 63, '2026-03-17 21:17:50', '2026-03-20 21:17:50', 3, 300.00, 2, 2, 0, 0, 0, '[]', '2026-03-17 21:17:50', '2026-03-17 21:17:53');
INSERT INTO `rental` VALUES (5, 64, '2026-03-17 21:18:20', '2026-03-20 21:18:20', 3, 300.00, 2, 2, 0, 0, 0, '[]', '2026-03-17 21:18:20', '2026-03-17 21:18:23');
INSERT INTO `rental` VALUES (6, 74, '2026-04-11 00:21:04', '2026-05-03 00:21:04', 22, 2200.00, 2, 2, 0, 0, 0, '[]', '2026-04-11 00:21:04', '2026-04-11 00:21:10');
INSERT INTO `rental` VALUES (7, 77, '2026-04-11 00:50:07', '2026-05-06 00:50:07', 25, 3002.25, 2, 2, 0, 0, 0, '[]', '2026-04-11 00:50:07', '2026-04-11 00:50:11');
INSERT INTO `rental` VALUES (8, 78, '2026-04-11 00:50:30', '2026-05-08 00:50:30', 27, 3242.43, 2, 2, 2, 0, 0, '[]', '2026-04-11 00:50:30', '2026-04-11 00:51:30');
INSERT INTO `rental` VALUES (9, 79, '2026-04-11 00:55:21', '2026-05-14 00:55:21', 33, 3962.97, 2, 2, 1, 0, 0, '[]', '2026-04-11 00:55:21', '2026-04-11 00:56:10');
INSERT INTO `rental` VALUES (10, 80, '2026-04-11 01:01:15', '2026-04-21 01:01:15', 10, 1000.00, 2, 2, 2, 0, 0, '[]', '2026-04-11 01:01:15', '2026-04-11 01:02:25');
INSERT INTO `rental` VALUES (11, 81, '2026-04-11 01:03:01', '2026-05-14 01:03:01', 33, 3962.97, 2, 2, 0, 0, 0, '[]', '2026-04-11 01:03:01', '2026-04-11 01:03:07');

-- ----------------------------
-- Table structure for rental_equipment_status
-- ----------------------------
DROP TABLE IF EXISTS `rental_equipment_status`;
CREATE TABLE `rental_equipment_status`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `product_id` bigint NOT NULL COMMENT '外键，关联product.product_id',
  `equipment_sn` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '器材序列号',
  `status` tinyint NOT NULL COMMENT '器材状态：0-可租, 1-已租出, 2-维修中, 3-已报废',
  `current_rental_order_id` bigint NULL DEFAULT NULL COMMENT '当前租赁订单ID（状态为1时非空）',
  `last_maintenance_date` date NOT NULL COMMENT '上次维护日期',
  `next_maintenance_date` date NOT NULL COMMENT '下次维护日期',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `equipment_sn`(`equipment_sn`) USING BTREE,
  INDEX `product_id`(`product_id`) USING BTREE,
  INDEX `status`(`status`) USING BTREE,
  CONSTRAINT `rental_equipment_status_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '租赁器材状态表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of rental_equipment_status
-- ----------------------------

-- ----------------------------
-- Table structure for rental_rule
-- ----------------------------
DROP TABLE IF EXISTS `rental_rule`;
CREATE TABLE `rental_rule`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `rule_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '规则名称',
  `rule_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '规则内容',
  `rule_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '规则类型：general-通用规则, damage-损坏赔偿, late-逾期规则',
  `is_active` tinyint NOT NULL DEFAULT 1 COMMENT '是否启用：0-禁用, 1-启用',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `rule_type`(`rule_type`) USING BTREE,
  INDEX `is_active`(`is_active`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '租赁规则表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of rental_rule
-- ----------------------------

-- ----------------------------
-- Table structure for role
-- ----------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role`  (
  `role_id` int NOT NULL AUTO_INCREMENT COMMENT '角色唯一标识',
  `role_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色名称（如 “超级管理员”“普通管理员”“运营管理员”）',
  `user_type` tinyint NOT NULL COMMENT '角色id,1 - 个人用户，2 - 企业用户（器材商家），3 - 管理员，4 -超级管理员',
  `role_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色编码（如 “ADMIN_SUPER”“ADMIN_NORMAL”“ADMIN_OP”）',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '角色描述（如 “超级管理员拥有全系统权限，可修改所有配置”）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '角色创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '角色信息更新时间',
  PRIMARY KEY (`role_id`) USING BTREE,
  UNIQUE INDEX `role_name`(`role_name`, `role_code`) USING BTREE,
  INDEX `user_type`(`user_type`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储系统角色（超级管理员 / 普通管理员 / 运营管理员），支撑基于角色的权限控制（RBAC）。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of role
-- ----------------------------
INSERT INTO `role` VALUES (1, '个人用户', 1, 'USER', NULL, '2026-01-04 22:23:10', '2026-01-04 22:23:10');
INSERT INTO `role` VALUES (2, '企业用户', 2, 'MERCHANT', NULL, '2026-01-04 22:23:10', '2026-01-04 22:23:10');
INSERT INTO `role` VALUES (3, '管理员', 3, 'ADMIN', NULL, '2026-01-04 22:23:10', '2026-01-04 22:23:10');
INSERT INTO `role` VALUES (4, '超级管理员', 4, 'SUPER_ADMIN', NULL, '2026-01-04 22:23:10', '2026-01-04 22:23:10');

-- ----------------------------
-- Table structure for role_permission
-- ----------------------------
DROP TABLE IF EXISTS `role_permission`;
CREATE TABLE `role_permission`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '关联记录唯一标识',
  `role_id` int NOT NULL COMMENT '关联role.role_id，角色删除时同步删除关联记录',
  `permission_id` int NOT NULL COMMENT '关联permission.permission_id，权限删除时同步删除关联记录',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '关联记录创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `role_id`(`role_id`, `permission_id`) USING BTREE,
  INDEX `permission_id`(`permission_id`) USING BTREE,
  CONSTRAINT `role_permission_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `role_permission_ibfk_2` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`permission_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 348 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：RBAC 模型的中间表，实现角色与权限的多对多关联（如 “普通管理员” 关联 “商品审核”“订单查看” 权限）。\r\n备注：普通管理员不可关联 “超级管理员” 专属权限（如permission_code=“SYSTEM_CONFIG”），权限变更需超级管理员审批。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of role_permission
-- ----------------------------
INSERT INTO `role_permission` VALUES (74, 4, 42, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (75, 4, 89, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (76, 4, 90, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (77, 4, 91, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (78, 4, 92, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (79, 4, 93, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (80, 4, 94, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (81, 4, 95, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (82, 4, 96, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (83, 4, 97, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (84, 4, 98, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (85, 4, 99, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (86, 4, 100, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (87, 4, 101, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (88, 4, 102, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (89, 4, 103, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (90, 4, 104, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (91, 4, 105, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (92, 4, 106, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (93, 4, 107, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (94, 4, 108, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (95, 4, 109, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (96, 4, 110, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (97, 4, 111, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (98, 4, 112, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (99, 4, 113, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (100, 4, 114, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (101, 4, 115, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (102, 4, 116, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (103, 4, 117, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (104, 4, 118, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (105, 4, 119, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (106, 4, 120, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (107, 4, 121, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (108, 4, 122, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (109, 4, 123, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (110, 4, 124, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (111, 4, 125, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (112, 4, 126, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (113, 4, 127, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (114, 4, 128, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (115, 4, 129, '2026-03-08 01:07:05');
INSERT INTO `role_permission` VALUES (268, 3, 89, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (269, 3, 90, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (270, 3, 91, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (271, 3, 92, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (272, 3, 93, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (273, 3, 94, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (274, 3, 95, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (275, 3, 96, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (276, 3, 97, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (277, 3, 98, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (278, 3, 99, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (279, 3, 100, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (280, 3, 101, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (281, 3, 102, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (282, 3, 103, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (283, 3, 104, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (284, 3, 105, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (285, 3, 106, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (286, 3, 107, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (287, 3, 108, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (288, 3, 109, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (289, 3, 110, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (290, 3, 111, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (291, 3, 112, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (292, 3, 113, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (293, 3, 114, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (294, 3, 115, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (295, 3, 116, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (296, 3, 117, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (297, 3, 118, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (298, 3, 119, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (299, 3, 120, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (300, 3, 121, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (301, 3, 122, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (302, 3, 123, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (303, 3, 124, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (304, 3, 125, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (305, 3, 126, '2026-03-08 02:02:26');
INSERT INTO `role_permission` VALUES (306, 3, 128, '2026-03-08 02:02:26');

-- ----------------------------
-- Table structure for second_hand
-- ----------------------------
DROP TABLE IF EXISTS `second_hand`;
CREATE TABLE `second_hand`  (
  `sh_id` bigint NOT NULL AUTO_INCREMENT COMMENT '二手记录唯一标识',
  `product_id` bigint NOT NULL COMMENT '关联product.product_id，商品删除时同步删除二手记录',
  `quality_report` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '第三方质检报告路径（如 “/report/sh123.pdf”）',
  `used_time` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '使用时长（如 “3 个月”“1 年”）',
  `defect_desc` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '瑕疵描述（如 “镜头边缘轻微划痕，不影响成像”）',
  `defect_img` json NULL COMMENT '瑕疵图片路径（JSON 数组，无瑕疵则为空）',
  `seller_type` tinyint NOT NULL COMMENT '卖家类型：1 - 个人闲置，2 - 企业商家（优先展示个人闲置）',
  `negotiate_status` tinyint NOT NULL DEFAULT 0 COMMENT '议价状态：0 - 未议价，1 - 议价中，2 - 议价达成，3 - 议价失败',
  `final_price` decimal(12, 2) NULL DEFAULT NULL COMMENT '议价最终价格（无议价则与product.price一致）',
  `parameters` json NULL COMMENT '专业参数（JSON格式）',
  `warranty_info` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '保修信息',
  `img_urls` json NULL COMMENT '器材实拍图路径（JSON数组）',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '商品描述',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '二手记录创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '二手信息更新时间',
  `repair_history` tinyint NOT NULL DEFAULT 0 COMMENT '维修记录：0-无维修记录，1-有维修记录',
  `accessories` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '配件清单（如电池、充电器、说明书等）',
  PRIMARY KEY (`sh_id`) USING BTREE,
  UNIQUE INDEX `product_id`(`product_id`) USING BTREE,
  INDEX `used_time`(`used_time`, `seller_type`, `negotiate_status`) USING BTREE,
  CONSTRAINT `second_hand_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储二手器材的专属信息（质检报告、使用记录等），与product一对一关联（仅product_type=2时存在）。\r\n备注：禁止发布 “翻新机”“拼装机”，违规则product.audit_status=2且永久封禁seller_id对应的账号。\r\n' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of second_hand
-- ----------------------------
INSERT INTO `second_hand` VALUES (1, 4, NULL, '5年', NULL, NULL, 2, 0, NULL, '{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康F卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}', '', '[\"/images/D850_2.png\", \"/images/D850_1.png\", \"/images/D850_3.png\"]', '单反时代的末代机皇', '2025-12-27 19:23:09', '2025-12-27 19:23:09', 0, NULL);

-- ----------------------------
-- Table structure for sku
-- ----------------------------
DROP TABLE IF EXISTS `sku`;
CREATE TABLE `sku`  (
  `sku_id` bigint NOT NULL AUTO_INCREMENT COMMENT 'SKU ID',
  `product_id` bigint NOT NULL COMMENT '商品ID',
  `sku_attribute` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'SKU属性',
  `sku_value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'SKU值',
  `price` decimal(12, 2) NOT NULL COMMENT 'SKU价格',
  `stock` int NOT NULL COMMENT 'SKU库存',
  `min_stock` int NOT NULL DEFAULT 10 COMMENT 'SKU安全库存',
  `sales` int NOT NULL DEFAULT 0 COMMENT 'SKU销量',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`sku_id`) USING BTREE,
  INDEX `idx_product_id`(`product_id`) USING BTREE,
  INDEX `idx_sku_attribute`(`sku_attribute`) USING BTREE,
  INDEX `idx_sku_value`(`sku_value`) USING BTREE,
  CONSTRAINT `fk_sku_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = 'SKU表，存储商品的库存单位信息' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sku
-- ----------------------------
INSERT INTO `sku` VALUES (1, 1, '颜色', '黑色', 0.00, 77, 10, 120, '2026-02-09 19:38:53', '2026-02-09 19:38:53');
INSERT INTO `sku` VALUES (2, 2, '版本', '国行', 0.00, 9, 10, 95, '2026-02-09 19:38:53', '2026-02-09 19:38:53');
INSERT INTO `sku` VALUES (3, 3, '套餐', '单机', 0.00, 99, 10, 88, '2026-02-09 19:38:53', '2026-02-09 19:38:53');
INSERT INTO `sku` VALUES (4, 4, '成色', '85新', 5555.00, 4, 5, 45, '2026-02-09 19:38:53', '2026-02-09 19:56:17');
INSERT INTO `sku` VALUES (5, 5, '成色', '90新', 0.00, 9, 10, 67, '2026-02-09 19:38:53', '2026-02-09 19:38:53');
INSERT INTO `sku` VALUES (6, 6, '状态', '可租', 0.00, 4, 5, 32, '2026-02-09 19:38:53', '2026-02-09 19:38:53');
INSERT INTO `sku` VALUES (7, 7, '状态', '可租', 0.00, 11, 20, 56, '2026-02-09 19:38:53', '2026-02-09 19:38:53');
INSERT INTO `sku` VALUES (8, 4, '成色', '8新', 5000.00, 7, 10, 0, '2026-02-09 19:55:29', '2026-02-09 19:55:29');
INSERT INTO `sku` VALUES (9, 23, '黑色', 'BLACK', 13999.00, 200, 10, 0, '2026-04-08 21:19:25', '2026-04-08 21:19:25');
INSERT INTO `sku` VALUES (10, 23, '白', 'W', 13999.00, 199, 10, 0, '2026-04-08 21:20:06', '2026-04-08 21:20:06');
INSERT INTO `sku` VALUES (11, 8, '默认', '默认', 18999.00, 88, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (12, 15, '默认', '默认', 15999.00, 88, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (13, 20, '默认', '默认', 18888.00, 8555, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (14, 21, '默认', '默认', 14999.00, 220, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (15, 22, '默认', '默认', 9999.00, 72, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (16, 24, '默认', '默认', 14449.00, -137, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (17, 25, '默认', '默认', 3299.00, 90, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (18, 26, '默认', '默认', 9999.00, 88, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (19, 27, '默认', '默认', 1499.00, 200, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (20, 28, '默认', '默认', 22999.00, 99, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (21, 29, '默认', '默认', 18999.00, 99, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (22, 30, '默认', '默认', 999.00, 0, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (23, 31, '默认', '默认', 2899.00, 22, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (24, 32, '默认', '默认', 18999.00, 82, 10, 0, '2026-04-11 01:25:09', '2026-04-11 01:25:09');
INSERT INTO `sku` VALUES (26, 33, '默认', '默认', 109.00, 2, 10, 0, '2026-04-11 01:30:41', '2026-04-11 01:30:41');
INSERT INTO `sku` VALUES (27, 34, '默认', '默认', 56.00, 66, 10, 0, '2026-04-11 01:32:44', '2026-04-11 01:32:44');
INSERT INTO `sku` VALUES (28, 35, '默认', '默认', 80.00, 3, 10, 0, '2026-04-11 01:34:24', '2026-04-11 01:34:24');
INSERT INTO `sku` VALUES (29, 36, '默认', '默认', 90.00, 50, 10, 0, '2026-04-11 01:37:35', '2026-04-11 01:37:35');
INSERT INTO `sku` VALUES (30, 37, '默认', '默认', 32.00, 88, 10, 0, '2026-04-11 01:40:28', '2026-04-11 01:40:28');
INSERT INTO `sku` VALUES (31, 38, '默认', '默认', 150.00, 88, 10, 0, '2026-04-11 01:41:35', '2026-04-11 01:41:35');
INSERT INTO `sku` VALUES (32, 39, '默认', '默认', 20.00, 5555, 10, 0, '2026-04-11 01:42:46', '2026-04-11 01:42:46');
INSERT INTO `sku` VALUES (33, 40, '默认', '默认', 70.00, 63, 10, 0, '2026-04-11 01:44:45', '2026-04-11 01:44:45');
INSERT INTO `sku` VALUES (34, 41, '默认', '默认', 40.00, 11, 10, 0, '2026-04-11 01:47:17', '2026-04-11 01:47:17');

-- ----------------------------
-- Table structure for statistics
-- ----------------------------
DROP TABLE IF EXISTS `statistics`;
CREATE TABLE `statistics`  (
  `stat_id` bigint NOT NULL AUTO_INCREMENT COMMENT '统计记录唯一标识',
  `stat_type` tinyint NOT NULL COMMENT '统计类型：1 - 日统计，2 - 周统计，3 - 月统计',
  `stat_date` date NOT NULL COMMENT '统计日期（日统计：具体日期；周统计：周一日期；月统计：1 号日期）',
  `user_count` int NOT NULL DEFAULT 0 COMMENT '当日 / 周 / 月新增用户数',
  `order_count` int NOT NULL DEFAULT 0 COMMENT '当日 / 周 / 月新增订单总数（含购买 / 租赁 / 二手）',
  `purchase_count` int NOT NULL DEFAULT 0 COMMENT '当日 / 周 / 月购买订单数',
  `rental_count` int NOT NULL DEFAULT 0 COMMENT '当日 / 周 / 月租赁订单数',
  `second_hand_count` int NOT NULL DEFAULT 0 COMMENT '当日 / 周 / 月二手订单数',
  `sales_amount` decimal(15, 2) NOT NULL DEFAULT 0.00 COMMENT '当日 / 周 / 月总销售额（购买 + 二手）',
  `rental_amount` decimal(15, 2) NOT NULL DEFAULT 0.00 COMMENT '当日 / 周 / 月总租金收入',
  `deposit_total` decimal(15, 2) NOT NULL DEFAULT 0.00 COMMENT '当日 / 周 / 月在押押金总额',
  `is_abnormal` tinyint NOT NULL DEFAULT 0 COMMENT '数据是否异常：0 - 正常，1 - 异常（如单日销售额突增 10 倍，自动标记）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '统计记录生成时间（日统计：次日凌晨；周统计：次周一凌晨；月统计：次月 1 号凌晨）',
  PRIMARY KEY (`stat_id`) USING BTREE,
  INDEX `stat_type`(`stat_type`, `stat_date`, `is_abnormal`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储系统运营数据（用户注册量、订单量、销售额等），支撑数据可视化分析。\r\n备注：数据统计延迟≤1 小时（实时数据），历史数据每日凌晨自动更新；支持自定义时间区间查询（最大跨度 1 年）。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of statistics
-- ----------------------------

-- ----------------------------
-- Table structure for sys_image
-- ----------------------------
DROP TABLE IF EXISTS `sys_image`;
CREATE TABLE `sys_image`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `image_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片自定义名称',
  `original_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '图片原始文件名（如test.jpg）',
  `storage_path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '存储路径/OSS访问地址（核心）',
  `file_size` bigint NOT NULL COMMENT '文件大小（字节）',
  `file_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '文件类型（如jpg/png/webp）',
  `width` int NULL DEFAULT NULL COMMENT '图片宽度（px）',
  `height` int NULL DEFAULT NULL COMMENT '图片高度（px）',
  `upload_user_id` bigint NULL DEFAULT NULL COMMENT '上传人ID',
  `upload_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `business_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '业务类型（product：商品图；banner：轮播图）',
  `is_deleted` tinyint NULL DEFAULT 0 COMMENT '逻辑删除（0：未删；1：已删）',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `sys_image_ibfk_1`(`upload_user_id`) USING BTREE,
  CONSTRAINT `sys_image_ibfk_1` FOREIGN KEY (`upload_user_id`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 56 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '存储所有图片的基础信息' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_image
-- ----------------------------
INSERT INTO `sys_image` VALUES (1, 'Z62', 'Z62_1', '/images/Z62_1.png', 519881, 'png', NULL, NULL, NULL, '2025-12-18 22:56:57', 'product', 0);
INSERT INTO `sys_image` VALUES (2, 'Z 24-120 F4S', 'Z 24-120 F4S_1', '/images/Z 24-120 F4S.png', 441389, 'png', NULL, NULL, NULL, '2025-12-20 17:04:31', 'product', 0);
INSERT INTO `sys_image` VALUES (3, 'A7R5', 'A7R5_1', '/images/A7R5.png', 205298, 'png', NULL, NULL, NULL, '2025-12-20 17:13:38', 'product', 0);
INSERT INTO `sys_image` VALUES (4, 'D850', 'D850_1', '/images/D850_1.png', 126235, 'png', NULL, NULL, NULL, '2025-12-27 17:16:45', 'product', 0);
INSERT INTO `sys_image` VALUES (5, 'Z6', 'Z6_1', '/images/Z6_1.png', 392002, 'png', NULL, NULL, NULL, '2025-12-27 18:57:46', 'product', 0);
INSERT INTO `sys_image` VALUES (6, 'ZR', 'ZR_1', '/images/ZR_1.png', 563911, 'png', NULL, NULL, NULL, '2025-12-28 18:26:25', 'product', 0);
INSERT INTO `sys_image` VALUES (7, 'Z 70-200mm f2.8 VR S', 'Z 70-200mm f2.8 VR S_1', '/images/Z 70-200mm f2.8 VR S_1.png', 247594, 'png', NULL, NULL, NULL, '2025-12-28 18:27:27', 'product', 0);
INSERT INTO `sys_image` VALUES (38, 'z8', 'image copy 3.png', '/images/ee2d0a66e4844750abc1238cf6773e9a.png', 409989, 'png', NULL, NULL, NULL, '2026-02-09 22:22:44', 'product', 0);
INSERT INTO `sys_image` VALUES (39, NULL, 'image.png', '/images/661e6ec68d3f4fb09728b434e0ed8dcd.png', 408839, 'image/png', NULL, NULL, NULL, '2026-02-09 22:46:47', 'product', 0);
INSERT INTO `sys_image` VALUES (40, NULL, 'image.png', '/images/cda9743e83854f6ab180a7d19a97afa7.png', 251325, 'image/png', NULL, NULL, NULL, '2026-02-09 22:55:49', 'product', 0);
INSERT INTO `sys_image` VALUES (41, NULL, 'image.png', '/images/ac556fd1cf9b4cb1abfe283875a71b70.png', 251325, 'image/png', NULL, NULL, NULL, '2026-02-09 23:40:24', 'product', 0);
INSERT INTO `sys_image` VALUES (42, NULL, 'image copy 2.png', '/images/bd47415b483848669345f762129938cf.png', 349819, 'image/png', NULL, NULL, NULL, '2026-02-10 00:41:26', 'product', 0);
INSERT INTO `sys_image` VALUES (43, NULL, 'image.png', '/images/d12bf2e4e70f45928697a62bd20c80f8.png', 563911, 'image/png', NULL, NULL, NULL, '2026-02-10 00:43:16', 'product', 0);
INSERT INTO `sys_image` VALUES (44, NULL, 'image copy 2.png', '/images/06d51035f6d740edbb5769dc83eadd5e.png', 466436, 'image/png', NULL, NULL, NULL, '2026-02-10 00:43:43', 'product', 0);
INSERT INTO `sys_image` VALUES (45, NULL, 'image copy 5.png', '/images/b1145ce27105475daab729bd2c044435.png', 453101, 'image/png', NULL, NULL, NULL, '2026-02-10 00:51:39', 'product', 0);
INSERT INTO `sys_image` VALUES (46, NULL, 'image copy 2.png', '/images/6bd2429655c3436a9f3eb6047feaecd5.png', 552445, 'image/png', NULL, NULL, NULL, '2026-02-10 00:51:45', 'product', 0);
INSERT INTO `sys_image` VALUES (47, NULL, 'image copy 3.png', '/images/910b881ab68c4e38868df32553b1a270.png', 503298, 'image/png', NULL, NULL, NULL, '2026-02-10 00:51:48', 'product', 0);
INSERT INTO `sys_image` VALUES (48, NULL, 'image copy 4.png', '/images/2ce390ab01aa454fabb8c9d89f47c09b.png', 336401, 'image/png', NULL, NULL, NULL, '2026-02-10 00:51:51', 'product', 0);
INSERT INTO `sys_image` VALUES (49, NULL, 'image.png', '/images/c5ea913d6c4f4b719992f595108073f5.png', 324172, 'image/png', NULL, NULL, NULL, '2026-03-08 01:34:32', 'product', 0);
INSERT INTO `sys_image` VALUES (50, NULL, 'image copy.png', '/images/52d572ee89a4443a849eb60955eb05ba.png', 323591, 'image/png', NULL, NULL, NULL, '2026-03-08 01:34:36', 'product', 0);
INSERT INTO `sys_image` VALUES (51, NULL, 'image copy 3.png', '/images/3ddfc3964aa34b4e98768fa7b91ba22c.png', 409989, 'image/png', NULL, NULL, NULL, '2026-03-08 01:52:53', 'product', 0);
INSERT INTO `sys_image` VALUES (52, NULL, 'image copy 5.png', '/images/8e59174ed13b4eec923021a2c6e91c24.png', 347919, 'image/png', NULL, NULL, NULL, '2026-03-08 01:53:04', 'product', 0);
INSERT INTO `sys_image` VALUES (53, NULL, 'image copy.png', '/images/731841eab6f44f25a7012ad738aaf254.png', 462580, 'image/png', NULL, NULL, NULL, '2026-03-08 01:53:33', 'product', 0);
INSERT INTO `sys_image` VALUES (54, NULL, 'image copy 3.png', '/images/3b887786a8de438a867649223fcb4389.png', 409989, 'image/png', NULL, NULL, NULL, '2026-03-08 01:53:38', 'product', 0);
INSERT INTO `sys_image` VALUES (55, NULL, 'image copy 4.png', '/images/a005143dadc14798af03a344229cca26.png', 390828, 'image/png', NULL, NULL, NULL, '2026-03-08 01:53:50', 'product', 0);
INSERT INTO `sys_image` VALUES (56, NULL, 'image copy 2.png', '/images/7085b9abc95849de855aa2e7e2365a2a.png', 375089, 'image/png', NULL, NULL, NULL, '2026-04-10 22:30:42', 'product', 0);
INSERT INTO `sys_image` VALUES (57, NULL, 'image.png', '/images/dbbd8f3903924bb6b8c188467ae42574.png', 328283, 'image/png', NULL, NULL, NULL, '2026-04-10 22:30:47', 'product', 0);
INSERT INTO `sys_image` VALUES (58, NULL, 'image.png', '/images/59f76d18f65a49c7937b7d3736afb037.png', 787769, 'image/png', NULL, NULL, NULL, '2026-04-10 22:39:50', 'product', 0);
INSERT INTO `sys_image` VALUES (59, NULL, 'image copy.png', '/images/5ad51b941ccc432fac17b738b51664a6.png', 867345, 'image/png', NULL, NULL, NULL, '2026-04-10 22:39:54', 'product', 0);
INSERT INTO `sys_image` VALUES (60, NULL, 'image copy 4.png', '/images/300d0b01b0384218941799908a1276bd.png', 334883, 'image/png', NULL, NULL, NULL, '2026-04-10 22:46:03', 'product', 0);
INSERT INTO `sys_image` VALUES (61, NULL, 'image copy 2.png', '/images/430f57fce15f41b18ab35511c2880521.png', 479712, 'image/png', NULL, NULL, NULL, '2026-04-10 22:46:08', 'product', 0);
INSERT INTO `sys_image` VALUES (62, NULL, 'image.png', '/images/05a7dc58042446a3912f50a3cc9d047d.png', 209936, 'image/png', NULL, NULL, NULL, '2026-04-10 22:48:55', 'product', 0);
INSERT INTO `sys_image` VALUES (63, NULL, 'image copy.png', '/images/952d5911e845479cb1ba3072eb420219.png', 204181, 'image/png', NULL, NULL, NULL, '2026-04-10 22:48:59', 'product', 0);
INSERT INTO `sys_image` VALUES (64, NULL, 'image copy 3.png', '/images/d77ea52193414947b1133a640b00fe91.png', 783316, 'image/png', NULL, NULL, NULL, '2026-04-10 23:05:16', 'product', 0);
INSERT INTO `sys_image` VALUES (65, NULL, 'image.png', '/images/00170959838740d1ad2e5e8f1ef3bb5b.png', 2767546, 'image/png', NULL, NULL, NULL, '2026-04-10 23:10:46', 'product', 0);
INSERT INTO `sys_image` VALUES (66, NULL, 'image copy.png', '/images/19dae3d4911147f6a9f907ad0070f639.png', 265578, 'image/png', NULL, NULL, NULL, '2026-04-10 23:35:59', 'product', 0);
INSERT INTO `sys_image` VALUES (67, NULL, 'image.png', '/images/fc0ee5a8bc2c456aa7b4e8d9d68ab0ea.png', 259041, 'image/png', NULL, NULL, NULL, '2026-04-11 01:30:13', 'product', 0);
INSERT INTO `sys_image` VALUES (68, NULL, 'image copy.png', '/images/7fd64253bfcf4698b133316df2cdda8e.png', 193442, 'image/png', NULL, NULL, NULL, '2026-04-11 01:32:20', 'product', 0);
INSERT INTO `sys_image` VALUES (69, NULL, 'image copy 3.png', '/images/3d1dd6799f004f928ffaed8687a0c8ae.png', 182052, 'image/png', NULL, NULL, NULL, '2026-04-11 01:32:26', 'product', 0);
INSERT INTO `sys_image` VALUES (70, NULL, 'image.png', '/images/459d8113fe2a49d6be48352176d6e277.png', 251325, 'image/png', NULL, NULL, NULL, '2026-04-11 01:34:08', 'product', 0);
INSERT INTO `sys_image` VALUES (71, NULL, 'image.png', '/images/3d433a2c80b9471ea9dd30b2ec637710.png', 193991, 'image/png', NULL, NULL, NULL, '2026-04-11 01:37:10', 'product', 0);
INSERT INTO `sys_image` VALUES (72, NULL, 'image copy 2.png', '/images/24e668afd9de4e2db4ee14ae9ae5049d.png', 414015, 'image/png', NULL, NULL, NULL, '2026-04-11 01:40:12', 'product', 0);
INSERT INTO `sys_image` VALUES (73, NULL, 'image copy 2.png', '/images/a8df6409afac400b81ef80f6c4a62374.png', 479712, 'image/png', NULL, NULL, NULL, '2026-04-11 01:41:12', 'product', 0);
INSERT INTO `sys_image` VALUES (74, NULL, 'image.png', '/images/acf67e5d43ee45138555618b70afa5dd.png', 100787, 'image/png', NULL, NULL, NULL, '2026-04-11 01:42:20', 'product', 0);
INSERT INTO `sys_image` VALUES (75, NULL, 'image copy 2.png', '/images/2fd8e973dd5447d1947d9983ea87ce20.png', 552445, 'image/png', NULL, NULL, NULL, '2026-04-11 01:44:26', 'product', 0);
INSERT INTO `sys_image` VALUES (76, NULL, 'image copy 2.png', '/images/3fa0a908d12f4006b58941aee0883324.png', 318380, 'image/png', NULL, NULL, NULL, '2026-04-11 01:46:49', 'product', 0);
INSERT INTO `sys_image` VALUES (77, NULL, 'image copy 2.png', '/images/ad3aba846fc5463eadb918ece9e2217c.png', 713892, 'image/png', NULL, NULL, NULL, '2026-04-11 02:09:33', 'product', 0);
INSERT INTO `sys_image` VALUES (78, NULL, 'image copy 2.png', '/images/43bfac6b609446638a0556e291c3738c.png', 713892, 'image/png', NULL, NULL, NULL, '2026-04-11 02:10:38', 'product', 0);

-- ----------------------------
-- Table structure for sys_log
-- ----------------------------
DROP TABLE IF EXISTS `sys_log`;
CREATE TABLE `sys_log`  (
  `log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志唯一标识',
  `user_id` bigint NOT NULL COMMENT '关联user.user_id，未登录操作（如浏览商品）为 null',
  `log_type` tinyint NOT NULL COMMENT '日志类型：1 - 操作日志，2 - 错误日志',
  `operation` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '操作描述（如 “商品审核通过”“订单取消”）',
  `module` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '操作模块（如 “商品管理”“订单管理”）',
  `ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '操作 IP 地址（如 “127.0.0.1”）',
  `error_msg` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '错误信息（仅log_type=2时填写，如 “数据库连接超时”）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '日志生成时间',
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `user_id`(`user_id`, `log_type`, `module`, `ip`, `create_time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_log
-- ----------------------------
INSERT INTO `sys_log` VALUES (1, 1, 1, '更新用户状态', '用户管理', '127.0.0.1', NULL, '2026-03-08 00:02:39');
INSERT INTO `sys_log` VALUES (2, 1, 1, '更新用户状态', '用户管理', '127.0.0.1', NULL, '2026-03-08 00:02:42');
INSERT INTO `sys_log` VALUES (3, 1, 1, '更新用户状态', '用户管理', '127.0.0.1', NULL, '2026-03-08 00:02:51');
INSERT INTO `sys_log` VALUES (4, 1, 1, '更新用户状态', '用户管理', '127.0.0.1', NULL, '2026-03-08 00:02:52');
INSERT INTO `sys_log` VALUES (5, 1, 1, '更新用户状态', '用户管理', '127.0.0.1', NULL, '2026-03-08 00:14:23');
INSERT INTO `sys_log` VALUES (6, 1, 1, '更新用户状态', '用户管理', '127.0.0.1', NULL, '2026-03-08 00:14:24');
INSERT INTO `sys_log` VALUES (7, 1, 1, '禁用商家', '商家管理', '127.0.0.1', NULL, '2026-03-08 00:27:23');
INSERT INTO `sys_log` VALUES (8, 1, 1, '启用商家', '商家管理', '127.0.0.1', NULL, '2026-03-08 00:27:26');
INSERT INTO `sys_log` VALUES (9, 1, 1, '添加公告', '公告管理', '127.0.0.1', NULL, '2026-03-08 01:27:23');
INSERT INTO `sys_log` VALUES (10, 1, 1, '商品审核通过', '商品管理', '127.0.0.1', NULL, '2026-03-08 01:59:00');
INSERT INTO `sys_log` VALUES (11, 1, 1, '商品审核通过', '商品管理', '127.0.0.1', NULL, '2026-03-08 01:59:02');
INSERT INTO `sys_log` VALUES (12, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:05:57');
INSERT INTO `sys_log` VALUES (13, 1, 1, '商家审核通过', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:06:19');
INSERT INTO `sys_log` VALUES (14, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:07:11');
INSERT INTO `sys_log` VALUES (15, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:13:50');
INSERT INTO `sys_log` VALUES (16, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:13:59');
INSERT INTO `sys_log` VALUES (17, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:14:14');
INSERT INTO `sys_log` VALUES (18, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:15:13');
INSERT INTO `sys_log` VALUES (19, 1, 1, '商家审核驳回', '商家管理', '127.0.0.1', NULL, '2026-03-17 20:23:34');
INSERT INTO `sys_log` VALUES (20, 1, 1, '商品审核通过', '商品管理', '127.0.0.1', NULL, '2026-04-10 22:40:34');
INSERT INTO `sys_log` VALUES (21, 1, 1, '商品审核通过', '商品管理', '127.0.0.1', NULL, '2026-04-10 22:40:35');
INSERT INTO `sys_log` VALUES (22, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-10 22:47:36');
INSERT INTO `sys_log` VALUES (23, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-10 22:49:15');
INSERT INTO `sys_log` VALUES (24, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-10 23:05:44');
INSERT INTO `sys_log` VALUES (25, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-10 23:11:04');
INSERT INTO `sys_log` VALUES (26, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-10 23:37:17');
INSERT INTO `sys_log` VALUES (27, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:30:51');
INSERT INTO `sys_log` VALUES (28, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:32:51');
INSERT INTO `sys_log` VALUES (29, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:34:46');
INSERT INTO `sys_log` VALUES (30, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:37:42');
INSERT INTO `sys_log` VALUES (31, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:42:56');
INSERT INTO `sys_log` VALUES (32, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:42:57');
INSERT INTO `sys_log` VALUES (33, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:42:58');
INSERT INTO `sys_log` VALUES (34, 1, 1, '商品审核通过并上架', '商品管理', '127.0.0.1', NULL, '2026-04-11 01:44:50');

-- ----------------------------
-- Table structure for sys_notice
-- ----------------------------
DROP TABLE IF EXISTS `sys_notice`;
CREATE TABLE `sys_notice`  (
  `notice_id` bigint NOT NULL AUTO_INCREMENT COMMENT '通知唯一标识（自增主键）',
  `user_id` bigint NULL DEFAULT NULL COMMENT '接收通知的用户ID，关联user.user_id（个人/企业/管理员用户）',
  `content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '通知内容（需包含关键业务信息，如商品名称、订单号、违规原因等）',
  `notice_type` tinyint NOT NULL COMMENT '通知类型：0-通用通知，1-库存预警通知（3.2模块），2-退款通知（3.6/3.7模块），3-账号封禁/冻结通知（3.8/3.9模块），4-差评提醒通知（3.10模块），5-租赁到期提醒（3.8模块）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '通知创建时间（自动化触发时间）',
  `is_read` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读：0-未读，1-已读（用户查看后更新）',
  `expire_time` date NULL DEFAULT NULL COMMENT '通知有效期（如差评提醒48小时有效期，3.10模块），过期后可标记为无效',
  `notice_status` tinyint NOT NULL DEFAULT 0 COMMENT '通知状态：0-正常，1-已过期，2-已删除（逻辑删除，避免物理删除丢失记录）',
  PRIMARY KEY (`notice_id`) USING BTREE,
  INDEX `idx_sys_notice_user_id`(`user_id`) USING BTREE,
  INDEX `idx_sys_notice_user_create`(`user_id`, `create_time`) USING BTREE,
  INDEX `idx_sys_notice_type_status`(`notice_type`, `notice_status`) USING BTREE,
  CONSTRAINT `fk_sys_notice_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 56 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '系统通知表：存储库存预警、退款提醒、账号封禁、差评提醒等自动化通知，支撑业务规则落地' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_notice
-- ----------------------------
INSERT INTO `sys_notice` VALUES (1, 8, '您的商品【11 ZR】库存仅剩4件，请及时补货..', 1, '2025-12-29 23:05:05', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (2, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2025-12-29 23:05:07', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (4, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-01-02 05:08:07', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (5, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-01-02 05:10:47', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (6, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-01-02 05:10:50', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (9, 8, '您的商品【11 D850】库存仅剩4件，请及时补货', 1, '2026-01-08 22:18:40', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (10, 8, '您的商品【11 ZR】库存仅剩4件，请及时补货', 1, '2026-01-08 22:21:36', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (11, 8, '您的商品【11 ZR】库存仅剩4件，请及时补货', 1, '2026-01-08 22:21:56', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (12, 8, '您的商品【11 D850】库存仅剩4件，请及时补货', 1, '2026-01-11 16:25:57', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (14, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-01-11 16:31:56', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (15, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-01-11 16:40:06', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (16, 8, '你好', 0, '2026-01-11 16:54:34', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (17, 8, '您的商品【11 D850】库存仅剩4件，请及时补货', 1, '2026-01-21 21:14:20', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (18, 8, '您的商品【11 D850】库存仅剩4件，请及时补货', 1, '2026-01-21 21:14:21', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (19, 8, '您的商品【11 D850】库存仅剩4件，请及时补货', 1, '2026-01-21 21:25:55', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (20, 8, '您的商品【11 ZR】库存仅剩4件，请及时补货', 1, '2026-01-21 21:26:48', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (21, 8, '您的商品\"Z8\"审核通过，已自动上架。', 0, '2026-01-22 00:54:05', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (22, 8, '您的商品\"Z8\"审核驳回，原因：111111', 0, '2026-01-22 00:54:17', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (23, 8, '您的商品\"Z8\"已被管理员强制下架', 0, '2026-01-22 01:23:19', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (24, 8, '您的商品\"Z8\"已被管理员撤销，需要重新审核', 0, '2026-01-22 01:27:27', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (25, 8, '您的商品\"Z8\"审核通过，已自动上架。', 0, '2026-01-22 01:28:41', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (26, 8, '您的商品\"Z8\"已被管理员强制下架', 0, '2026-01-22 01:28:47', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (27, 8, '您的商品\"Z8\"已被管理员撤销，需要重新审核', 0, '2026-01-22 01:28:54', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (28, 8, '您的店铺\"摄影器材专营店\"认证审核驳回，原因：缺少材料', 0, '2026-02-09 17:42:27', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (29, 19, '您的店铺\"爱爱爱\"认证审核驳回，原因：111', 0, '2026-02-09 18:41:23', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (30, 19, '您的店铺\"爱爱爱\"认证审核通过，店铺已成功开通。', 0, '2026-02-09 19:21:26', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (31, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-02-09 20:13:51', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (32, 8, '您的商品【11 ZR】库存仅剩2件，请及时补货', 1, '2026-02-09 20:13:53', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (33, 8, '您的商品\"z8\"审核通过，已自动上架。', 0, '2026-02-09 21:20:44', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (34, 8, '您的商品\"z8\"审核通过，已自动上架。', 0, '2026-02-09 22:23:10', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (35, 8, '您的商品\"A7M4\"审核通过，已自动上架。', 0, '2026-02-09 22:56:08', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (36, 8, '您的商品\"Z72\"审核通过，已自动上架。', 0, '2026-02-10 00:42:14', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (37, 8, '您的商品\"ZR\"审核通过，已自动上架。', 0, '2026-02-10 00:44:07', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (38, 19, '您的商品\"Z63\"审核通过，已自动上架。', 0, '2026-02-10 00:52:16', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (39, 19, '您的商品\"Z63\"已被管理员强制下架', 0, '2026-02-10 00:52:22', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (40, 19, '您的商品\"Z63\"已被管理员撤销，需要重新审核', 0, '2026-02-10 00:52:31', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (41, 19, '您的商品\"Z63\"审核通过，已自动上架。', 0, '2026-02-10 01:09:53', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (42, 19, '您的商品\"Z63\"已被管理员强制下架', 0, '2026-02-10 01:09:58', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (43, 19, '您的商品\"Z63\"已被管理员撤销，需要重新审核', 0, '2026-02-10 01:10:01', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (44, 19, '您的商品\"Z63\"审核通过，已自动上架。', 0, '2026-02-10 01:52:29', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (45, NULL, '', 0, '2026-03-07 23:13:48', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (46, NULL, '', 0, '2026-03-07 23:13:55', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (47, 8, '啊啊啊啊啊啊啊啊啊啊', 0, '2026-03-08 00:01:28', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (48, 8, '21', 0, '2026-03-08 01:27:23', 1, NULL, 2);
INSERT INTO `sys_notice` VALUES (49, 21, '您的店铺审核已驳回，原因：111111111111111111111', 1, '2026-03-17 20:23:34', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (50, 8, '您的商品【11 ZR】库存仅剩-3件，请及时补货', 1, '2026-03-17 21:11:39', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (51, 8, '您的商品【11 ZR】库存仅剩-8件，请及时补货', 1, '2026-03-17 21:11:49', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (52, 19, '您的商品【11 Z63】库存仅剩-37件，请及时补货', 1, '2026-04-07 17:57:25', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (53, 19, '您的商品【11 Z63】库存仅剩-137件，请及时补货', 1, '2026-04-07 17:57:27', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (54, 8, '您的商品【11 Z62】库存仅剩-137件，请及时补货', 1, '2026-04-07 17:57:51', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (55, 8, '您的商品【11 Z62】库存仅剩-336件，请及时补货', 1, '2026-04-07 17:57:52', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (56, 8, '您的商品【41 ACTION 4】库存仅剩2件，请及时补货', 1, '2026-04-10 23:05:43', 1, NULL, 0);
INSERT INTO `sys_notice` VALUES (57, 8, '您的商品【41 ACTION 4】库存仅剩1件，请及时补货', 1, '2026-04-11 00:18:05', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (58, 8, '您的商品【41 ACTION 4】库存仅剩0件，请及时补货', 1, '2026-04-11 00:18:07', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (59, 8, '您的商品【21 Z 70-200mm f2.8 VR S】库存仅剩4件，请及时补货', 1, '2026-04-11 01:01:18', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (60, 8, '您的商品【21 Z 70-200mm f2.8 VR S】库存仅剩3件，请及时补货', 1, '2026-04-11 01:01:20', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (61, 8, '您的商品【21 Z 70-200mm f2.8 VR S】库存仅剩4件，请及时补货', 1, '2026-04-11 01:02:25', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (62, 8, '您的商品【11 ZR】库存仅剩4件，请及时补货', 1, '2026-04-11 01:03:04', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (63, 8, '您的商品【11 ZR】库存仅剩3件，请及时补货', 1, '2026-04-11 01:03:06', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (64, 8, '您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货', 1, '2026-04-11 01:30:50', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (65, 8, '您的商品【12 A7M4】库存仅剩3件，请及时补货', 1, '2026-04-11 01:34:45', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (66, 8, '您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货', 1, '2026-04-11 01:47:44', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (67, 8, '您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货', 1, '2026-04-11 01:55:37', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (68, 8, '您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货', 1, '2026-04-11 01:55:55', 0, NULL, 0);
INSERT INTO `sys_notice` VALUES (69, 8, '您的商品【11 D850】库存仅剩4件，请及时补货', 1, '2026-04-11 02:11:13', 0, NULL, 0);

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `user_id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识（自增 ID）',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '登录账号（个人为手机号 / 邮箱，企业为统一信用代码）',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '随机昵称（用户_+6位随机数）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '加密存储的密码（MD5 + 盐值）',
  `user_type` tinyint NOT NULL COMMENT '用户类型：1 - 个人用户，2 - 企业用户（器材商家），3 - 管理员，4 -超级管理员',
  `real_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '个人用户真实姓名（实名认证用）',
  `id_card` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '个人用户身份证号（加密存储，仅管理员可查看）',
  `avatar_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '用户头像路径（存储于本地public/head目录）',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '联系电话（用于验证码登录、订单通知）',
  `business_license` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '企业营业执照图片路径（存储于 MinIO / 本地）',
  `legal_id_front` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '法人身份证正面图片路径',
  `legal_id_back` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '法人身份证反面图片路径',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '邮箱（用于密码重置、系统通知）',
  `gender` tinyint NULL DEFAULT 0 COMMENT '性别：0 - 未知，1 - 男，2 - 女',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '账号状态：0 - 禁用（违规），1 - 正常，2 - 待审核（企业 / 个人未认证）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '账号创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '账号信息更新时间',
  `shop_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '店铺名称',
  `business_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '企业类型：personal-个人店铺，enterprise-企业店铺',
  `shop_status` tinyint NOT NULL DEFAULT 1 COMMENT '店铺状态：0-关闭，1-正常，2-审核中',
  `open_time` datetime NULL DEFAULT NULL COMMENT '开店时间',
  `shop_address` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '店铺地址',
  `shop_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL COMMENT '店铺简介',
  `has_shop` tinyint NOT NULL DEFAULT 0 COMMENT '是否有店铺：0-无，1-有',
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE INDEX `username`(`username`, `id_card`, `email`) USING BTREE,
  INDEX `user_type`(`user_type`, `phone`, `status`) USING BTREE,
  INDEX `user_id`(`user_id`, `username`) USING BTREE,
  CONSTRAINT `user_ibfk_1` FOREIGN KEY (`user_type`) REFERENCES `role` (`user_type`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 22 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。\r\n备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (1, '18344551990', 'Seventy7超管', '$2a$12$etCitOk68ONZtMTg6N25ZOXCVpWjqrBm4i7gtznXUD4TV1d5J7U5m', 4, '詹仕杰', '', '', '18344551990', NULL, NULL, NULL, '3324879861@qq.com', 1, 1, '2026-03-07 20:34:37', '2026-03-07 20:34:37', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (2, '18344551993', 'Seventy7普管', '$2a$12$etCitOk68ONZtMTg6N25ZOXCVpWjqrBm4i7gtznXUD4TV1d5J7U5m', 3, '詹仕杰', '', '', '18344551993', NULL, NULL, NULL, '3324879861@qq.com', 1, 1, '2026-03-07 20:34:39', '2026-03-07 20:34:39', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (7, '18344551991', 'Seventy7', '$2a$12$y.Rt69W9faL0lPR.vniTpe.Np4PDPNeuoBjCVcKDTF8K2uh5KUhq.', 1, '詹仕杰', '445122200308210917', '/head/04953aa3-09d4-420b-970b-29ebd4ce31f1.JPG', '18344551991', NULL, NULL, NULL, '3324879861@qq.com', 1, 1, '2026-01-11 15:40:12', '2026-04-10 21:08:54', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (8, '52440000799352866W', '摄影优品', '$2a$12$oEeivQpmHhIGFNziDyxYIOYaibQ.uAHGf3UUAM7ZzfKUYxajlthp6', 2, '广软', NULL, '/head/shop_58711c1b-1b43-4275-84d3-5ca6248828a1.png', '18344551992', '/auth/auth_8_53242743-b96d-4d6c-badd-c3a2a0529fa1.png', '/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png', '/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png', '3324879861@qq.com', 0, 1, '2026-03-07 23:12:31', '2026-03-07 23:12:31', '摄影器材专营店', 'enterprise', 1, '2025-01-15 00:00:00', '北京市朝阳区建国路88号', '专业摄影器材销售、租赁和二手交易.', 1);
INSERT INTO `user` VALUES (9, '18344551999', '用户_418092', '$2a$12$cyG5Q8FzHvCHfvRTzX4bTecytZPgfnInlQfHZzJ0tjtTmi8mr1zOa', 3, NULL, NULL, NULL, '', NULL, NULL, NULL, '3324879861@qq.com', 0, 0, '2026-03-07 20:34:41', '2026-03-07 20:34:41', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (11, '18344551994', '用户_539209', '$2a$12$cyG5Q8FzHvCHfvRTzX4bTecytZPgfnInlQfHZzJ0tjtTmi8mr1zOa', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '3324879861@qq.com', 0, 1, '2026-03-07 20:34:42', '2026-03-07 20:34:42', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (17, '18344551998', '用户_885077', '$2a$12$cPVMHtcAn0hKFR7KUKAmsejqqajcoJ64xgWpASabzgvFhhMZREWqm', 3, NULL, NULL, NULL, '', NULL, NULL, NULL, '3324879861@qq.com', 0, 1, '2026-03-07 20:34:44', '2026-03-07 20:34:44', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (19, '123456789123456789', '用户_889684', '$2a$12$c45vhPps7FL8DuA.07Jdn.zKn5JVkA5FqQgt9zxaWrf4qBWQR1U3O', 2, NULL, NULL, '/head/shop_96af7a46-e549-4fbf-8452-419d93a08b2e.png', '18344551990', '/auth/auth_19_e86e1ef7-60c3-43ee-a473-dbc1ee60f922.png', '/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png', '/auth/auth_19_a6367c0a-31fe-46ea-943d-11a026eb4355.png', '3324879861@qq.com', 0, 1, '2026-03-01 21:11:04', '2026-03-01 21:11:04', 'AAA', 'personal', 1, '2026-02-09 19:21:26', '66666666', '啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊', 1);
INSERT INTO `user` VALUES (20, '15113747673', '用户_791222', '$2a$12$kIxuvY35kdDYWjUFJzQeA.VloOmB.SfN/nmc0Skaw.kdKldbnalFi', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '3324879861@qq.com', 0, 1, '2026-03-07 20:39:49', '2026-03-07 20:39:49', NULL, NULL, 1, NULL, NULL, NULL, 0);
INSERT INTO `user` VALUES (21, '888888888888888888', '用户_378138', '$2a$12$PrH4w1gz/yWTQNdOlUbDaexbJFmFUVwSF/EZESR72BN0SX5UFDM3y', 2, NULL, NULL, NULL, NULL, '/auth/auth_21_b931fcfc-a8c7-451a-ba8b-23385c4f59b5.png', '/auth/auth_21_3e70886e-69db-4151-9a16-e095e87fb106.png', '/auth/auth_21_e94086c6-c7ce-41fd-a0ed-e23cd21e30cb.png', '3324879861@qq.com', 0, 2, '2026-03-17 20:06:46', '2026-03-17 21:44:19', NULL, NULL, 2, NULL, NULL, NULL, 1);

-- ----------------------------
-- Table structure for user_address
-- ----------------------------
DROP TABLE IF EXISTS `user_address`;
CREATE TABLE `user_address`  (
  `address_id` bigint NOT NULL AUTO_INCREMENT COMMENT '地址ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `recipient` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '收货人',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '电话',
  `province` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '省份',
  `city` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '城市',
  `district` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '区/县',
  `detail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '详细地址',
  `is_default` tinyint NOT NULL DEFAULT 0 COMMENT '是否默认地址',
  PRIMARY KEY (`address_id`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  CONSTRAINT `user_address_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user_address
-- ----------------------------
INSERT INTO `user_address` VALUES (15, 1, '詹仕杰', '18344551990', '广东省', '广州市', '从化区', '广从南路548号广州软件学院', 1);
INSERT INTO `user_address` VALUES (16, 1, '詹先生', '18344551990', '广东省', '潮州市', '饶平县', '饶洋镇陈坑村上坑202号', 1);
INSERT INTO `user_address` VALUES (17, 7, '詹', '18344551990', '44', '4401', '440117', '广从南路548号广州软件学院', 1);
INSERT INTO `user_address` VALUES (18, 11, '111', '18344551994', '11', '1101', '110101', '111', 1);
INSERT INTO `user_address` VALUES (19, 7, 'shijie', '18344551990', '44', '4401', '440117', '广从南路548号11111', 0);

-- ----------------------------
-- Table structure for user_member
-- ----------------------------
DROP TABLE IF EXISTS `user_member`;
CREATE TABLE `user_member`  (
  `member_id` bigint NOT NULL AUTO_INCREMENT COMMENT '会员记录唯一标识',
  `user_id` bigint NOT NULL COMMENT '外键，关联user.user_id，非会员用户无此记录',
  `member_level` tinyint NOT NULL DEFAULT 1 COMMENT '会员等级：1 - 青铜，2 - 白银，3 - 黄金（按年度消费金额分级）',
  `expire_time` datetime NOT NULL COMMENT '会员有效期（黄金会员默认 1 年，到期自动降级）',
  `deposit_discount` decimal(5, 2) NOT NULL DEFAULT 0.00 COMMENT '租赁押金减免比例（如 30.00 表示减免 30%，黄金会员专属）',
  `annual_consume` decimal(12, 2) NOT NULL DEFAULT 0.00 COMMENT '年度消费金额（用于会员等级升级判断）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '会员开通时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '会员信息更新时间',
  PRIMARY KEY (`member_id`) USING BTREE,
  UNIQUE INDEX `user_id`(`user_id`) USING BTREE,
  INDEX `member_level`(`member_level`, `expire_time`) USING BTREE,
  CONSTRAINT `user_member_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用途：存储个人用户的会员等级与专属权益，支撑租赁押金减免、优先购买等业务规则。' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user_member
-- ----------------------------

-- ----------------------------
-- Triggers structure for table evaluation
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_evaluation_bad_remind`;
delimiter ;;
CREATE TRIGGER `trg_evaluation_bad_remind` AFTER INSERT ON `evaluation` FOR EACH ROW BEGIN
    -- 仅当评分低于3星（差评）时触发提醒
    IF NEW.score < 3 THEN
        INSERT INTO sys_notice (
            notice_id, 
            user_id, 
            content, 
            notice_type, 
            create_time, 
            is_read,
            expire_time  -- 48小时有效期（用于逾期未回复判断）
        ) VALUES (
            NULL,
            NEW.seller_id,  -- 接收提醒的商家ID
            CONCAT('您收到一条来自用户【', NEW.user_id, '】的差评（订单【', NEW.order_id, '】），请在48小时内回复'),
            4,  -- 4-差评提醒通知类型
            CURRENT_TIMESTAMP,
            0,
            DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 DAY)  -- 计算48小时后过期时间
        );
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table inventory
-- ----------------------------
DROP TRIGGER IF EXISTS `sync_inventory_stock_to_product`;
delimiter ;;
CREATE TRIGGER `sync_inventory_stock_to_product` AFTER UPDATE ON `inventory` FOR EACH ROW BEGIN
    -- 只有当current_stock实际变化时才同步到product表的stock字段
    IF NEW.current_stock <> OLD.current_stock THEN
        UPDATE product 
        SET stock = NEW.current_stock
        WHERE product_id = NEW.product_id;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table product
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_product_stock_alert`;
delimiter ;;
CREATE TRIGGER `trg_product_stock_alert` AFTER UPDATE ON `product` FOR EACH ROW BEGIN
    -- 仅当库存低于5件时触发提醒
    IF NEW.stock < 5 THEN
        INSERT INTO sys_notice (
            notice_id, 
            user_id, 
            content, 
            notice_type, 
            create_time, 
            is_read
        ) VALUES (
            NULL,
            -- 关联商品所属商家ID
            (SELECT seller_id FROM product WHERE product_id = NEW.product_id),
            -- 拼接提醒内容（含商品品牌、型号、当前库存）
            CONCAT('您的商品【', NEW.brand, ' ', NEW.model, '】库存仅剩', NEW.stock, '件，请及时补货'),
            1,  -- 1-库存预警通知类型
            CURRENT_TIMESTAMP,
            0   -- 0-未读状态
        );
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table product
-- ----------------------------
DROP TRIGGER IF EXISTS `after_product_insert`;
delimiter ;;
CREATE TRIGGER `after_product_insert` AFTER INSERT ON `product` FOR EACH ROW BEGIN
    -- 只处理租赁商品
    IF NEW.product_type = 3 THEN
        -- 为新租赁商品创建默认的product_rental_detail记录
        INSERT INTO product_rental_detail (
            product_id, deposit, max_rental_days, min_rental_days, 
            insurance_fee, late_fee_rate, damage_fee_rule, 
            pickup_methods, delivery_fee
        ) VALUES (
            NEW.product_id, 
            NEW.original_price * 0.1, -- 默认押金为原价的10%
            90, -- 默认最长租赁期限
            NEW.min_rental_days, -- 使用product表中的起租天数
            0.00, -- 默认保险费用
            0.05, -- 默认逾期违约金率
            '请联系客服了解详细赔偿规则', -- 默认损坏赔偿规则
            'delivery', -- 默认取货方式
            0.00 -- 默认配送费用
        );
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table product
-- ----------------------------
DROP TRIGGER IF EXISTS `after_product_update`;
delimiter ;;
CREATE TRIGGER `after_product_update` AFTER UPDATE ON `product` FOR EACH ROW BEGIN
    -- 声明变量
    DECLARE detail_count INT;
    
    -- 只处理租赁商品
    IF NEW.product_type = 3 THEN
        -- 检查product_rental_detail表中是否存在对应记录
        SELECT COUNT(*) INTO detail_count FROM product_rental_detail WHERE product_id = NEW.product_id;
        
        IF detail_count > 0 THEN
            -- 更新已存在的记录
            UPDATE product_rental_detail
            SET 
                min_rental_days = NEW.min_rental_days,
                deposit = NEW.original_price * 0.1,
                updated_time = NOW()
            WHERE product_id = NEW.product_id;
        ELSE
            -- 创建新记录
            INSERT INTO product_rental_detail (
                product_id, deposit, max_rental_days, min_rental_days, 
                insurance_fee, late_fee_rate, damage_fee_rule, 
                pickup_methods, delivery_fee
            ) VALUES (
                NEW.product_id, 
                NEW.original_price * 0.1, -- 默认押金为原价的10%
                90, -- 默认最长租赁期限
                NEW.min_rental_days, -- 使用product表中的起租天数
                0.00, -- 默认保险费用
                0.05, -- 默认逾期违约金率
                '请联系客服了解详细赔偿规则', -- 默认损坏赔偿规则
                'delivery', -- 默认取货方式
                0.00 -- 默认配送费用
            );
        END IF;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table rental
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_rental_overdue_freeze`;
delimiter ;;
CREATE TRIGGER `trg_rental_overdue_freeze` AFTER UPDATE ON `rental` FOR EACH ROW BEGIN
    -- 仅当逾期天数首次达到7天及以上时触发（避免重复冻结）
    IF NEW.overdue_days >= 7 AND OLD.overdue_days < 7 THEN
        -- 1. 冻结用户账号（设为禁用状态0）
        UPDATE user 
        SET 
            status = 0,
            update_time = CURRENT_TIMESTAMP 
        WHERE user_id = (SELECT user_id FROM `order` WHERE order_id = NEW.order_id);
        
        -- 2. 发送逾期冻结通知
        INSERT INTO sys_notice (
            notice_id, 
            user_id, 
            content, 
            notice_type, 
            create_time, 
            is_read
        ) VALUES (
            NULL,
            (SELECT user_id FROM `order` WHERE order_id = NEW.order_id),
            CONCAT('您的租赁订单【', NEW.order_id, '】已逾期', NEW.overdue_days, '天，账号已冻结，请立即归还器材'),
            3,  -- 3-账号冻结通知类型
            CURRENT_TIMESTAMP,
            0
        );
        
        -- 3. 更新订单状态为“逾期冻结”（新增状态5）
        UPDATE `order` 
        SET 
            order_status = 5,
            update_time = CURRENT_TIMESTAMP 
        WHERE order_id = NEW.order_id;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table second_hand
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_second_hand_illegal_ban`;
delimiter ;;
CREATE TRIGGER `trg_second_hand_illegal_ban` AFTER UPDATE ON `second_hand` FOR EACH ROW BEGIN
    DECLARE v_audit_status INT;
    DECLARE v_reject_reason VARCHAR(255);
    DECLARE v_seller_id INT;

    -- 从product表获取audit_status、reject_reason和seller_id
    SELECT p.audit_status, p.reject_reason, p.seller_id
    INTO v_audit_status, v_reject_reason, v_seller_id
    FROM product p
    WHERE p.product_id = NEW.product_id;

    -- 仅当审核驳回且原因含“翻新机”“拼装机”时触发封禁
    IF v_audit_status = 2
    AND (v_reject_reason LIKE '%翻新机%' OR v_reject_reason LIKE '%拼装机%') THEN
        -- 1. 封禁违规商家账号（设为禁用状态）
        UPDATE user
        SET status = 0,
            update_time = CURRENT_TIMESTAMP
        WHERE user_id = v_seller_id;

        -- 2. 发送账号封禁通知
        INSERT INTO sys_notice (
            notice_id,
            user_id,
            content,
            notice_type,
            create_time,
            is_read
        ) VALUES (
            NULL,
            v_seller_id,
            '您发布的二手器材因涉及“翻新机/拼装机”违规，账号已永久封禁，详情联系管理员',
            3, -- 3-账号封禁通知类型
            CURRENT_TIMESTAMP,
            0
        );
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table user
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_user_nickname`;
delimiter ;;
CREATE TRIGGER `trg_user_nickname` BEFORE INSERT ON `user` FOR EACH ROW BEGIN
  -- 生成 "用户_xxxxxx"（6位随机数，范围 000000-999999）
  SET NEW.nickname = CONCAT('用户_', FLOOR(RAND() * 1000000));
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
