-- MySQL dump 10.13  Distrib 8.0.30, for Win64 (x86_64)
--
-- Host: localhost    Database: db_bysj_pets
-- ------------------------------------------------------
-- Server version	8.0.30

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `db_bysj_pets`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `db_bysj_pets` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `db_bysj_pets`;

--
-- Table structure for table `brand`
--

DROP TABLE IF EXISTS `brand`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `brand` (
  `brand_id` int NOT NULL AUTO_INCREMENT COMMENT '品牌ID',
  `brand_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '品牌名称',
  `parent_id` int DEFAULT NULL COMMENT '外键，父类ID（相机-尼康；镜头-适马）',
  `category_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类编码，按层级规则生成（如顶级分类 “相机” 编码为 “CAM”，子分类 “全画幅相机” 编码为 “CAM-FULL”）',
  `sort` int NOT NULL DEFAULT '0' COMMENT '分类排序（数值越小越靠前）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '分类状态：\r\n- 1 = 启用（可被商品关联、前端展示）\r\n- 0 = 禁用（不可关联商品、前端隐藏）',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '分类描述',
  `create_by` bigint NOT NULL COMMENT '外键,分类创建人 ID，关联user.user_id（仅管理员可创建分类）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '外键,分类更新人 ID，关联user.user_id（仅管理员可更新分类',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类更新时间',
  PRIMARY KEY (`brand_id`) USING BTREE,
  UNIQUE KEY `category_name` (`brand_name`,`category_code`) USING BTREE,
  KEY `parent_id` (`parent_id`,`sort`,`status`,`create_by`,`update_by`) USING BTREE,
  KEY `create_by` (`create_by`) USING BTREE,
  KEY `product_category_ibfk_3` (`update_by`) USING BTREE,
  KEY `parent_id_2` (`parent_id`) USING BTREE,
  CONSTRAINT `brand_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `brand` (`brand_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `brand_ibfk_2` FOREIGN KEY (`create_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `brand_ibfk_3` FOREIGN KEY (`update_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储品牌分类（如相机-尼康、镜头-适马、灯光设备-神牛），为product提供分类关联。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `brand`
--

/*!40000 ALTER TABLE `brand` DISABLE KEYS */;
INSERT INTO `brand` VALUES (1,'相机',NULL,'CAM',0,1,NULL,1,'2026-03-07 22:23:22',2,'2026-03-07 22:23:23'),(2,'镜头',NULL,'LEN',0,1,NULL,1,'2026-01-06 23:41:05',1,'2026-01-06 23:41:06'),(3,'无人机',NULL,'DRONE',0,1,NULL,1,'2026-04-10 18:22:07',NULL,'2026-04-10 18:22:10'),(11,'尼康',1,'NIKON',1,1,NULL,1,'2026-01-06 23:44:36',1,'2026-01-06 23:44:37'),(12,'索尼',1,'SONY',1,1,'刀法',1,'2026-01-11 16:20:07',1,'2026-01-11 16:20:08'),(13,'佳能',1,'CANON',1,1,NULL,1,'2026-04-10 18:20:36',1,'2026-04-10 18:20:36'),(14,'富士',1,'FUJIFILM',1,1,NULL,1,'2026-04-10 18:21:24',NULL,'2026-04-10 18:21:26'),(21,'尼克尔',2,'NIKKOR',1,1,'尼康-尼克尔镜头',1,'2026-01-11 16:19:50',1,'2026-01-11 16:19:51'),(22,'索尼',2,'SONY_LENS',1,1,'',1,'2026-01-11 16:20:03',1,'2026-01-11 16:20:04'),(23,'佳能',2,'CANON_LENS',1,1,NULL,1,'2026-04-10 18:20:31',1,'2026-04-10 18:20:31'),(31,'三脚架',NULL,'TRIPOD',0,1,'',1,'2026-01-11 16:12:44',NULL,'2026-01-11 16:12:44'),(34,'闪光灯',NULL,'FLASHLIGHT',0,1,'',1,'2026-01-11 16:18:19',NULL,'2026-01-11 16:18:19'),(35,'斯莫格',31,'SMALLRIG',1,1,'斯莫格',1,'2026-01-11 16:19:31',1,'2026-01-11 16:19:31'),(37,'大疆',3,'DJI',1,1,NULL,1,'2026-04-10 18:23:03',NULL,'2026-04-10 18:23:05'),(41,'大疆-Action',1,'DJI-ACTION',1,1,'111111111111',1,'2026-04-10 22:38:40',NULL,'2026-04-10 22:38:40');
/*!40000 ALTER TABLE `brand` ENABLE KEYS */;

--
-- Table structure for table `cart`
--

DROP TABLE IF EXISTS `cart`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart` (
  `cart_id` bigint NOT NULL AUTO_INCREMENT COMMENT '购物车记录唯一标识',
  `user_id` bigint NOT NULL COMMENT '外键,关联user.user_id，用户删除时同步清空购物车',
  `product_id` bigint NOT NULL COMMENT '外键,关联product.product_id，商品下架时标记 “已下架”',
  `quantity` int NOT NULL DEFAULT '1' COMMENT '商品数量（购买场景）或租赁数量（租赁场景，默认 1）',
  `lease_term` int DEFAULT '1' COMMENT '租期（仅租赁场景用，单位：天，如 1-90 天）',
  `select_status` tinyint NOT NULL DEFAULT '1' COMMENT '是否勾选结算：0 - 未勾选，1 - 已勾选',
  `preoccupy_time` datetime DEFAULT NULL COMMENT '租赁商品预占库存时间（加入购物车后 24 小时内有效，超时自动释放）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '加入购物车时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '购物车信息更新时间',
  PRIMARY KEY (`cart_id`) USING BTREE,
  KEY `user_id` (`user_id`,`product_id`,`preoccupy_time`) USING BTREE,
  KEY `product_id` (`product_id`) USING BTREE,
  CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储用户加入购物车的商品信息，支持购买 / 租赁场景的临时数据存储与状态同步。\r\n备注：商品下架或库存不足时，select_status自动设为 0，不可结算；未登录用户购物车存储于本地，登录后通过user_id合并至该表。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cart`
--

/*!40000 ALTER TABLE `cart` DISABLE KEYS */;
INSERT INTO `cart` VALUES (30,1,1,1,1,1,NULL,'2025-12-29 21:43:29','2025-12-29 21:43:29'),(32,7,4,1,1,1,NULL,'2025-12-30 21:13:14','2025-12-30 21:13:14'),(34,7,5,1,1,1,NULL,'2026-02-08 17:36:04','2026-02-08 17:36:04'),(37,7,1,1,1,1,NULL,'2026-04-10 21:02:22','2026-04-10 21:02:22'),(60,23,32,1,1,1,NULL,'2026-10-15 06:10:36','2026-10-15 06:10:36');
/*!40000 ALTER TABLE `cart` ENABLE KEYS */;

--
-- Table structure for table `evaluation`
--

DROP TABLE IF EXISTS `evaluation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `evaluation` (
  `eval_id` bigint NOT NULL AUTO_INCREMENT COMMENT '评价唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联order.order_id，订单删除时同步删除评价',
  `product_id` bigint NOT NULL COMMENT '关联product.product_id，商品下架不影响评价展示',
  `user_id` bigint NOT NULL COMMENT '关联user.user_id，评价归属用户',
  `seller_id` bigint NOT NULL COMMENT '关联user.user_id，评价对应的商家',
  `score` tinyint NOT NULL COMMENT '综合评分（1-5 星，1 星最差，5 星最好）',
  `quality_score` tinyint NOT NULL COMMENT '器材质量评分（1-5 星，仅购买 / 租赁 / 二手场景）',
  `service_score` tinyint NOT NULL COMMENT '商家服务评分（1-5 星，所有场景）',
  `logistics_score` tinyint DEFAULT NULL COMMENT '物流速度评分（1-5 星，仅购买 / 二手场景，自提为 5 星）',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '评价内容（≥10 字，禁止辱骂、虚假内容）',
  `img_urls` json DEFAULT NULL COMMENT '评价图片路径（JSON 数组，≤5 张）',
  `eval_status` tinyint NOT NULL DEFAULT '1' COMMENT '评价状态：0 - 已删除，1 - 正常展示，2 - 违规隐藏（管理员操作）',
  `reply_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '商家回复内容',
  `reply_time` datetime DEFAULT NULL COMMENT '商家回复时间',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '评价提交时间',
  `update_time` datetime NOT NULL COMMENT '评价状态更新时间',
  PRIMARY KEY (`eval_id`) USING BTREE,
  UNIQUE KEY `order_id` (`order_id`) USING BTREE,
  KEY `product_id` (`product_id`,`user_id`,`seller_id`,`score`,`eval_status`,`create_time`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `seller_id` (`seller_id`) USING BTREE,
  CONSTRAINT `evaluation_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `evaluation_ibfk_3` FOREIGN KEY (`seller_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `evaluation_ibfk_4` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `evaluation_ibfk_5` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储用户对订单的评价与评分，关联商品与商家，支撑消费信任体系。\r\n备注：订单完成后 7 天内可提交评价，提交后 24 小时内可删除重评；评分低于 3 星的 “差评”，系统提醒商家 48 小时内回复。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evaluation`
--

/*!40000 ALTER TABLE `evaluation` DISABLE KEYS */;
INSERT INTO `evaluation` VALUES (6,54,1,7,1,5,5,5,5,'好好好好好好好好好好',NULL,1,NULL,NULL,'2026-03-07 19:48:08','2026-03-07 19:48:08'),(7,84,6,7,1,5,5,5,NULL,'',NULL,1,NULL,NULL,'2026-04-11 12:29:44','2026-04-11 12:29:44'),(8,55,1,7,8,4,4,3,4,'东西没问题，发货稍微慢了一天。客服回复比较及时，整体可以。','[]',1,'感谢反馈，包装环节我们已经加了一层缓冲，后续会注意发货时效。','2026-10-21 03:42:34','2026-10-15 03:44:16','2026-10-20 03:42:34'),(9,56,1,7,8,5,5,4,5,'包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。','[]',1,NULL,NULL,'2026-10-20 03:42:34','2026-10-20 03:42:34'),(10,59,2,11,8,5,5,4,5,'包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。','[]',1,NULL,NULL,'2026-02-14 20:38:11','2026-02-14 20:38:11'),(11,65,1,7,8,4,4,3,4,'东西没问题，发货稍微慢了一天。客服回复比较及时，整体可以。','[]',1,'感谢反馈，包装环节我们已经加了一层缓冲，后续会注意发货时效。','2026-03-23 21:37:03','2026-10-15 03:44:16','2026-03-22 21:37:03'),(12,73,30,7,8,5,5,4,5,'包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。','[]',1,NULL,NULL,'2026-04-16 00:18:43','2026-04-16 00:18:43'),(13,74,7,7,8,5,5,4,5,'包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。','[]',1,NULL,NULL,'2026-04-16 00:23:02','2026-04-16 00:23:02'),(14,76,32,7,8,4,4,3,4,'东西没问题，发货稍微慢了一天。客服回复比较及时，整体可以。','[]',1,'感谢反馈，包装环节我们已经加了一层缓冲，后续会注意发货时效。','2026-04-17 00:25:13','2026-10-15 03:44:16','2026-04-16 00:25:13'),(15,78,6,7,8,5,5,4,5,'包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。','[]',1,NULL,NULL,'2026-04-16 00:51:30','2026-04-16 00:51:30'),(16,80,7,7,8,3,3,3,3,'收到后发现和描述有一点出入，已和客服沟通，处理态度还行。','[]',1,'感谢反馈，包装环节我们已经加了一层缓冲，后续会注意发货时效。','2026-04-17 01:02:25','2026-10-15 03:44:16','2026-04-16 01:02:25'),(17,85,6,7,8,5,5,4,5,'包装很扎实，泡沫分三层，机身和镜头都没有磕碰。参数和描述一致，开机测试一切正常。','[]',1,NULL,NULL,'2026-04-16 12:32:27','2026-04-16 12:32:27'),(18,86,6,7,8,4,4,3,4,'东西没问题，发货稍微慢了一天。客服回复比较及时，整体可以。','[]',1,'感谢反馈，包装环节我们已经加了一层缓冲，后续会注意发货时效。','2026-04-17 14:58:22','2026-10-15 03:44:16','2026-04-16 14:58:22');
/*!40000 ALTER TABLE `evaluation` ENABLE KEYS */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_evaluation_bad_remind` AFTER INSERT ON `evaluation` FOR EACH ROW BEGIN
    
    IF NEW.score < 3 THEN
        INSERT INTO sys_notice (
            notice_id, 
            user_id, 
            content, 
            notice_type, 
            create_time, 
            is_read,
            expire_time  
        ) VALUES (
            NULL,
            NEW.seller_id,  
            CONCAT('您收到一条来自用户【', NEW.user_id, '】的差评（订单【', NEW.order_id, '】），请在48小时内回复'),
            4,  
            CURRENT_TIMESTAMP,
            0,
            DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 DAY)  
        );
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `favorite`
--

DROP TABLE IF EXISTS `favorite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favorite` (
  `favorite_id` bigint NOT NULL AUTO_INCREMENT COMMENT '收藏记录唯一标识',
  `user_id` bigint NOT NULL COMMENT '用户ID，关联user.user_id',
  `product_id` bigint NOT NULL COMMENT '商品ID，关联product.product_id',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`favorite_id`) USING BTREE,
  UNIQUE KEY `user_product_unique` (`user_id`,`product_id`) USING BTREE COMMENT '用户对同一商品只能收藏一次',
  KEY `product_id` (`product_id`) USING BTREE,
  CONSTRAINT `favorite_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `favorite_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储用户收藏的商品信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favorite`
--

/*!40000 ALTER TABLE `favorite` DISABLE KEYS */;
INSERT INTO `favorite` VALUES (12,1,2,'2025-12-25 01:06:42'),(15,1,4,'2025-12-27 19:07:00'),(20,1,5,'2025-12-28 00:05:32'),(21,1,6,'2025-12-28 20:33:59'),(22,1,1,'2025-12-29 21:43:30'),(23,1,3,'2025-12-29 21:43:35'),(31,7,7,'2026-02-08 01:06:51'),(42,7,4,'2026-02-08 19:06:54'),(43,7,5,'2026-02-08 19:07:42'),(50,7,3,'2026-02-08 19:36:28'),(51,11,1,'2026-02-09 20:13:20'),(56,7,2,'2026-03-17 21:10:30'),(62,7,1,'2026-04-11 12:23:45'),(66,7,6,'2026-04-11 14:56:40'),(67,23,1,'2026-10-15 06:08:07'),(68,23,32,'2026-10-15 06:10:38');
/*!40000 ALTER TABLE `favorite` ENABLE KEYS */;

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '库存ID',
  `product_id` bigint NOT NULL COMMENT '商品ID',
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '商品名称',
  `product_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '商品类型(new:全新, used:二手, rental:租赁)',
  `sku_id` bigint NOT NULL COMMENT 'SKU ID',
  `sku_attribute` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT 'SKU属性',
  `sku_value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT 'SKU值',
  `current_stock` int NOT NULL COMMENT '当前库存',
  `min_stock` int NOT NULL DEFAULT '10' COMMENT '安全库存',
  `sales` int NOT NULL DEFAULT '0' COMMENT '销量',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_product_sku` (`product_id`,`sku_id`),
  KEY `idx_product_id` (`product_id`) USING BTREE,
  KEY `idx_sku_id` (`sku_id`) USING BTREE,
  KEY `idx_product_type` (`product_type`) USING BTREE,
  KEY `idx_min_stock` (`min_stock`) USING BTREE,
  KEY `idx_current_stock` (`current_stock`) USING BTREE,
  KEY `idx_last_update_time` (`last_update_time`) USING BTREE,
  KEY `idx_product_name` (`product_name`(100)) USING BTREE,
  CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_inventory_sku` FOREIGN KEY (`sku_id`) REFERENCES `sku` (`sku_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='库存表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory`
--

/*!40000 ALTER TABLE `inventory` DISABLE KEYS */;
INSERT INTO `inventory` VALUES (1,1,'尼康 Z6II','new',1,'颜色','黑色',66,11,120,'2026-01-02 19:43:23','2026-10-15 06:08:46'),(2,2,'尼康 Z 24-120 F4S','new',2,'版本','国行',3,10,95,'2026-01-02 19:43:23','2026-10-15 05:18:53'),(3,3,'索尼 A7R5','new',3,'套餐','单机',99,10,88,'2026-01-02 19:43:23','2026-01-02 20:49:41'),(4,4,'尼康 D850','used',4,'成色','95新',1,5,45,'2026-01-02 19:43:23','2026-10-15 05:18:53'),(5,5,'尼康 Z6','used',5,'成色','90新',1,10,67,'2026-01-02 19:43:23','2026-10-15 05:18:53'),(6,6,'尼康 ZR','rental',6,'状态','可租',84,5,32,'2026-01-02 19:43:23','2026-10-15 05:18:53'),(7,7,'尼康 Z 70-200mm f2.8 VR S','rental',7,'状态','可租',4,20,56,'2026-01-02 19:43:23','2026-10-15 05:18:53'),(9,8,'尼康 Z8','new',11,'默认','默认',88,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(10,15,'尼康 Z8','new',12,'默认','默认',88,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(11,20,'尼康 z8','new',13,'默认','默认',8555,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(12,21,'索尼 A7M4','new',14,'默认','默认',220,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(13,22,'尼康 Z72','used',15,'默认','默认',1,10,0,'2026-04-11 01:25:09','2026-10-15 05:18:53'),(14,23,'尼康 ZR','new',9,'默认','默认',111,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(15,24,'尼康 Z63','new',16,'默认','默认',0,10,0,'2026-04-11 01:25:09','2026-10-15 05:18:53'),(16,25,'尼克尔 50mm F1.8 S','new',17,'默认','默认',90,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(17,26,'佳能 EOS R5 Mark II','used',18,'默认','默认',1,10,0,'2026-04-11 01:25:09','2026-10-15 05:18:53'),(18,27,'大疆-Action Action 4','new',19,'默认','默认',200,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(19,28,'佳能 EOS R6 Mark II','new',20,'默认','默认',99,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(20,29,'索尼 ZV-E1','new',21,'默认','默认',99,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(21,30,'大疆-Action ACTION 4','used',22,'默认','默认',0,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(22,31,'大疆-Action ACTION 6','new',23,'默认','默认',22,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(23,32,'大疆 Mavic 4 Pro','new',24,'默认','默认',78,10,0,'2026-04-11 01:25:09','2026-10-15 05:18:53'),(24,33,'索尼 Mavic 3 Pro','rental',26,'默认','默认',1,10,0,'2026-04-11 01:30:41','2026-10-15 05:18:53'),(25,34,'索尼 FE 24-70mm F2.8 GM II','rental',27,'默认','默认',66,10,0,'2026-04-11 01:32:44','2026-04-11 01:32:44'),(26,35,'索尼 A7M4','rental',28,'默认','默认',3,10,0,'2026-04-11 01:34:24','2026-04-11 01:34:24'),(27,36,'富士 X-T4','rental',29,'默认','默认',50,10,0,'2026-04-11 01:37:35','2026-04-11 01:37:35'),(28,37,'大疆 Mini 4K','rental',30,'默认','默认',88,10,0,'2026-04-11 01:40:28','2026-04-11 01:40:28'),(29,38,'佳能 EOS R6 Mark II','rental',31,'默认','默认',88,10,0,'2026-04-11 01:41:35','2026-04-11 01:41:35'),(30,39,'佳能 EF 50mm F1.2 L USM','rental',32,'默认','默认',5555,10,0,'2026-04-11 01:42:46','2026-04-11 01:42:46'),(31,40,'尼康 Z63','rental',33,'默认','默认',63,10,0,'2026-04-11 01:44:45','2026-04-11 01:44:45'),(32,41,'尼克尔 尼克尔 Z 24-70mm F4 S','rental',34,'默认','默认',11,10,0,'2026-04-11 01:47:17','2026-04-11 01:47:17'),(34,42,'大疆-Action ACTION 5 PRO','rental',35,'默认','默认',55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(35,43,'大疆-Action ACTION 5 PRO','rental',36,'默认','默认',55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(36,44,'大疆-Action ACTION 5 PRO','new',37,'默认','默认',55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(37,45,'大疆-Action Action 5 PRO','rental',38,'默认','默认',66,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(38,46,'大疆-Action ACTION 5 PRO','new',39,'默认','默认',55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(39,47,'尼康 ZR','new',40,'默认','默认',22,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36');
/*!40000 ALTER TABLE `inventory` ENABLE KEYS */;

--
-- Table structure for table `inventory_history`
--

DROP TABLE IF EXISTS `inventory_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_history` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '历史记录ID',
  `inventory_id` bigint NOT NULL COMMENT '库存ID',
  `change_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变更时间',
  `change_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '变更类型(增加, 减少, 直接设置)',
  `before_stock` int NOT NULL COMMENT '变更前库存',
  `after_stock` int NOT NULL COMMENT '变更后库存',
  `change_quantity` int NOT NULL COMMENT '变更数量',
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '变更原因',
  `operator` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作人',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_inventory_id` (`inventory_id`) USING BTREE,
  KEY `idx_change_time` (`change_time`) USING BTREE,
  KEY `idx_change_type` (`change_type`) USING BTREE,
  KEY `idx_operator` (`operator`) USING BTREE,
  CONSTRAINT `fk_inventory_history_inventory` FOREIGN KEY (`inventory_id`) REFERENCES `inventory` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='库存历史记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_history`
--

/*!40000 ALTER TABLE `inventory_history` DISABLE KEYS */;
INSERT INTO `inventory_history` VALUES (1,7,'2026-01-02 20:05:55','减少',20,0,-20,'自动记录库存变更','系统'),(2,7,'2026-01-02 20:06:15','增加',0,21,21,'自动记录库存变更','系统'),(3,3,'2026-01-02 20:06:18','减少',99,0,-99,'自动记录库存变更','系统'),(4,1,'2026-01-02 20:20:56','增加',72,77,5,'自动记录库存变更','系统'),(5,1,'2026-01-02 20:20:56','增加',72,77,5,'','管理员'),(6,1,'2026-01-02 20:23:50','减少',77,72,-5,'自动记录库存变更','系统'),(15,1,'2026-01-02 20:42:15','增加',72,77,5,'自动记录库存变更','系统'),(16,1,'2026-01-02 20:42:16','增加',72,77,5,'','管理员'),(17,1,'2026-01-02 20:42:41','减少',77,72,-5,'自动记录库存变更','系统'),(18,1,'2026-01-02 20:43:43','增加',72,77,5,'自动记录库存变更','系统'),(20,1,'2026-01-02 20:47:08','减少',77,72,-5,'自动记录库存变更','系统'),(22,1,'2026-01-02 20:53:43','增加',72,77,5,'','管理员'),(23,2,'2026-01-08 22:19:49','直接设置',87,9,-78,'','管理员'),(24,2,'2026-01-08 22:20:48','增加',9,109,100,'','管理员'),(25,6,'2026-01-08 22:21:56','减少',6,4,2,'','管理员'),(26,5,'2026-01-11 16:25:18','直接设置',55,9,-46,'','管理员'),(27,4,'2026-01-11 16:25:49','直接设置',4,666,662,'','管理员'),(28,4,'2026-01-11 16:25:57','直接设置',666,4,-662,'','管理员'),(29,7,'2026-01-11 16:26:30','直接设置',20,11,-9,'','管理员'),(30,6,'2026-01-11 16:26:58','直接设置',44,4,-40,'','管理员'),(31,6,'2026-03-17 21:20:30','增加',4,9,5,'','管理员'),(32,6,'2026-03-17 21:21:49','增加',9,10,1,'','管理员'),(33,1,'2026-04-08 21:01:19','增加',77,82,5,'','管理员'),(34,6,'2026-04-11 08:49:20','增加',10,90,80,'','管理员'),(35,1,'2026-10-15 04:11:48','增加',82,83,1,'进货','管理员'),(36,1,'2026-10-15 04:11:55','减少',83,82,1,'盘点修正','管理员');
/*!40000 ALTER TABLE `inventory_history` ENABLE KEYS */;

--
-- Table structure for table `order_item`
--

DROP TABLE IF EXISTS `order_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_item` (
  `item_id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单项唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联order.order_id，订单删除时同步删除订单项',
  `product_id` bigint NOT NULL COMMENT '关联product.product_id，商品下架不影响已生成订单项',
  `quantity` int NOT NULL DEFAULT '1' COMMENT '商品数量（购买 / 二手场景）或租赁数量（租赁场景）',
  `unit_price` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '商品单价（下单时的价格，不受后续商品调价影响）',
  `deposit` decimal(12,2) DEFAULT '0.00' COMMENT '租赁押金（仅租赁场景用，按器材价值 50%-80% 计算，会员享减免）',
  `freight` decimal(10,2) DEFAULT '0.00' COMMENT '运费（购买 / 二手场景，租赁场景可为 0，自提）	',
  `item_status` tinyint NOT NULL DEFAULT '0' COMMENT '订单项状态：0 - 待履约，1 - 已发货 / 已出租，2 - 已完成，3 - 售后中',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '订单项创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '订单项状态更新时间',
  `lease_term` int DEFAULT NULL COMMENT '租赁天数',
  PRIMARY KEY (`item_id`) USING BTREE,
  KEY `order_id` (`order_id`,`product_id`,`item_status`) USING BTREE,
  KEY `product_id` (`product_id`) USING BTREE,
  CONSTRAINT `order_item_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `order_item_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储订单中的商品明细（如多件商品合并下单），与order一对多关联，支持分商品履约。\r\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_item`
--

/*!40000 ALTER TABLE `order_item` DISABLE KEYS */;
INSERT INTO `order_item` VALUES (60,54,1,1,9200.00,0.00,0.00,3,'2026-01-22 23:24:26','2026-01-23 00:36:49',NULL),(61,55,1,1,9200.00,0.00,0.00,3,'2026-01-23 00:32:45','2026-04-07 16:46:03',NULL),(62,56,1,1,9200.00,0.00,0.00,3,'2026-02-08 00:42:57','2026-03-07 21:41:48',NULL),(63,57,1,1,9200.00,0.00,0.00,4,'2026-02-08 17:38:18','2026-02-08 17:38:30',NULL),(64,58,6,1,120.09,1399.90,0.00,3,'2026-02-09 20:13:50','2026-10-15 06:00:00',NULL),(65,59,2,1,7999.00,0.00,0.00,3,'2026-02-09 20:26:18','2026-02-09 20:38:11',NULL),(66,60,5,1,5555.00,0.00,0.00,1,'2026-02-09 20:40:42','2026-02-09 20:40:44',NULL),(67,61,1,1,9200.00,0.00,0.00,1,'2026-02-26 22:19:51','2026-02-26 22:19:58',NULL),(68,62,6,5,120.09,1399.90,0.00,1,'2026-03-17 21:11:37','2026-03-17 21:11:50',NULL),(69,63,7,1,100.00,1499.90,0.00,1,'2026-03-17 21:17:50','2026-03-17 21:17:53',NULL),(70,64,7,1,100.00,1499.90,0.00,1,'2026-03-17 21:18:20','2026-03-17 21:18:23',NULL),(71,65,1,1,9200.00,0.00,0.00,3,'2026-03-17 21:35:49','2026-03-17 21:37:03',NULL),(72,66,1,1,9200.00,0.00,0.00,4,'2026-03-17 21:39:39','2026-04-07 15:21:00',NULL),(74,68,1,2,9200.00,0.00,0.00,5,'2026-04-07 17:52:48','2026-04-07 17:53:29',NULL),(75,69,25,5,3299.00,0.00,0.00,5,'2026-04-07 17:54:45','2026-04-07 17:55:18',NULL),(76,70,21,1,14999.00,0.00,0.00,5,'2026-04-07 17:56:37','2026-04-07 17:56:48',NULL),(77,71,24,100,14449.00,0.00,0.00,5,'2026-04-07 17:57:24','2026-04-07 17:57:33',NULL),(78,72,1,199,9200.00,0.00,0.00,5,'2026-04-07 17:57:50','2026-04-07 17:58:16',NULL),(79,73,30,1,999.00,0.00,0.00,3,'2026-04-11 00:18:03','2026-04-11 00:18:43',NULL),(80,74,7,1,100.00,1499.90,0.00,3,'2026-04-11 00:21:04','2026-04-11 00:23:02',NULL),(81,75,32,1,18999.00,0.00,0.00,4,'2026-04-11 00:24:11','2026-04-11 00:24:32',NULL),(82,76,32,3,18999.00,0.00,0.00,3,'2026-04-11 00:24:39','2026-04-11 00:25:13',NULL),(83,77,6,1,120.09,1399.90,0.00,5,'2026-04-11 00:50:07','2026-04-11 00:50:20',NULL),(84,78,6,1,120.09,1399.90,0.00,3,'2026-04-11 00:50:30','2026-04-11 00:51:30',NULL),(85,79,6,1,120.09,1399.90,0.00,5,'2026-04-11 00:55:21','2026-04-11 00:56:10',NULL),(86,80,7,1,100.00,1499.90,0.00,3,'2026-04-11 01:01:15','2026-04-11 01:02:25',NULL),(87,81,6,1,120.09,1399.90,0.00,3,'2026-04-11 01:03:01','2026-10-15 06:00:00',NULL),(88,82,6,2,120.09,1399.90,0.00,1,'2026-04-11 08:35:24','2026-04-11 08:35:41',NULL),(89,83,2,2,7999.00,0.00,0.00,3,'2026-04-11 09:12:12','2026-10-15 06:00:00',NULL),(90,84,6,4,120.09,1399.90,0.00,3,'2026-04-11 12:28:30','2026-04-11 12:29:27',NULL),(91,85,6,1,120.09,1399.90,0.00,3,'2026-04-11 12:31:38','2026-04-11 12:32:27',NULL),(92,86,6,1,120.09,1399.90,0.00,3,'2026-04-11 14:57:19','2026-04-11 14:58:22',NULL),(93,87,32,2,18999.00,0.00,0.00,3,'2026-10-15 03:48:19','2026-10-15 03:48:27',NULL),(94,88,33,1,109.00,2999.90,0.00,5,'2026-10-15 03:48:35','2026-10-15 03:48:40',NULL),(95,89,32,1,18999.00,0.00,0.00,5,'2026-10-15 03:50:58','2026-10-15 03:50:59',NULL),(96,90,32,1,18999.00,0.00,0.00,1,'2026-10-15 03:59:03','2026-10-15 03:59:06',NULL),(97,91,1,2,9200.00,0.00,0.00,4,'2026-10-15 05:25:26','2026-10-15 05:31:00',NULL),(98,92,1,3,9200.00,0.00,0.00,4,'2026-10-15 05:25:28','2026-10-15 05:31:00',NULL),(99,93,1,5,9200.00,0.00,0.00,3,'2026-10-15 05:27:06','2026-10-15 05:27:07',NULL),(100,94,1,1,9200.00,0.00,0.00,5,'2026-10-15 05:27:08','2026-10-15 05:27:08',NULL),(101,95,1,2,9200.00,0.00,0.00,3,'2026-10-15 05:27:17','2026-10-15 05:27:17',NULL),(102,96,1,1,9200.00,0.00,0.00,5,'2026-10-15 05:27:18','2026-10-15 05:27:19',NULL),(103,97,1,2,9200.00,0.00,0.00,3,'2026-10-15 05:27:30','2026-10-15 05:27:30',NULL),(104,98,1,1,9200.00,0.00,0.00,5,'2026-10-15 05:27:31','2026-10-15 05:27:31',NULL),(105,99,1,2,9200.00,0.00,0.00,3,'2026-10-15 05:29:41','2026-10-15 05:29:42',NULL),(106,100,1,1,9200.00,0.00,0.00,5,'2026-10-15 05:29:42','2026-10-15 05:29:43',NULL),(107,101,1,2,9200.00,0.00,0.00,3,'2026-10-15 05:31:43','2026-10-15 05:31:43',NULL),(108,102,1,1,9200.00,0.00,0.00,5,'2026-10-15 05:31:44','2026-10-15 05:31:44',NULL),(109,103,1,2,9200.00,0.00,0.00,3,'2026-10-15 05:35:10','2026-10-15 05:35:10',NULL),(110,104,1,1,9200.00,0.00,0.00,5,'2026-10-15 05:35:11','2026-10-15 05:35:11',NULL),(111,105,1,1,9200.00,0.00,0.00,1,'2026-10-15 06:08:37','2026-10-15 06:08:47',NULL);
/*!40000 ALTER TABLE `order_item` ENABLE KEYS */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `order_id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单唯一标识',
  `order_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '订单编号',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `seller_id` bigint NOT NULL COMMENT '商家ID，关联user.user_id',
  `total_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '订单总金额',
  `shipping_fee` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '运费',
  `pay_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `order_status` tinyint NOT NULL DEFAULT '0' COMMENT '订单状态：0-待支付，1-已支付，2-已发货，3-已完成，4-已取消',
  `payment_method` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '支付方式',
  `address_id` bigint DEFAULT NULL COMMENT '收货地址ID',
  `recipient` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '收件人',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '联系电话',
  `province` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '省份',
  `city` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '城市',
  `district` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '区/县',
  `detail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '详细地址',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `pay_time` datetime DEFAULT NULL COMMENT '支付时间',
  `transaction_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '支付流水号',
  PRIMARY KEY (`order_id`) USING BTREE,
  UNIQUE KEY `order_no` (`order_no`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `orders_ibfk_2` (`address_id`) USING BTREE,
  KEY `orders_ibfk_3` (`seller_id`) USING BTREE,
  KEY `idx_orders_user_time` (`user_id`,`create_time`),
  KEY `idx_orders_seller_time` (`seller_id`,`create_time`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `user_address` (`address_id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`seller_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=106 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (54,'ORD2601222324263185720001',7,8,9200.00,0.00,9200.00,3,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-01-22 23:24:26','2026-10-15 03:42:34','2026-01-22 23:27:26','TXN20260122232726_54'),(55,'ORD2601230032452411440001',7,8,9200.00,0.00,9200.00,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-01-23 00:32:45','2026-10-15 03:42:34','2026-01-23 00:35:45','TXN20260123003545_55'),(56,'ORD2602080042573563520001',7,8,9200.00,0.00,9200.00,3,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-02-08 00:42:57','2026-10-15 03:42:34','2026-02-08 00:45:57','TXN20260208004557_56'),(57,'ORD2602081738176351120001',7,8,9200.00,0.00,9200.00,4,'online',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-02-08 17:38:18','2026-02-08 17:38:30',NULL,NULL),(58,'ORD2602092013502041560001',11,8,2240.53,0.00,2240.53,3,'wechat',18,'111','18344551994','11','1101','110101','111','2026-02-09 20:13:50','2026-10-15 06:00:00','2026-02-09 20:16:50','TXN20260209201650_58'),(59,'ORD2602092026175626320001',11,8,7999.00,0.00,7999.00,3,'wechat',18,'111','18344551994','11','1101','110101','111','2026-02-09 20:26:18','2026-02-09 20:38:11','2026-02-09 20:26:20','TXN1770639980194_59'),(60,'ORD2602092040416936320002',11,8,5555.00,0.00,5555.00,1,'wechat',18,'111','18344551994','11','1101','110101','111','2026-02-09 20:40:42','2026-02-09 20:40:44','2026-02-09 20:40:44','TXN1770640843753_60'),(61,'ORD2602262219506819920001',7,8,9200.00,0.00,9200.00,1,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-02-26 22:19:51','2026-02-26 22:19:58','2026-02-26 22:19:58','TXN1772115597653_61'),(62,'ORD2603172111368371280001',7,8,11202.65,0.00,11202.65,1,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-03-17 21:11:37','2026-03-17 21:11:50','2026-03-17 21:11:50','TXN1773753109564_62'),(63,'ORD2603172117502881280002',7,8,1799.90,0.00,1799.90,1,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-03-17 21:17:50','2026-03-17 21:17:53','2026-03-17 21:17:53','TXN1773753472965_63'),(64,'ORD2603172118201101280003',7,8,1799.90,0.00,1799.90,1,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-03-17 21:18:20','2026-03-17 21:18:23','2026-03-17 21:18:23','TXN1773753503085_64'),(65,'ORD2603172135491762320001',7,8,9200.00,0.00,9200.00,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-03-17 21:35:49','2026-03-17 21:37:03','2026-03-17 21:36:04','TXN1773754563779_65'),(66,'ORD2603172139389312320002',7,8,9200.00,0.00,9200.00,4,'online',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-03-17 21:39:39','2026-04-07 15:21:00',NULL,NULL),(68,'ORD2604071752477505240001',7,8,18400.00,0.00,18400.00,7,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-07 17:52:48','2026-04-07 17:53:29','2026-04-07 17:52:53','TXN1775555572645_68'),(69,'ORD2604071754446915240002',7,8,16495.00,0.00,16495.00,6,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-07 17:54:45','2026-04-07 17:55:18','2026-04-07 17:54:47','TXN1775555687281_69'),(70,'ORD2604071756373235240003',7,8,14999.00,0.00,14999.00,5,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-07 17:56:37','2026-04-07 17:56:48','2026-04-07 17:56:42','TXN1775555801538_70'),(71,'ORD2604071757238925240004',7,19,1444900.00,0.00,1444900.00,5,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-07 17:57:24','2026-04-07 17:57:33','2026-04-07 17:57:28','TXN1775555847986_71'),(72,'ORD2604071757498845240005',7,8,1830800.00,0.00,1830800.00,7,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-07 17:57:50','2026-04-07 17:58:16','2026-04-07 17:57:53','TXN1775555872849_72'),(73,'ORD2604110018032950760001',7,8,999.00,0.00,999.00,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:18:03','2026-04-11 00:18:43','2026-04-11 00:18:08','TXN1775837887692_73'),(74,'ORD2604110021040350760002',7,8,3699.90,0.00,3699.90,3,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:21:04','2026-04-11 00:23:02','2026-04-11 00:21:10','TXN1775838069529_74'),(75,'ORD2604110024111560760003',7,8,18999.00,0.00,18999.00,4,'online',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:24:11','2026-04-11 00:24:32',NULL,NULL),(76,'ORD2604110024391070760004',7,8,56997.00,0.00,56997.00,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:24:39','2026-04-11 00:25:13','2026-04-11 00:24:45','TXN1775838284667_76'),(77,'ORD2604110050071717440001',7,8,4402.15,0.00,4402.15,5,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:50:07','2026-04-11 00:50:20','2026-04-11 00:50:11','TXN1775839811170_77'),(78,'ORD2604110050303197440002',7,8,4642.33,0.00,4642.33,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:50:30','2026-04-11 00:51:30','2026-04-11 00:50:34','TXN1775839833517_78'),(79,'ORD2604110055214447440003',7,8,5362.87,0.00,5362.87,9,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 00:55:21','2026-04-11 00:56:10','2026-04-11 00:55:27','TXN1775840126564_79'),(80,'ORD2604110101153077440004',7,8,2499.90,0.00,2499.90,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 01:01:15','2026-04-11 01:02:25','2026-04-11 01:01:21','TXN1775840480670_80'),(81,'ORD2604110103012297440005',7,8,5362.87,0.00,5362.87,3,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 01:03:01','2026-10-15 06:00:00','2026-04-11 01:03:07','TXN1775840586757_81'),(82,'ORD2604110835244642080001',7,8,9044.48,0.00,9044.48,1,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 08:35:24','2026-04-11 08:35:41','2026-04-11 08:35:41','TXN1775867740968_82'),(83,'ORD2604110912117402400001',7,8,15998.00,0.00,15998.00,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 09:12:12','2026-10-15 06:00:00','2026-04-11 09:12:15','TXN1775869935063_83'),(84,'ORD2604111228302622400002',7,8,17608.60,0.00,17608.60,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 12:28:30','2026-04-11 12:29:27','2026-04-11 12:28:36','TXN1775881715742_84'),(85,'ORD2604111231382552400003',7,8,4402.15,0.00,4402.15,3,'alipay',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 12:31:38','2026-04-11 12:32:27','2026-04-11 12:31:43','TXN1775881903485_85'),(86,'ORD2604111457191642400004',7,8,5122.69,0.00,5122.69,3,'wechat',17,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院','2026-04-11 14:57:19','2026-04-11 14:58:22','2026-04-11 14:57:25','TXN1775890644805_86'),(87,'ORD2610150348188528360001',23,8,37998.00,0.00,37998.00,3,'wechat',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 03:48:19','2026-10-15 03:48:27','2026-10-15 03:48:27','TXN1792007306548_87'),(88,'ORD2610150348346578360002',23,8,3653.90,0.00,3653.90,9,'wechat',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 03:48:35','2026-10-15 03:48:40','2026-10-15 03:48:40','TXN1792007320095_88'),(89,'ORD2610150350583478360003',23,8,18999.00,0.00,18999.00,5,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 03:50:58','2026-10-15 03:50:59','2026-10-15 03:50:58','TXN1792007458410_89'),(90,'ORD2610150359025928360004',23,8,18999.00,0.00,18999.00,1,'wechat',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 03:59:03','2026-10-15 03:59:06','2026-10-15 03:59:06','TXN1792007946163_90'),(91,'ORD2610150525264389360001',23,8,18400.00,0.00,18400.00,4,'online',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:25:26','2026-10-15 05:31:00',NULL,NULL),(92,'ORD2610150525276799360002',23,8,27600.00,0.00,27600.00,4,'online',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:25:28','2026-10-15 05:31:00',NULL,NULL),(93,'ORD2610150527064649480001',23,8,46000.00,0.00,46000.00,3,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:27:06','2026-10-15 05:27:07','2026-10-15 05:27:07','TXN1792013226531_93'),(94,'ORD2610150527079979480002',23,8,9200.00,0.00,9200.00,6,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:27:08','2026-10-15 05:27:08','2026-10-15 05:27:08','TXN1792013228032_94'),(95,'ORD2610150527172519480003',23,8,18400.00,0.00,18400.00,3,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:27:17','2026-10-15 05:27:17','2026-10-15 05:27:17','TXN1792013237281_95'),(96,'ORD2610150527181079480004',23,8,9200.00,0.00,9200.00,6,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:27:18','2026-10-15 05:27:19','2026-10-15 05:27:18','TXN1792013238140_96'),(97,'ORD2610150527297759480005',23,8,18400.00,0.00,18400.00,3,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:27:30','2026-10-15 05:27:30','2026-10-15 05:27:30','TXN1792013249801_97'),(98,'ORD2610150527306499480006',23,8,9200.00,0.00,9200.00,6,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:27:31','2026-10-15 05:27:31','2026-10-15 05:27:31','TXN1792013250677_98'),(99,'ORD2610150529414579480007',23,8,18400.00,0.00,18400.00,3,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:29:41','2026-10-15 05:29:42','2026-10-15 05:29:41','TXN1792013381486_99'),(100,'ORD2610150529422509480008',23,8,9200.00,0.00,9200.00,6,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:29:42','2026-10-15 05:29:43','2026-10-15 05:29:42','TXN1792013382276_100'),(101,'ORD2610150531432279480009',23,8,18400.00,0.00,18400.00,3,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:31:43','2026-10-15 05:31:43','2026-10-15 05:31:43','TXN1792013503255_101'),(102,'ORD2610150531439539480010',23,8,9200.00,0.00,9200.00,6,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:31:44','2026-10-15 05:31:44','2026-10-15 05:31:44','TXN1792013503986_102'),(103,'ORD2610150535096000080001',23,8,18400.00,0.00,18400.00,3,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:35:10','2026-10-15 05:35:10','2026-10-15 05:35:10','TXN1792013709650_103'),(104,'ORD2610150535105080080002',23,8,9200.00,0.00,9200.00,6,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 05:35:11','2026-10-15 05:35:11','2026-10-15 05:35:11','TXN1792013710532_104'),(105,'ORD2610150608368821880001',23,8,9200.00,0.00,9200.00,1,'alipay',20,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号','2026-10-15 06:08:37','2026-10-15 06:08:47','2026-10-15 06:08:47','TXN1792015726889_105');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment` (
  `payment_id` bigint NOT NULL AUTO_INCREMENT COMMENT '支付记录ID',
  `order_id` bigint NOT NULL COMMENT '订单ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `amount` decimal(12,2) NOT NULL COMMENT '支付金额',
  `payment_method` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '支付方式',
  `transaction_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '第三方交易流水号',
  `pay_time` datetime DEFAULT NULL COMMENT '支付完成时间',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '0 待支付 / 1 已支付 / 2 已退款 / 3 支付失败',
  `qr_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '支付二维码',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  PRIMARY KEY (`payment_id`) USING BTREE,
  KEY `order_id` (`order_id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `idx_order_status` (`order_id`,`status`),
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment`
--

/*!40000 ALTER TABLE `payment` DISABLE KEYS */;
INSERT INTO `payment` VALUES (1,54,7,9200.00,'alipay','TXN20260122232726_54','2026-01-22 23:27:26',1,NULL,'2026-01-22 23:24:26','2026-10-15 03:42:34'),(2,55,7,9200.00,'wechat','TXN20260123003545_55','2026-01-23 00:35:45',1,NULL,'2026-01-23 00:32:45','2026-10-15 03:42:34'),(3,56,7,9200.00,'alipay','TXN20260208004557_56','2026-02-08 00:45:57',1,NULL,'2026-02-08 00:42:57','2026-10-15 03:42:34'),(4,58,11,2240.53,'wechat','TXN20260209201650_58','2026-02-09 20:16:50',1,NULL,'2026-02-09 20:13:50','2026-10-15 03:42:34'),(5,59,11,7999.00,'wechat','TXN1770639980194_59','2026-02-09 20:26:20',1,NULL,'2026-02-09 20:26:18','2026-02-09 20:38:11'),(6,60,11,5555.00,'wechat','TXN1770640843753_60','2026-02-09 20:40:44',1,NULL,'2026-02-09 20:40:42','2026-02-09 20:40:44'),(7,61,7,9200.00,'wechat','TXN1772115597653_61','2026-02-26 22:19:58',1,NULL,'2026-02-26 22:19:51','2026-02-26 22:19:58'),(8,62,7,11202.65,'wechat','TXN1773753109564_62','2026-03-17 21:11:50',1,NULL,'2026-03-17 21:11:37','2026-03-17 21:11:50'),(9,63,7,1799.90,'wechat','TXN1773753472965_63','2026-03-17 21:17:53',1,NULL,'2026-03-17 21:17:50','2026-03-17 21:17:53'),(10,64,7,1799.90,'wechat','TXN1773753503085_64','2026-03-17 21:18:23',1,NULL,'2026-03-17 21:18:20','2026-03-17 21:18:23'),(11,65,7,9200.00,'wechat','TXN1773754563779_65','2026-03-17 21:36:04',1,NULL,'2026-03-17 21:35:49','2026-03-17 21:37:03'),(12,69,7,16495.00,'wechat','TXN1775555687281_69','2026-04-07 17:54:47',2,NULL,'2026-04-07 17:54:45','2026-04-07 17:55:18'),(13,70,7,14999.00,'wechat','TXN1775555801538_70','2026-04-07 17:56:42',1,NULL,'2026-04-07 17:56:37','2026-04-07 17:56:48'),(14,71,7,1444900.00,'alipay','TXN1775555847986_71','2026-04-07 17:57:28',1,NULL,'2026-04-07 17:57:24','2026-04-07 17:57:33'),(15,73,7,999.00,'wechat','TXN1775837887692_73','2026-04-11 00:18:08',1,NULL,'2026-04-11 00:18:03','2026-04-11 00:18:43'),(16,74,7,3699.90,'alipay','TXN1775838069529_74','2026-04-11 00:21:10',1,NULL,'2026-04-11 00:21:04','2026-04-11 00:23:02'),(17,76,7,56997.00,'wechat','TXN1775838284667_76','2026-04-11 00:24:45',1,NULL,'2026-04-11 00:24:39','2026-04-11 00:25:13'),(18,77,7,4402.15,'wechat','TXN1775839811170_77','2026-04-11 00:50:11',1,NULL,'2026-04-11 00:50:07','2026-04-11 00:50:20'),(19,78,7,4642.33,'wechat','TXN1775839833517_78','2026-04-11 00:50:34',1,NULL,'2026-04-11 00:50:30','2026-04-11 00:51:30'),(20,79,7,5362.87,'alipay','TXN1775840126564_79','2026-04-11 00:55:27',1,NULL,'2026-04-11 00:55:21','2026-04-11 00:56:10'),(21,80,7,2499.90,'wechat','TXN1775840480670_80','2026-04-11 01:01:21',1,NULL,'2026-04-11 01:01:15','2026-04-11 01:02:25'),(22,81,7,5362.87,'alipay','TXN1775840586757_81','2026-04-11 01:03:07',1,NULL,'2026-04-11 01:03:01','2026-04-11 01:03:30'),(23,82,7,9044.48,'wechat','TXN1775867740968_82','2026-04-11 08:35:41',1,NULL,'2026-04-11 08:35:24','2026-04-11 08:35:41'),(24,83,7,15998.00,'wechat','TXN1775869935063_83','2026-04-11 09:12:15',1,NULL,'2026-04-11 09:12:12','2026-04-11 09:12:29'),(25,84,7,17608.60,'wechat','TXN1775881715742_84','2026-04-11 12:28:36',1,NULL,'2026-04-11 12:28:30','2026-04-11 12:29:27'),(26,85,7,4402.15,'alipay','TXN1775881903485_85','2026-04-11 12:31:43',1,NULL,'2026-04-11 12:31:38','2026-04-11 12:32:27'),(27,86,7,5122.69,'wechat','TXN1775890644805_86','2026-04-11 14:57:25',1,NULL,'2026-04-11 14:57:19','2026-04-11 14:58:22');
/*!40000 ALTER TABLE `payment` ENABLE KEYS */;

--
-- Table structure for table `permission`
--

DROP TABLE IF EXISTS `permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permission` (
  `permission_id` int NOT NULL AUTO_INCREMENT COMMENT '权限唯一标识',
  `permission_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '权限名称（如 “商品审核”“订单删除”“数据统计查看”）',
  `permission_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '权限编码（如 “PRODUCT_AUDIT”“ORDER_DELETE”“STAT_VIEW”）',
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '权限对应的后端接口 URL（如 “/admin/product/audit”“/admin/order/delete”）',
  `method` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '接口请求方式（如 “GET”“POST”“PUT”“DELETE”）',
  `parent_id` int DEFAULT NULL COMMENT '外键,父权限 ID（用于权限层级，如 “商品管理” 是 “商品审核” 的父权限，NULL 表示顶级权限）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '权限创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '权限信息更新时间',
  PRIMARY KEY (`permission_id`) USING BTREE,
  UNIQUE KEY `permission_name` (`permission_name`,`permission_code`) USING BTREE,
  KEY `parent_id` (`parent_id`) USING BTREE,
  CONSTRAINT `permission_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `permission` (`permission_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=261 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储系统功能权限（如商品审核、订单查看、数据统计），与role通过中间表关联。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permission`
--

/*!40000 ALTER TABLE `permission` DISABLE KEYS */;
INSERT INTO `permission` VALUES (42,'系统权限','SYSTEM_ROOT','/','*',NULL,'2026-01-04 22:22:51','2026-01-04 22:22:51'),(89,'系统管理','SYSTEM_MANAGE','/super-admin/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(90,'管理员管理','ADMIN_MANAGE','/super-admin/admins/**','*',89,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(91,'权限管理','PERMISSION_MANAGE','/super-admin/permissions/**','*',89,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(92,'角色管理','ROLE_MANAGE','/super-admin/roles/**','*',89,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(93,'系统配置','SYSTEM_CONFIG','/super-admin/config/**','*',89,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(94,'操作日志','SYSTEM_LOG','/super-admin/logs/**','*',89,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(95,'用户管理','USER_MANAGE','/admin/users/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(96,'用户查看','USER_VIEW','/admin/users','GET',95,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(97,'用户详情','USER_DETAIL','/admin/users/{userId}','GET',95,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(98,'用户状态更新','USER_STATUS_UPDATE','/admin/users/{userId}/status','PUT',95,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(99,'用户信息更新','USER_INFO_UPDATE','/admin/users/{userId}','PUT',95,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(100,'用户删除','USER_DELETE','/admin/users/{userId}','DELETE',95,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(101,'商家管理','MERCHANT_MANAGE','/admin/merchants/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(102,'商家列表查看','MERCHANT_LIST_VIEW','/admin/merchants','GET',101,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(103,'商家审核列表','MERCHANT_AUDIT_LIST','/admin/merchants/audit','GET',101,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(104,'商家详情','MERCHANT_DETAIL','/admin/merchants/{merchantId}','GET',101,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(105,'商家审核','MERCHANT_AUDIT','/admin/merchants/{merchantId}/audit','PUT',101,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(106,'商家状态更新','MERCHANT_STATUS_UPDATE','/admin/merchants/{merchantId}/status','PUT',101,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(107,'商家禁用','MERCHANT_DISABLE','/admin/merchants/{merchantId}/disable','PUT',101,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(108,'商品管理','PRODUCT_MANAGE','/admin/products/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(109,'商品列表查看','PRODUCT_LIST_VIEW','/admin/products','GET',108,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(110,'商品审核列表','PRODUCT_AUDIT_LIST','/admin/products/audit','GET',108,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(111,'商品详情','PRODUCT_DETAIL','/admin/products/{productId}','GET',108,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(112,'商品审核','PRODUCT_AUDIT','/admin/products/{productId}/audit','PUT',108,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(113,'商品上架/下架','PRODUCT_SHELF','/admin/products/{productId}/shelf','PUT',108,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(114,'商品删除','PRODUCT_DELETE','/admin/products/{productId}','DELETE',108,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(115,'分类管理','CATEGORY_MANAGE','/admin/categories/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(116,'分类树查看','CATEGORY_TREE_VIEW','/admin/categories/tree','GET',115,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(117,'分类添加','CATEGORY_ADD','/admin/categories','POST',115,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(118,'分类更新','CATEGORY_UPDATE','/admin/categories/{categoryId}','PUT',115,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(119,'分类删除','CATEGORY_DELETE','/admin/categories/{categoryId}','DELETE',115,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(120,'公告管理','NOTICE_MANAGE','/admin/notices/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(121,'公告列表查看','NOTICE_LIST_VIEW','/admin/notices','GET',120,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(122,'公告详情','NOTICE_DETAIL','/admin/notices/{noticeId}','GET',120,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(123,'公告添加','NOTICE_ADD','/admin/notices','POST',120,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(124,'公告更新','NOTICE_UPDATE','/admin/notices/{noticeId}','PUT',120,'2026-03-08 01:07:05','2026-03-08 02:36:22'),(125,'公告删除','NOTICE_DELETE','/admin/notices/{noticeId}','DELETE',120,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(126,'公告发布','NOTICE_PUBLISH','/admin/notices/{noticeId}/publish','PUT',120,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(127,'数据统计','STATISTICS_MANAGE','/admin/statistics/**','*',42,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(128,'仪表盘数据','DASHBOARD_VIEW','/admin/dashboard','GET',127,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(129,'超级管理员仪表盘','SUPER_ADMIN_DASHBOARD','/admin/super-admin/dashboard','GET',127,'2026-03-08 01:07:05','2026-03-08 01:07:05'),(131,'品牌管理','BRAND_MANAGE','/admin/brands/**','*',42,'2026-10-15 04:39:37','2026-10-15 04:39:37'),(132,'操作日志','OPERATION_LOG','/admin/operations','GET',42,'2026-10-15 04:39:37','2026-10-15 04:39:37'),(133,'查看个人资料','USER_PROFILE_GET','/user/profile','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(134,'修改个人资料','USER_PROFILE_UPDATE','/user/profile','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(135,'修改登录密码','USER_PASSWORD_UPDATE','/user/password','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(136,'上传头像','USER_AVATAR_UPLOAD','/user/avatar','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(137,'查看收货地址','USER_ADDRESS_LIST','/user/addresses','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(138,'新增收货地址','USER_ADDRESS_ADD','/user/addresses','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(139,'修改收货地址','USER_ADDRESS_UPDATE','/user/addresses','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(140,'删除收货地址','USER_ADDRESS_DELETE','/user/addresses/{addressId}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(141,'设为默认地址','USER_ADDRESS_DEFAULT','/user/addresses/{addressId}/default','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(142,'查看购物车','CART_LIST','/cart/items','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(143,'加入购物车','CART_ADD','/cart/add','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(144,'修改购物车数量','CART_UPDATE','/cart/items/{cartItemId}','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(145,'删除购物车项','CART_DELETE','/cart/items/{cartItemId}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(146,'清空购物车','CART_CLEAR','/cart/clear','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(147,'批量加入购物车','CART_BATCH_ADD','/cart/batch-add','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(148,'批量删除购物车项','CART_BATCH_DELETE','/cart/batch-delete','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(149,'查看收藏','FAVORITE_LIST','/favorites','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(150,'添加收藏','FAVORITE_ADD','/favorites','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(151,'取消收藏（按商品）','FAVORITE_REMOVE','/favorites','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(152,'取消收藏（按收藏ID）','FAVORITE_REMOVE_BY_ID','/favorites/{favoriteId}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(153,'批量取消收藏','FAVORITE_BATCH_DELETE','/favorites/batch-delete','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(154,'检查收藏状态','FAVORITE_CHECK','/favorites/check','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(155,'查看我的订单','ORDER_LIST','/orders/list','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(156,'查看订单详情','ORDER_DETAIL','/orders/{orderId}','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(157,'按订单号查详情','ORDER_DETAIL_BY_NO','/orders/by-order-no/{orderNo}','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(158,'购物车下单','ORDER_CREATE_FROM_CART','/orders/create-from-cart','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(159,'立即购买下单','ORDER_TEMP','/orders/temp','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(160,'检查未支付订单','ORDER_CHECK_PENDING','/orders/check-pending','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(161,'支付订单','ORDER_PAY','/orders/pay/{orderId}','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(162,'取消订单','ORDER_CANCEL','/orders/{orderId}/cancel','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(163,'确认收货','ORDER_CONFIRM_RECEIVE','/orders/{orderId}/confirm-receive','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(164,'归还租赁器材','ORDER_RETURN','/orders/{orderId}/return','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(165,'申请退款','REFUND_APPLY','/refunds/apply','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(166,'查看订单退款','REFUND_BY_ORDER','/refunds/order/{orderId}','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(167,'判断能否退款','REFUND_CAN','/refunds/can-refund/{orderId}','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(168,'提交评价','EVAL_CREATE','/evaluations','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(169,'查看我的评价','EVAL_MINE','/evaluations/user','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(170,'删除评价','EVAL_DELETE','/evaluations/{evaluationId}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(171,'查看消息','MESSAGE_LIST','/message/list','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(172,'查看未读数','MESSAGE_UNREAD','/message/unread/count','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(173,'标记消息已读','MESSAGE_READ','/message/{id}/read','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(174,'全部标记已读','MESSAGE_READ_ALL','/message/all/read','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(175,'删除消息','MESSAGE_DELETE','/message/{id}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(176,'上传文件','FILE_UPLOAD','/files/upload','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(177,'浏览图库','FILE_PAGE','/files/page','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(178,'商品列表','MERCHANT_PRODUCT_LIST','/merchant/product/list','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(179,'发布商品','MERCHANT_PRODUCT_ADD','/merchant/product','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(180,'商品详情','MERCHANT_PRODUCT_DETAIL','/merchant/product/{productId}','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(181,'编辑商品','MERCHANT_PRODUCT_UPDATE','/merchant/product/{productId}','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(182,'删除商品','MERCHANT_PRODUCT_DELETE','/merchant/product/{productId}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(183,'上下架商品','MERCHANT_PRODUCT_STATUS','/merchant/product/{productId}/status','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(184,'查看商品图片','MERCHANT_PRODUCT_IMAGES','/merchant/product/{productId}/images','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(185,'查看SKU','MERCHANT_SKU_LIST','/merchant/product/{productId}/skus','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(186,'新增SKU','MERCHANT_SKU_ADD','/merchant/product/{productId}/skus','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(187,'编辑SKU','MERCHANT_SKU_UPDATE','/merchant/product/{productId}/skus/{skuId}','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(188,'删除SKU','MERCHANT_SKU_DELETE','/merchant/product/{productId}/skus/{skuId}','DELETE',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(189,'分类下拉','MERCHANT_META_CATEGORIES','/merchant/product/categories','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(190,'子类下拉','MERCHANT_META_SUB_CATEGORIES','/merchant/product/sub-categories','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(191,'品牌下拉','MERCHANT_META_BRANDS','/merchant/product/brands','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(192,'品牌树','MERCHANT_META_BRAND_TREE','/merchant/product/brand-tree','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(193,'绑定商品图片','MERCHANT_IMAGE_BIND','/image/bind/product','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(194,'库存列表','MERCHANT_INVENTORY_LIST','/merchant/inventory','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(195,'库存详情','MERCHANT_INVENTORY_DETAIL','/merchant/inventory/{inventoryId}','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(196,'调整库存','MERCHANT_INVENTORY_ADJUST','/merchant/inventory/adjust','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(197,'库存变更记录','MERCHANT_INVENTORY_HISTORY','/merchant/inventory/history','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(198,'设置安全库存','MERCHANT_INVENTORY_MIN_STOCK','/merchant/inventory/{inventoryId}/min-stock','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(199,'批量导入库存','MERCHANT_INVENTORY_IMPORT','/merchant/inventory/import','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(200,'查看店铺资料','MERCHANT_SHOP_INFO_GET','/merchant/shop/info','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(201,'修改店铺资料','MERCHANT_SHOP_INFO_UPDATE','/merchant/shop/info','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(202,'上传店铺logo','MERCHANT_SHOP_LOGO','/merchant/shop/upload-logo','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(203,'上传资质材料','MERCHANT_SHOP_AUTH_UPLOAD','/merchant/shop/upload-auth-material','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(204,'查看认证信息','MERCHANT_SHOP_AUTH_GET','/merchant/shop/auth-info','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(205,'提交认证信息','MERCHANT_SHOP_AUTH_POST','/merchant/shop/auth-info','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(206,'查看安全设置','MERCHANT_SHOP_SECURITY','/merchant/shop/security-info','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(207,'修改店铺密码','MERCHANT_SHOP_PWD','/merchant/shop/change-password','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(208,'设置支付密码','MERCHANT_SHOP_PAY_PWD_SET','/merchant/shop/set-pay-password','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(209,'修改支付密码','MERCHANT_SHOP_PAY_PWD_CHANGE','/merchant/shop/change-pay-password','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(210,'店铺看板','MERCHANT_SHOP_DASHBOARD','/merchant/shop/dashboard','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(211,'最近订单','MERCHANT_SHOP_RECENT_ORDERS','/merchant/shop/recent-orders','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(212,'成交趋势','MERCHANT_SHOP_CHART','/merchant/shop/chart-data','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(213,'经营日历','MERCHANT_SHOP_CALENDAR','/merchant/shop/calendar-data','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(214,'品类分布','MERCHANT_SHOP_DISTRIBUTION','/merchant/shop/product-distribution','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(215,'订单发货','MERCHANT_ORDER_SHIP','/orders/{orderId}/ship','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(216,'确认归还','MERCHANT_ORDER_CONFIRM_RETURN','/orders/{orderId}/confirm-return','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(217,'退款列表','MERCHANT_REFUND_LIST','/refunds/merchant/list','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(218,'处理退款','MERCHANT_REFUND_PROCESS','/refunds/process','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(219,'查看个人资料','ADMIN_SELF_PROFILE_GET','/user/profile','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(220,'修改个人资料','ADMIN_SELF_PROFILE_UPDATE','/user/profile','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(221,'修改登录密码','ADMIN_SELF_PASSWORD','/user/password','PUT',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(222,'上传头像','ADMIN_SELF_AVATAR','/user/avatar','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(223,'上传文件','ADMIN_FILE_UPLOAD','/files/upload','POST',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(224,'浏览图库','ADMIN_FILE_PAGE','/files/page','GET',42,'2026-10-15 05:13:01','2026-10-15 05:13:01'),(260,'评价回复','EVAL_REPLY','/evaluations/{evaluationId}/reply','POST',42,'2026-10-15 05:18:12','2026-10-15 05:18:12');
/*!40000 ALTER TABLE `permission` ENABLE KEYS */;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product` (
  `product_id` bigint NOT NULL AUTO_INCREMENT COMMENT '商品唯一标识',
  `category_id` int NOT NULL COMMENT '外键，商品分类 ID（关联product_category.category_id，如 1 - 相机、2 - 镜头）',
  `brand` int NOT NULL COMMENT '器材品牌（如佳能、索尼、尼康）',
  `model` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '器材型号（如佳能 R5、索尼 24-70F2.8）',
  `product_type` tinyint NOT NULL COMMENT '商品类型：1 - 全新器材，2 - 二手器材，3 - 租赁专用器材',
  `condition` tinyint DEFAULT NULL COMMENT '成色（仅二手 / 租赁用）：1-99 新，2-95 新，3-9 新，4-8 新',
  `original_price` decimal(12,2) NOT NULL COMMENT '原价',
  `price` decimal(12,2) NOT NULL COMMENT '售价（全新 / 二手）或租赁单价（元 / 天，租赁专用）',
  `min_rental_days` int DEFAULT '3' COMMENT '最短租赁期限（天）',
  `stock` int NOT NULL DEFAULT '0' COMMENT '库存数量（租赁专用器材为 “可租数量”）',
  `seller_id` bigint NOT NULL COMMENT '外键,商家 ID（关联user.user_id，仅企业用户可作为卖家）',
  `audit_status` tinyint NOT NULL DEFAULT '0' COMMENT '审核状态：0 - 待审核，1 - 审核通过，2 - 审核驳回（管理员审核）',
  `reject_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '审核驳回原因（如 “缺少保修证明”）',
  `is_on_shelf` tinyint NOT NULL DEFAULT '0' COMMENT '是否上架：0 - 下架，1 - 上架（审核通过后可手动上架）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '商品创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '商品信息更新时间',
  `min_stock` int NOT NULL DEFAULT '10' COMMENT '安全库存数量（库存低于此值时系统自动提醒补货）',
  `color` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '商品颜色（仅全新商品使用）',
  PRIMARY KEY (`product_id`) USING BTREE,
  KEY `category_id` (`category_id`,`brand`,`model`,`product_type`,`condition`,`stock`,`seller_id`,`audit_status`,`is_on_shelf`) USING BTREE,
  KEY `seller_id` (`seller_id`) USING BTREE,
  KEY `brand` (`brand`) USING BTREE,
  KEY `stock` (`stock`) USING BTREE,
  KEY `idx_product_onsale_time` (`audit_status`,`is_on_shelf`,`create_time`,`product_id`),
  KEY `idx_product_audit_time` (`audit_status`,`create_time`),
  KEY `idx_product_onsale_type_time` (`audit_status`,`is_on_shelf`,`product_type`,`create_time`,`product_id`),
  KEY `idx_product_onsale_price` (`audit_status`,`is_on_shelf`,`price`,`product_id`),
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `product_category` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_ibfk_2` FOREIGN KEY (`seller_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_ibfk_3` FOREIGN KEY (`brand`) REFERENCES `brand` (`brand_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储摄影器材的核心基础信息，区分全新 / 二手 / 租赁三种商品类型，是商品管理与交易的核心表。\r\n备注：全新器材需关联品牌授权证明（存储于product_detail），否则audit_status驳回；库存低于 5 件时，系统自动提醒seller_id对应的商家补货。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product`
--

/*!40000 ALTER TABLE `product` DISABLE KEYS */;
INSERT INTO `product` VALUES (1,11,11,'Z62',1,NULL,13999.00,9200.00,NULL,66,8,1,NULL,1,'2026-10-15 06:08:46','2026-10-15 06:08:46',10,''),(2,21,21,'Z 24-120 F4S',1,NULL,8999.00,7999.00,NULL,3,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,'默认颜色'),(3,11,12,'A7R5',1,NULL,17999.00,16300.00,NULL,99,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,'默认颜色'),(4,12,11,'D850',2,85,12999.00,5999.00,NULL,1,8,1,NULL,1,'2026-10-15 03:44:09','2026-10-15 03:44:09',10,''),(5,11,11,'Z6',2,95,12999.00,5555.00,NULL,1,8,1,NULL,1,'2026-10-15 03:44:09','2026-10-15 03:44:09',10,''),(6,11,11,'ZR',3,NULL,13999.00,120.09,1,84,8,1,NULL,1,'2026-04-11 08:49:20','2026-04-11 08:49:20',10,''),(7,21,21,'Z 70-200mm f2.8 VR S',3,NULL,14999.00,100.00,3,4,8,1,NULL,1,'2026-01-11 16:26:30','2026-01-11 16:26:30',10,''),(8,11,11,'Z8',1,90,25999.00,18999.00,NULL,88,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,''),(15,11,11,'Z8',1,90,25999.00,15999.00,NULL,88,8,2,'111111',0,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,''),(20,11,11,'z8',1,90,28888.00,18888.00,NULL,8555,8,1,NULL,0,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,''),(21,11,12,'A7M4',1,90,19999.00,14999.00,NULL,220,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,''),(22,11,11,'Z72',2,90,17999.00,9999.00,NULL,1,8,1,NULL,1,'2026-10-15 03:44:09','2026-10-15 03:44:09',10,NULL),(23,11,11,'ZR',1,90,14999.00,12999.00,NULL,111,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,''),(24,11,11,'Z63',1,90,16999.00,14449.00,NULL,0,19,1,'管理员强制下架',1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(25,27,21,'50mm F1.8 S',1,90,3999.00,3299.00,NULL,90,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,''),(26,11,13,'EOS R5 Mark II',2,90,15999.00,9999.00,NULL,1,8,1,NULL,1,'2026-10-15 03:44:09','2026-10-15 03:44:09',10,NULL),(27,13,41,'Action 4',1,90,1999.00,1499.00,NULL,200,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(28,11,13,'EOS R6 Mark II',1,90,25999.00,22999.00,NULL,99,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(29,11,12,'ZV-E1',1,90,21999.00,18999.00,NULL,99,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(30,13,41,'ACTION 4',2,90,1599.00,999.00,NULL,0,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(31,13,41,'ACTION 6',1,90,2999.00,2899.00,NULL,22,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(32,32,37,'Mavic 4 Pro',1,90,18999.00,18999.00,NULL,78,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(33,11,37,'Mavic 3 Pro',3,90,29999.00,109.00,6,1,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(34,21,12,'FE 24-70mm F2.8 GM II',3,90,15999.00,56.00,3,66,8,1,NULL,1,'2026-04-11 01:32:45','2026-04-11 01:32:45',10,NULL),(35,11,12,'A7M4',3,90,18999.00,80.00,3,3,8,1,NULL,1,'2026-04-11 01:34:25','2026-04-11 01:34:25',10,NULL),(36,11,14,'X-T4',3,90,15999.00,90.00,3,50,8,1,NULL,1,'2026-04-11 01:37:36','2026-04-11 01:37:36',10,NULL),(37,32,37,'Mini 4K',3,90,8999.00,32.00,3,88,8,1,NULL,1,'2026-04-11 01:40:28','2026-04-11 01:40:28',10,NULL),(38,11,13,'EOS R6 Mark II',3,90,29999.00,150.00,3,88,8,1,NULL,1,'2026-04-11 01:41:35','2026-04-11 01:41:35',10,NULL),(39,27,23,'EF 50mm F1.2 L USM',3,90,3000.00,20.00,3,5555,8,1,NULL,1,'2026-04-11 01:42:47','2026-04-11 01:42:47',10,NULL),(40,11,11,'Z63',3,90,18999.00,70.00,6,63,8,1,NULL,1,'2026-04-11 01:45:50','2026-04-11 02:14:26',10,NULL),(41,21,21,'Z 24-70mm F4 S',3,90,4999.00,40.00,3,11,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(42,11,41,'ACTION 5 PRO',3,90,2199.00,21.00,3,55,8,1,NULL,1,'2026-04-11 02:09:56','2026-04-11 02:09:56',10,NULL),(43,11,41,'ACTION 5 PRO',3,90,2199.00,21.00,3,55,8,1,NULL,1,'2026-04-11 02:10:05','2026-04-11 02:10:05',10,NULL),(44,11,41,'ACTION 5 PRO',1,90,2199.00,2000.00,NULL,55,8,2,NULL,0,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(45,13,41,'Action 5 PRO',3,90,2199.00,29.00,3,66,8,1,NULL,1,'2026-04-11 02:15:29','2026-04-11 02:15:29',10,NULL),(46,13,41,'ACTION 5 PRO',1,90,2199.00,1599.00,NULL,55,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL),(47,11,11,'ZR',1,90,13999.00,12999.00,NULL,22,8,1,NULL,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',10,NULL);
/*!40000 ALTER TABLE `product` ENABLE KEYS */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_product_insert` AFTER INSERT ON `product` FOR EACH ROW BEGIN
    IF EXISTS (SELECT 1 FROM `sku` WHERE `product_id` = NEW.`product_id`
               AND `sku_attribute` = '默认' AND `sku_value` = '默认') THEN
        UPDATE `sku`
        SET `price` = NEW.`price`, `stock` = NEW.`stock`, `min_stock` = NEW.`min_stock`
        WHERE `product_id` = NEW.`product_id`
          AND `sku_attribute` = '默认' AND `sku_value` = '默认';
        SET @sku_id = (SELECT `sku_id` FROM `sku` WHERE `product_id` = NEW.`product_id` ORDER BY `sku_id` LIMIT 1);
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
        VALUES (NEW.`product_id`,
                CONCAT((SELECT `brand_name` FROM `brand` WHERE `brand_id` = NEW.`brand`), ' ', NEW.`model`),
                CASE NEW.`product_type` WHEN 2 THEN 'used' WHEN 3 THEN 'rental' ELSE 'new' END,
                @sku_id, '默认', '默认', NEW.`stock`, NEW.`min_stock`, 0);
    END IF;

    IF NEW.`product_type` = 3 THEN
        INSERT INTO `product_rental_detail` (`product_id`, `deposit`, `max_rental_days`, `min_rental_days`,
            `insurance_fee`, `late_fee_rate`, `damage_fee_rule`, `pickup_methods`, `delivery_fee`)
        VALUES (NEW.`product_id`, NEW.`original_price` * 0.1, 90, IFNULL(NEW.`min_rental_days`, 1),
                0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00);
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_product_stock_alert` AFTER UPDATE ON `product` FOR EACH ROW BEGIN
    
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
            
            (SELECT seller_id FROM product WHERE product_id = NEW.product_id),
            
            CONCAT('您的商品【', NEW.brand, ' ', NEW.model, '】库存仅剩', NEW.stock, '件，请及时补货'),
            1,  
            CURRENT_TIMESTAMP,
            0   
        );
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_product_update` AFTER UPDATE ON `product` FOR EACH ROW BEGIN
    IF NEW.`product_type` = 3 THEN
        IF EXISTS (SELECT 1 FROM `product_rental_detail` WHERE `product_id` = NEW.`product_id`) THEN
            UPDATE `product_rental_detail`
            SET `min_rental_days` = NEW.`min_rental_days`,
                `deposit` = NEW.`original_price` * 0.1, `updated_time` = NOW()
            WHERE `product_id` = NEW.`product_id`;
        ELSE
            INSERT INTO `product_rental_detail` (`product_id`, `deposit`, `max_rental_days`, `min_rental_days`,
                `insurance_fee`, `late_fee_rate`, `damage_fee_rule`, `pickup_methods`, `delivery_fee`)
            VALUES (NEW.`product_id`, NEW.`original_price` * 0.1, 90, IFNULL(NEW.`min_rental_days`, 1),
                    0.00, 0.05, '请联系客服了解详细赔偿规则', 'delivery', 0.00);
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `product_category`
--

DROP TABLE IF EXISTS `product_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_category` (
  `category_id` int NOT NULL AUTO_INCREMENT COMMENT '分类唯一标识',
  `category_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类名称（如 “相机”“镜头”“三脚架”“灯光设备”）',
  `parent_id` int DEFAULT '0' COMMENT '外键,父分类 ID（如 “全画幅相机” 父分类为 “相机”）',
  `category_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '分类编码，按层级规则生成（如顶级分类 “相机” 编码为 “CAM”，子分类 “全画幅相机” 编码为 “CAM-FULL”）',
  `sort` int NOT NULL DEFAULT '0' COMMENT '分类排序（数值越小越靠前）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '分类状态：\r\n- 1 = 启用（可被商品关联、前端展示）\r\n- 0 = 禁用（不可关联商品、前端隐藏）',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '分类描述，说明分类涵盖的器材范围（如 “全画幅相机：传感器尺寸为 36×24mm 左右的专业相机”）',
  `create_by` bigint NOT NULL COMMENT '外键,分类创建人 ID，关联user.user_id（仅管理员可创建分类）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '外键,分类更新人 ID，关联user.user_id（仅管理员可更新分类）',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '分类更新时间',
  PRIMARY KEY (`category_id`) USING BTREE,
  UNIQUE KEY `category_name` (`category_name`,`category_code`) USING BTREE,
  KEY `parent_id` (`parent_id`,`sort`,`status`,`create_by`,`update_by`) USING BTREE,
  KEY `create_by` (`create_by`) USING BTREE,
  KEY `product_category_ibfk_3` (`update_by`) USING BTREE,
  CONSTRAINT `product_category_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `product_category` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_category_ibfk_2` FOREIGN KEY (`create_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `product_category_ibfk_3` FOREIGN KEY (`update_by`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储摄影器材分类（如相机、镜头、灯光设备），为product提供分类关联。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_category`
--

/*!40000 ALTER TABLE `product_category` DISABLE KEYS */;
INSERT INTO `product_category` VALUES (1,'相机',NULL,'CAM',0,1,'',1,'2026-01-06 22:07:12',1,'2026-01-06 22:07:12'),(2,'镜头',NULL,'LEN',0,1,NULL,1,'2025-12-20 16:59:02',1,'2025-12-20 16:59:10'),(3,'无人机',NULL,'DRONE',0,1,NULL,1,'2026-04-10 18:25:30',NULL,'2026-04-10 18:25:32'),(11,'微单相机',1,'MCAM',1,1,NULL,1,'2025-12-21 13:12:38',1,'2025-12-21 13:12:43'),(12,'单反相机',1,'SLR',1,1,'',1,'2026-01-06 22:07:17',1,'2026-01-06 22:07:17'),(13,'运动相机',1,'ACTION_CAM',1,1,NULL,1,'2026-04-10 18:25:59',NULL,'2026-04-10 18:25:59'),(21,'变焦镜头',2,'ZLEN',1,1,NULL,1,'2025-12-21 15:18:11',1,'2025-12-21 15:18:11'),(22,'定焦镜头',2,'PLEN',1,1,NULL,1,'2025-12-21 15:18:50',1,'2025-12-21 15:18:55'),(27,'50mm',22,'50mm',2,1,'',1,'2026-01-06 22:43:05',NULL,'2026-01-06 22:43:05'),(31,'微型无人机',3,'DRONE_WEI',1,1,NULL,1,'2026-04-10 18:26:45',NULL,'2026-04-10 18:26:45'),(32,'轻型无人机',3,'DRONE_QING',1,1,NULL,1,'2026-04-10 18:29:10',NULL,'2026-04-10 18:29:10'),(33,'中型无人机',3,'DRONE_ZHONG',1,1,NULL,1,'2026-04-10 18:28:01',NULL,'2026-04-10 18:28:03'),(34,'大型无人机',3,'DRONE_DA',1,1,NULL,1,'2026-04-10 18:28:31',NULL,'2026-04-10 18:28:32'),(35,'穿越机',3,'DRONE_CHUAN',1,1,NULL,1,'2026-04-10 18:29:04',NULL,'2026-04-10 18:29:05'),(40,'三脚架',NULL,'TRIPOD',0,1,'',1,'2026-01-06 22:55:29',NULL,'2026-01-06 22:55:29'),(41,'铝合金三脚架',40,'ALU-TRIPOD',1,1,'',1,'2026-01-06 22:57:19',NULL,'2026-01-06 22:57:19'),(42,'碳纤维三脚架',40,'CAR-F-TRIPOD',1,1,'',1,'2026-01-06 22:58:20',NULL,'2026-01-06 22:58:20');
/*!40000 ALTER TABLE `product_category` ENABLE KEYS */;

--
-- Table structure for table `product_detail`
--

DROP TABLE IF EXISTS `product_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_detail` (
  `detail_id` bigint NOT NULL AUTO_INCREMENT COMMENT '详情记录唯一标识',
  `product_id` bigint NOT NULL COMMENT '外键，关联product.product_id，删除商品时同步删除详情',
  `parameters` json NOT NULL COMMENT '专业参数（JSON 格式，如{"画幅":"全画幅","焦距":"24-70mm","光圈":"F2.8"}）',
  `warranty_info` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '保修信息（如 “官方保修 1 年，2025-12-31 到期”）',
  `authorization` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '品牌授权证明路径（仅全新器材需上传）',
  `img_urls` json NOT NULL COMMENT '器材实拍图路径（JSON 数组，至少 3 张，含细节图，如["/img/1.jpg","/img/2.jpg"]）',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '商品描述（商家自定义，如 “95 新镜头，无划痕，仅使用 3 次”）',
  `usage_duration` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '使用时长（二手商品专用，如"1年"）',
  `repair_history` tinyint DEFAULT '0' COMMENT '维修记录：0-无维修记录，1-有维修记录（二手商品专用）',
  `accessories` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '配件清单（二手商品专用，如"原装电池、充电器、相机包"）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '详情创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '详情更新时间',
  PRIMARY KEY (`detail_id`) USING BTREE,
  UNIQUE KEY `product_id` (`product_id`) USING BTREE,
  CONSTRAINT `product_detail_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储摄影器材的专业参数、保修信息、图片等详细内容，与product一对一关联，避免基础表字段冗余。\r\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_detail`
--

/*!40000 ALTER TABLE `product_detail` DISABLE KEYS */;
INSERT INTO `product_detail` VALUES (1,1,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/Z62_1.png\", \"/uploads/seed/Z62_2.png\", \"/uploads/seed/Z62_3.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(2,15,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-04-10 22:56:42','2026-04-11 01:35:01'),(3,8,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/a005143dadc14798af03a344229cca26.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(4,4,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/D850_1.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(5,6,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-04-10 22:56:47','2026-04-10 22:56:47'),(7,20,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/661e6ec68d3f4fb09728b434e0ed8dcd.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(8,21,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/ac556fd1cf9b4cb1abfe283875a71b70.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(9,22,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 22:56:51','2026-04-10 22:56:51'),(10,23,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/d12bf2e4e70f45928697a62bd20c80f8.png\", \"/uploads/seed/06d51035f6d740edbb5769dc83eadd5e.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(11,24,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 22:56:53','2026-04-10 22:56:53'),(12,25,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[\"/uploads/seed/c5ea913d6c4f4b719992f595108073f5.png\", \"/uploads/seed/52d572ee89a4443a849eb60955eb05ba.png\"]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(13,26,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 22:57:28','2026-04-10 22:57:28'),(14,27,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 22:57:30','2026-04-10 22:57:30'),(15,28,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 22:57:32','2026-04-10 22:57:32'),(16,29,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康Z卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}',NULL,NULL,'[]','1111111111111111111111111将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\r\n\r\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\r\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\r\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\r\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\r\n- MB-N11电池匣（另购）提供舒适安心的竖拍\r\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\r\n\r\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\r\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\r\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 22:57:48','2026-04-10 22:57:48'),(17,30,'{}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\n\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\n- MB-N11电池匣（另购）提供舒适安心的竖拍\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\n\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 23:05:35','2026-04-10 23:05:35'),(18,31,'{}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\n\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\n- MB-N11电池匣（另购）提供舒适安心的竖拍\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\n\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 23:10:59','2026-04-10 23:10:59'),(19,32,'{}',NULL,NULL,'[]','将激动人心的时刻记录在戏剧性的照片中，让观众沉浸在另一个世界的电影级4K超高清视频，尼康Z 6II可以让您自信地实现。双EXPEED 6影像处理器允许以约14幅/秒的速度一次连拍可达约124张照片*1。眼部侦测自动对焦和动物侦测自动对焦在拍摄照片和视频时均可使用。包括10位HDR（HLG）和4K超高清/50p/60p*2在内的多种视频录制选项可满足不同的需求。此外，双存储卡插槽和另购的MB-N11电池匣为发挥多功能性提供保障。Z 6II为多媒体创作者提供一个可靠的复合解决方案。\n\n- 具备自动曝光和自动对焦的约14幅/秒高速连拍，缓存能力提升，一次连拍可达约124张照片*1\n- 拍摄照片和视频均可使用眼部侦测自动对焦和动物侦测自动对焦\n- 多种视频录制选项，包括RAW*3, HDR (HLG), N-Log视频输出至相机内优化校准，满足多种需求\n- 双存储卡插槽兼容CFexpress 卡和UHS-II SD卡，支持可靠的数据备份和快速的工作流程\n- MB-N11电池匣（另购）提供舒适安心的竖拍\n- 尼克尔Z卡口镜头系列不断扩展，在视频和照片方面均提供良好的渲染能力\n\n*1 使用索尼CEB-G128 CFexpress卡，在高速连拍（延长）模式下使用单点自动对焦（AF），12位无损压缩RAW（L）时。\n*2 将于2021年2月固件升级时支持。基于DX的视频格式下提供。相机内提供8位色彩录制，10位和12位色彩需使用另购的外录设备。\n*3 需另外收费升级后使用，同时需使用另购的外录设备。',NULL,NULL,NULL,'2026-04-10 23:36:42','2026-04-10 23:36:42'),(20,33,'{}',NULL,NULL,'[\"/uploads/seed/fc0ee5a8bc2c456aa7b4e8d9d68ab0ea.png\"]','111111111111111111测试','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(21,34,'{}',NULL,NULL,'[]','测试1111111111111111',NULL,NULL,NULL,'2026-04-11 01:32:45','2026-04-11 01:32:45'),(22,35,'{}',NULL,NULL,'[]','M44444444444',NULL,NULL,NULL,'2026-04-11 01:34:25','2026-04-11 01:34:25'),(23,36,'{}',NULL,NULL,'[]','111111111111111111111111111',NULL,NULL,NULL,'2026-04-11 01:37:36','2026-04-11 01:37:36'),(24,37,'{}',NULL,NULL,'[]','4kkkkkkkkkkkkkkkk',NULL,NULL,NULL,'2026-04-11 01:40:28','2026-04-11 01:40:28'),(25,38,'{}',NULL,NULL,'[]','R66666666666666662',NULL,NULL,NULL,'2026-04-11 01:41:35','2026-04-11 01:41:35'),(26,39,'{}',NULL,NULL,'[]','aaaaaaaaaaaaaaaaaaa',NULL,NULL,NULL,'2026-04-11 01:42:47','2026-04-11 01:42:47'),(27,40,'{}',NULL,NULL,'[\"/uploads/seed/2fd8e973dd5447d1947d9983ea87ce20.png\"]','6333333333333333333Z','',0,'','2026-10-15 03:42:34','2026-10-15 03:42:34'),(28,41,'{}',NULL,NULL,'[]','sssssssssssssss',NULL,NULL,NULL,'2026-04-11 01:47:18','2026-04-11 01:47:18'),(29,42,'{}',NULL,NULL,'[]','5555555555555',NULL,NULL,NULL,'2026-04-11 02:09:56','2026-04-11 02:09:56'),(30,43,'{}',NULL,NULL,'[]','5555555555555',NULL,NULL,NULL,'2026-04-11 02:10:05','2026-04-11 02:10:05'),(31,44,'{}',NULL,NULL,'[]','5555555555555',NULL,NULL,NULL,'2026-04-11 02:10:45','2026-04-11 02:10:45'),(32,45,'{}',NULL,NULL,'[]','5ppppppppppppppro',NULL,NULL,NULL,'2026-04-11 02:15:29','2026-04-11 02:15:29'),(33,46,'{}',NULL,NULL,'[]','55555555555555555555555',NULL,NULL,NULL,'2026-04-11 02:30:47','2026-04-11 02:30:47'),(34,47,'{}',NULL,NULL,'[]','111111111111111111111',NULL,NULL,NULL,'2026-04-11 11:04:23','2026-04-11 11:04:23'),(35,5,'{\"卡口\": \"尼康 Z\", \"视频\": \"4K 30p\", \"连拍\": \"12fps\", \"重量\": \"675g（含电池）\", \"防抖\": \"机身五轴防抖\", \"传感器\": \"2450万像素全画幅\"}','平台验机后 7 天内可退，超出按平台售后规则处理',NULL,'[]','【尼康 Z6】经平台验机后上架，成色与瑕疵描述以实物图为准。','约 2 年',0,'原装电池、充电器、机身盖','2026-10-15 03:44:15','2026-10-15 03:44:15'),(36,3,'{\"卡口\": \"索尼 E\", \"屏幕\": \"4 轴多角度翻转屏\", \"视频\": \"8K 30p / 4K 60p\", \"连拍\": \"10fps\", \"重量\": \"723g（含电池）\", \"防抖\": \"8 档机身五轴防抖\", \"传感器\": \"6100万像素全画幅 Exmor R\"}','全国联保一年，凭发票到品牌售后网点保修',NULL,'[]','【索尼 A7R5】国行正品，支持开发票。',NULL,0,NULL,'2026-10-15 03:44:15','2026-10-15 03:44:15'),(37,2,'{\"卡口\": \"尼康 Z\", \"焦距\": \"24-120mm\", \"重量\": \"630g\", \"防抖\": \"VR 光学防抖\", \"最大光圈\": \"F4\", \"最近对焦\": \"0.35m\", \"滤镜口径\": \"77mm\"}','全国联保一年，凭发票到品牌售后网点保修',NULL,'[]','【尼克尔 Z 24-120 F4S】国行正品，支持开发票。',NULL,0,NULL,'2026-10-15 03:44:15','2026-10-15 03:44:15'),(38,7,'{\"卡口\": \"尼康 Z\", \"焦距\": \"70-200mm\", \"重量\": \"1360g\", \"防抖\": \"VR 光学防抖\", \"最大光圈\": \"F2.8\", \"最近对焦\": \"0.5m\", \"滤镜口径\": \"77mm\"}','租赁期内由平台承保，人为损坏按租赁协议赔付',NULL,'[]','【尼克尔 Z 70-200mm f2.8 VR S】按天计价，押金在归还验收后原路退回。',NULL,0,NULL,'2026-10-15 03:44:15','2026-10-15 03:44:15');
/*!40000 ALTER TABLE `product_detail` ENABLE KEYS */;

--
-- Table structure for table `product_image`
--

DROP TABLE IF EXISTS `product_image`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_image` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `product_id` bigint NOT NULL COMMENT '商品ID（关联product表）',
  `image_id` bigint NOT NULL COMMENT '图片ID（关联sys_image表）',
  `image_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '图片类型（main：主图；detail：详情图；gallery：图库图）',
  `sort` int DEFAULT '0' COMMENT '排序号（用于图片展示顺序）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '逻辑删除：0 正常 1 已删',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_product_id` (`product_id`) USING BTREE,
  KEY `idx_image_id` (`image_id`) USING BTREE,
  KEY `idx_product_type_sort` (`product_id`,`image_type`,`sort`),
  CONSTRAINT `product_image_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `product_image_ibfk_2` FOREIGN KEY (`image_id`) REFERENCES `sys_image` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='商品图片关联表，实现商品与图片的一对多关联';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_image`
--

/*!40000 ALTER TABLE `product_image` DISABLE KEYS */;
INSERT INTO `product_image` VALUES (1,1,1,'main',0,'2025-12-18 22:58:55',0),(2,2,2,'main',0,'2025-12-20 17:05:12',0),(3,3,3,'main',0,'2025-12-20 17:16:05',0),(4,4,4,'main',0,'2025-12-27 17:16:56',0),(5,5,5,'main',0,'2025-12-27 18:58:00',0),(6,6,6,'main',0,'2025-12-28 18:28:20',0),(7,7,7,'main',0,'2025-12-28 18:28:31',0),(25,20,38,'main',0,'2026-02-09 22:22:59',0),(26,20,39,'detail',0,'2026-02-09 22:46:49',0),(27,21,40,'main',0,'2026-02-09 22:56:02',0),(28,21,41,'detail',0,'2026-02-09 23:40:26',0),(29,22,42,'main',0,'2026-02-10 00:42:05',0),(30,23,43,'main',0,'2026-02-10 00:43:31',0),(32,23,44,'detail',1,'2026-02-10 00:43:44',0),(33,24,45,'main',0,'2026-02-10 00:52:09',0),(34,24,46,'detail',1,'2026-02-10 00:52:09',0),(35,24,47,'detail',2,'2026-02-10 00:52:09',0),(36,24,48,'detail',3,'2026-02-10 00:52:09',0),(37,25,49,'main',0,'2026-03-08 01:35:03',0),(38,25,50,'detail',1,'2026-03-08 01:35:03',0),(39,8,51,'main',0,'2026-03-08 01:52:54',0),(40,8,52,'detail',0,'2026-03-08 01:53:05',0),(41,8,53,'detail',0,'2026-03-08 01:53:39',0),(42,8,54,'detail',1,'2026-03-08 01:53:39',0),(43,8,55,'detail',0,'2026-03-08 01:53:50',0),(47,26,56,'main',0,'2026-04-10 22:31:28',0),(48,26,57,'detail',1,'2026-04-10 22:31:28',0),(49,27,58,'main',0,'2026-04-10 22:40:07',0),(50,27,59,'detail',1,'2026-04-10 22:40:07',0),(51,28,60,'main',0,'2026-04-10 22:46:25',0),(52,28,61,'detail',1,'2026-04-10 22:46:25',0),(53,29,62,'main',0,'2026-04-10 22:49:11',0),(54,29,63,'detail',1,'2026-04-10 22:49:11',0),(55,30,64,'main',0,'2026-04-10 23:05:35',0),(56,31,65,'main',0,'2026-04-10 23:10:59',0),(57,32,66,'main',0,'2026-04-10 23:36:42',0),(58,33,67,'main',0,'2026-04-11 01:30:42',0),(59,34,68,'main',0,'2026-04-11 01:32:45',0),(60,34,69,'detail',1,'2026-04-11 01:32:45',0),(61,35,70,'main',0,'2026-04-11 01:34:25',0),(62,36,71,'main',0,'2026-04-11 01:37:36',0),(63,37,72,'main',0,'2026-04-11 01:40:28',0),(64,38,73,'main',0,'2026-04-11 01:41:35',0),(65,39,74,'main',0,'2026-04-11 01:42:47',0),(66,40,75,'main',0,'2026-04-11 01:44:46',0),(67,41,76,'main',0,'2026-04-11 01:47:18',0),(69,42,77,'main',0,'2026-04-11 02:09:56',0),(70,43,77,'main',0,'2026-04-11 02:10:05',0),(71,44,77,'main',0,'2026-04-11 02:10:45',0),(72,44,78,'detail',1,'2026-04-11 02:10:45',0),(75,45,79,'main',0,'2026-04-11 02:15:29',0),(76,46,80,'main',0,'2026-04-11 02:30:47',0),(77,47,81,'main',0,'2026-04-11 11:04:23',0),(78,15,38,'main',0,'2026-10-15 03:44:16',0);
/*!40000 ALTER TABLE `product_image` ENABLE KEYS */;

--
-- Table structure for table `product_rental_detail`
--

DROP TABLE IF EXISTS `product_rental_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_rental_detail` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `product_id` bigint NOT NULL COMMENT '外键，关联product.product_id',
  `deposit` decimal(12,2) NOT NULL COMMENT '租赁押金（元）',
  `max_rental_days` int NOT NULL COMMENT '最长租赁期限（天）',
  `min_rental_days` int NOT NULL COMMENT '最短租赁期限（天）',
  `insurance_fee` decimal(12,2) NOT NULL COMMENT '保险费用（元/天）',
  `late_fee_rate` decimal(5,2) NOT NULL COMMENT '逾期违约金率（每天按租金的百分比计算）',
  `damage_fee_rule` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '损坏赔偿规则',
  `pickup_methods` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '取货方式：delivery-配送上门, store_pickup-门店自取',
  `delivery_fee` decimal(12,2) NOT NULL COMMENT '配送费用（元）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `product_id` (`product_id`) USING BTREE,
  CONSTRAINT `product_rental_detail_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='租赁商品详情表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_rental_detail`
--

/*!40000 ALTER TABLE `product_rental_detail` DISABLE KEYS */;
INSERT INTO `product_rental_detail` VALUES (1,6,1399.90,90,1,10.00,0.05,'根据损坏程度，按商品原价的10%-100%赔偿','delivery',50.00,'2025-12-29 23:21:28','2026-04-11 14:58:21'),(2,7,1499.90,90,3,8.00,0.05,'根据损坏程度，按商品原价的10%-100%赔偿','delivery',50.00,'2025-12-29 23:21:39','2025-12-29 23:21:39'),(3,33,2999.90,90,6,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-10-15 03:48:40'),(4,34,1599.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:06:36'),(5,35,1899.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:06:36'),(6,36,1599.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:06:36'),(7,37,899.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:06:36'),(8,38,2999.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:06:36'),(9,39,300.00,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:06:36'),(10,40,1899.90,90,6,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-04-11 02:14:26'),(11,41,499.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:06:36','2026-10-15 05:25:27'),(18,42,219.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:09:55','2026-10-15 05:29:41'),(19,43,219.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:10:04','2026-04-11 13:54:46'),(20,45,219.90,90,3,0.00,0.05,'请联系客服了解详细赔偿规则','delivery',0.00,'2026-04-11 02:15:28','2026-10-15 05:27:29');
/*!40000 ALTER TABLE `product_rental_detail` ENABLE KEYS */;

--
-- Table structure for table `refund`
--

DROP TABLE IF EXISTS `refund`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refund` (
  `refund_id` bigint NOT NULL AUTO_INCREMENT,
  `order_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `refund_amount` decimal(10,2) NOT NULL,
  `refund_status` int NOT NULL COMMENT '0: 申请中, 1: 退款成功, 2: 退款失败',
  `refund_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `refund_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `refund_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `apply_time` datetime DEFAULT NULL,
  `refund_time` datetime DEFAULT NULL,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`refund_id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_refund_status` (`refund_status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='退款表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refund`
--

/*!40000 ALTER TABLE `refund` DISABLE KEYS */;
INSERT INTO `refund` VALUES (2,67,7,9200.00,2,'其他原因','11111111111111','wechat','2026-04-07 17:10:06','2026-04-07 17:46:08','2026-04-07 17:10:06','2026-04-07 17:46:08'),(4,69,7,16495.00,1,'物流问题','阿大撒','wechat','2026-04-07 17:54:57','2026-04-07 17:55:18','2026-04-07 17:54:57','2026-04-07 17:55:18'),(5,70,7,14999.00,0,'商品质量问题','','wechat','2026-04-07 17:56:48',NULL,'2026-04-07 17:56:48','2026-04-07 17:56:48'),(6,71,7,1444900.00,0,'商品与描述不符','','alipay','2026-04-07 17:57:33',NULL,'2026-04-07 17:57:33','2026-04-07 17:57:33'),(7,72,7,1830800.00,2,'拍错商品','','alipay','2026-04-07 17:58:10','2026-04-07 17:58:16','2026-04-07 17:58:10','2026-04-07 17:58:16'),(8,77,7,4402.15,0,'拍错商品','','wechat','2026-04-11 00:50:20',NULL,'2026-04-11 00:50:20','2026-04-11 00:50:20'),(9,89,23,18999.00,0,'商品质量问题','机身有划痕，希望退货退款。','alipay','2026-10-15 03:50:59',NULL,'2026-10-15 03:50:59','2026-10-15 03:50:59'),(10,94,23,9200.00,1,'不想要了','测试退款','alipay','2026-10-15 05:27:08','2026-10-15 05:27:08','2026-10-15 05:27:08','2026-10-15 05:27:08'),(11,96,23,9200.00,1,'不想要了','测试退款','alipay','2026-10-15 05:27:18','2026-10-15 05:27:19','2026-10-15 05:27:18','2026-10-15 05:27:19'),(12,98,23,9200.00,1,'不想要了','测试退款','alipay','2026-10-15 05:27:31','2026-10-15 05:27:31','2026-10-15 05:27:31','2026-10-15 05:27:31'),(13,100,23,9200.00,1,'不想要了','测试退款','alipay','2026-10-15 05:29:42','2026-10-15 05:29:43','2026-10-15 05:29:42','2026-10-15 05:29:43'),(14,102,23,9200.00,1,'不想要了','测试退款','alipay','2026-10-15 05:31:44','2026-10-15 05:31:44','2026-10-15 05:31:44','2026-10-15 05:31:44'),(15,104,23,9200.00,1,'不想要了','测试退款','alipay','2026-10-15 05:35:11','2026-10-15 05:35:11','2026-10-15 05:35:11','2026-10-15 05:35:11');
/*!40000 ALTER TABLE `refund` ENABLE KEYS */;

--
-- Table structure for table `rental`
--

DROP TABLE IF EXISTS `rental`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rental` (
  `rental_id` bigint NOT NULL AUTO_INCREMENT COMMENT '租赁记录唯一标识',
  `order_id` bigint NOT NULL COMMENT '关联order.order_id，订单删除时同步删除租赁记录',
  `start_date` datetime NOT NULL COMMENT '起租时间（用户选择或商家确认）',
  `end_date` datetime NOT NULL COMMENT '到期时间（start_date + lease_term天，用于到期提醒）',
  `lease_term` int NOT NULL COMMENT '租期（单位：天，1-90 天）',
  `rent` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '总租金（unit_price × lease_term，会员享折扣）',
  `pickup_type` tinyint NOT NULL COMMENT '取货方式：1 - 上门取件，2 - 快递配送',
  `return_type` tinyint NOT NULL COMMENT '归还方式：1 - 上门还件，2 - 自行寄送',
  `return_status` tinyint NOT NULL DEFAULT '0' COMMENT '归还状态：0 - 未归还，1 - 待验收，2 - 验收通过（押金退还），3 - 验收异常（扣押金）',
  `renew_status` tinyint NOT NULL DEFAULT '0' COMMENT '续租状态：0 - 无续租，1 - 续租申请中，2 - 续租通过，3 - 续租驳回',
  `overdue_days` int NOT NULL DEFAULT '0' COMMENT '逾期天数（end_date后未归还的天数，按日租金 1.5 倍收滞纳金）',
  `initial_img` json NOT NULL COMMENT '出租时器材初始状态图（JSON 数组，用于归还验收对比）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '租赁记录创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '租赁状态更新时间',
  PRIMARY KEY (`rental_id`) USING BTREE,
  UNIQUE KEY `order_id` (`order_id`) USING BTREE,
  KEY `start_date` (`start_date`,`end_date`,`return_status`,`renew_status`) USING BTREE,
  CONSTRAINT `rental_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储租赁订单的专属信息（租期、归还状态等），与order一对一关联（仅order_type=2时存在）。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rental`
--

/*!40000 ALTER TABLE `rental` DISABLE KEYS */;
INSERT INTO `rental` VALUES (2,58,'2026-02-09 20:13:50','2026-02-16 20:13:50',7,840.63,2,2,0,0,0,'[]','2026-02-09 20:13:50','2026-02-09 20:13:54'),(3,62,'2026-03-17 21:11:37','2026-03-24 21:11:37',7,4203.15,2,2,0,0,0,'[]','2026-03-17 21:11:37','2026-03-17 21:11:50'),(4,63,'2026-03-17 21:17:50','2026-03-20 21:17:50',3,300.00,2,2,0,0,0,'[]','2026-03-17 21:17:50','2026-03-17 21:17:53'),(5,64,'2026-03-17 21:18:20','2026-03-20 21:18:20',3,300.00,2,2,0,0,0,'[]','2026-03-17 21:18:20','2026-03-17 21:18:23'),(6,74,'2026-04-11 00:21:04','2026-05-03 00:21:04',22,2200.00,2,2,0,0,0,'[]','2026-04-11 00:21:04','2026-04-11 00:21:10'),(7,77,'2026-04-11 00:50:07','2026-05-06 00:50:07',25,3002.25,2,2,0,0,0,'[]','2026-04-11 00:50:07','2026-04-11 00:50:11'),(8,78,'2026-04-11 00:50:30','2026-05-08 00:50:30',27,3242.43,2,2,2,0,0,'[]','2026-04-11 00:50:30','2026-04-11 00:51:30'),(9,79,'2026-04-11 00:55:21','2026-05-14 00:55:21',33,3962.97,2,2,1,0,0,'[]','2026-04-11 00:55:21','2026-04-11 00:56:10'),(10,80,'2026-04-11 01:01:15','2026-04-21 01:01:15',10,1000.00,2,2,2,0,0,'[]','2026-04-11 01:01:15','2026-04-11 01:02:25'),(11,81,'2026-04-11 01:03:01','2026-05-14 01:03:01',33,3962.97,2,2,0,0,0,'[]','2026-04-11 01:03:01','2026-04-11 01:03:07'),(12,82,'2026-04-11 08:35:24','2026-05-07 08:35:24',26,6244.68,2,2,0,0,0,'[]','2026-04-11 08:35:24','2026-04-11 08:35:41'),(13,84,'2026-04-11 12:28:30','2026-05-06 12:28:30',25,12009.00,2,2,2,0,0,'[]','2026-04-11 12:28:30','2026-04-11 12:29:27'),(14,85,'2026-04-11 12:31:38','2026-05-06 12:31:38',25,3002.25,2,2,2,0,0,'[]','2026-04-11 12:31:38','2026-04-11 12:32:27'),(15,86,'2026-04-11 14:57:19','2026-05-12 14:57:19',31,3722.79,2,2,2,0,0,'[]','2026-04-11 14:57:19','2026-04-11 14:58:22'),(16,88,'2026-10-15 03:48:35','2026-10-21 03:48:35',6,654.00,2,2,1,0,0,'[]','2026-10-15 03:48:35','2026-10-15 03:48:40');
/*!40000 ALTER TABLE `rental` ENABLE KEYS */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_rental_overdue_freeze` AFTER UPDATE ON `rental` FOR EACH ROW BEGIN
    IF NEW.`overdue_days` >= 7 AND OLD.`overdue_days` < 7 THEN
        INSERT INTO `sys_notice` (`notice_id`, `user_id`, `content`, `notice_type`, `create_time`, `is_read`)
        SELECT NULL, o.`user_id`,
               CONCAT('租赁订单 ', o.`order_no`, ' 已逾期 ', NEW.`overdue_days`, ' 天，请尽快归还，逾期将影响账号使用'),
               3, CURRENT_TIMESTAMP, 0
        FROM `orders` o WHERE o.`order_id` = NEW.`order_id`;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role` (
  `role_id` int NOT NULL AUTO_INCREMENT COMMENT '角色唯一标识',
  `role_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色名称（如 “超级管理员”“普通管理员”“运营管理员”）',
  `user_type` tinyint NOT NULL COMMENT '角色id,1 - 个人用户，2 - 企业用户（器材商家），3 - 管理员，4 -超级管理员',
  `role_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色编码（如 “ADMIN_SUPER”“ADMIN_NORMAL”“ADMIN_OP”）',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '角色描述（如 “超级管理员拥有全系统权限，可修改所有配置”）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '角色创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '角色信息更新时间',
  PRIMARY KEY (`role_id`) USING BTREE,
  UNIQUE KEY `role_name` (`role_name`,`role_code`) USING BTREE,
  KEY `user_type` (`user_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储系统角色（超级管理员 / 普通管理员 / 运营管理员），支撑基于角色的权限控制（RBAC）。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role`
--

/*!40000 ALTER TABLE `role` DISABLE KEYS */;
INSERT INTO `role` VALUES (1,'个人用户',1,'USER',NULL,'2026-01-04 22:23:10','2026-01-04 22:23:10'),(2,'企业用户',2,'MERCHANT',NULL,'2026-01-04 22:23:10','2026-01-04 22:23:10'),(3,'管理员',3,'ADMIN',NULL,'2026-01-04 22:23:10','2026-01-04 22:23:10'),(4,'超级管理员',4,'SUPER_ADMIN',NULL,'2026-01-04 22:23:10','2026-01-04 22:23:10');
/*!40000 ALTER TABLE `role` ENABLE KEYS */;

--
-- Table structure for table `role_permission`
--

DROP TABLE IF EXISTS `role_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permission` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '关联记录唯一标识',
  `role_id` int NOT NULL COMMENT '关联role.role_id，角色删除时同步删除关联记录',
  `permission_id` int NOT NULL COMMENT '关联permission.permission_id，权限删除时同步删除关联记录',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '关联记录创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `role_id` (`role_id`,`permission_id`) USING BTREE,
  KEY `permission_id` (`permission_id`) USING BTREE,
  CONSTRAINT `role_permission_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `role_permission_ibfk_2` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`permission_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=921 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：RBAC 模型的中间表，实现角色与权限的多对多关联（如 “普通管理员” 关联 “商品审核”“订单查看” 权限）。\r\n备注：普通管理员不可关联 “超级管理员” 专属权限（如permission_code=“SYSTEM_CONFIG”），权限变更需超级管理员审批。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_permission`
--

/*!40000 ALTER TABLE `role_permission` DISABLE KEYS */;
INSERT INTO `role_permission` VALUES (351,4,42,'2026-10-15 04:58:29'),(352,4,89,'2026-10-15 04:58:29'),(353,4,90,'2026-10-15 04:58:29'),(354,4,91,'2026-10-15 04:58:29'),(355,4,92,'2026-10-15 04:58:29'),(356,4,93,'2026-10-15 04:58:29'),(357,4,94,'2026-10-15 04:58:29'),(358,4,95,'2026-10-15 04:58:29'),(359,4,96,'2026-10-15 04:58:29'),(360,4,97,'2026-10-15 04:58:29'),(361,4,98,'2026-10-15 04:58:29'),(362,4,99,'2026-10-15 04:58:29'),(363,4,100,'2026-10-15 04:58:29'),(364,4,101,'2026-10-15 04:58:29'),(365,4,102,'2026-10-15 04:58:29'),(366,4,103,'2026-10-15 04:58:29'),(367,4,104,'2026-10-15 04:58:29'),(368,4,105,'2026-10-15 04:58:29'),(369,4,106,'2026-10-15 04:58:29'),(370,4,107,'2026-10-15 04:58:29'),(371,4,108,'2026-10-15 04:58:29'),(372,4,109,'2026-10-15 04:58:29'),(373,4,110,'2026-10-15 04:58:29'),(374,4,111,'2026-10-15 04:58:29'),(375,4,112,'2026-10-15 04:58:29'),(376,4,113,'2026-10-15 04:58:29'),(377,4,114,'2026-10-15 04:58:29'),(378,4,115,'2026-10-15 04:58:29'),(379,4,116,'2026-10-15 04:58:29'),(380,4,117,'2026-10-15 04:58:29'),(381,4,118,'2026-10-15 04:58:29'),(382,4,119,'2026-10-15 04:58:29'),(383,4,120,'2026-10-15 04:58:29'),(384,4,121,'2026-10-15 04:58:29'),(385,4,122,'2026-10-15 04:58:29'),(386,4,123,'2026-10-15 04:58:29'),(387,4,124,'2026-10-15 04:58:29'),(388,4,125,'2026-10-15 04:58:29'),(389,4,126,'2026-10-15 04:58:29'),(390,4,127,'2026-10-15 04:58:29'),(391,4,128,'2026-10-15 04:58:29'),(392,4,129,'2026-10-15 04:58:29'),(393,4,132,'2026-10-15 04:58:29'),(394,1,136,'2026-10-15 05:13:01'),(395,1,176,'2026-10-15 05:13:01'),(396,1,134,'2026-10-15 05:13:01'),(397,1,139,'2026-10-15 05:13:01'),(398,1,135,'2026-10-15 05:13:01'),(399,1,144,'2026-10-15 05:13:01'),(400,1,174,'2026-10-15 05:13:01'),(401,1,140,'2026-10-15 05:13:01'),(402,1,175,'2026-10-15 05:13:01'),(403,1,170,'2026-10-15 05:13:01'),(404,1,145,'2026-10-15 05:13:01'),(405,1,167,'2026-10-15 05:13:01'),(406,1,143,'2026-10-15 05:13:01'),(407,1,151,'2026-10-15 05:13:01'),(408,1,152,'2026-10-15 05:13:01'),(409,1,162,'2026-10-15 05:13:01'),(410,1,164,'2026-10-15 05:13:01'),(411,1,148,'2026-10-15 05:13:01'),(412,1,147,'2026-10-15 05:13:01'),(413,1,153,'2026-10-15 05:13:01'),(414,1,157,'2026-10-15 05:13:01'),(415,1,168,'2026-10-15 05:13:01'),(416,1,161,'2026-10-15 05:13:01'),(417,1,138,'2026-10-15 05:13:01'),(418,1,133,'2026-10-15 05:13:01'),(419,1,155,'2026-10-15 05:13:01'),(420,1,169,'2026-10-15 05:13:01'),(421,1,149,'2026-10-15 05:13:01'),(422,1,137,'2026-10-15 05:13:01'),(423,1,172,'2026-10-15 05:13:01'),(424,1,171,'2026-10-15 05:13:01'),(425,1,156,'2026-10-15 05:13:01'),(426,1,166,'2026-10-15 05:13:01'),(427,1,142,'2026-10-15 05:13:01'),(428,1,173,'2026-10-15 05:13:01'),(429,1,154,'2026-10-15 05:13:01'),(430,1,160,'2026-10-15 05:13:01'),(431,1,177,'2026-10-15 05:13:01'),(432,1,150,'2026-10-15 05:13:01'),(433,1,146,'2026-10-15 05:13:01'),(434,1,165,'2026-10-15 05:13:01'),(435,1,163,'2026-10-15 05:13:01'),(436,1,159,'2026-10-15 05:13:01'),(437,1,141,'2026-10-15 05:13:01'),(438,1,158,'2026-10-15 05:13:01'),(457,2,183,'2026-10-15 05:13:01'),(458,2,136,'2026-10-15 05:13:01'),(459,2,202,'2026-10-15 05:13:01'),(460,2,176,'2026-10-15 05:13:01'),(461,2,203,'2026-10-15 05:13:01'),(462,2,134,'2026-10-15 05:13:01'),(463,2,207,'2026-10-15 05:13:01'),(464,2,201,'2026-10-15 05:13:01'),(465,2,209,'2026-10-15 05:13:01'),(466,2,139,'2026-10-15 05:13:01'),(467,2,135,'2026-10-15 05:13:01'),(468,2,144,'2026-10-15 05:13:01'),(469,2,174,'2026-10-15 05:13:01'),(470,2,189,'2026-10-15 05:13:01'),(471,2,188,'2026-10-15 05:13:01'),(472,2,182,'2026-10-15 05:13:01'),(473,2,140,'2026-10-15 05:13:01'),(474,2,175,'2026-10-15 05:13:01'),(475,2,170,'2026-10-15 05:13:01'),(476,2,145,'2026-10-15 05:13:01'),(477,2,167,'2026-10-15 05:13:01'),(478,2,143,'2026-10-15 05:13:01'),(479,2,179,'2026-10-15 05:13:01'),(480,2,151,'2026-10-15 05:13:01'),(481,2,152,'2026-10-15 05:13:01'),(482,2,162,'2026-10-15 05:13:01'),(483,2,191,'2026-10-15 05:13:01'),(484,2,192,'2026-10-15 05:13:01'),(485,2,214,'2026-10-15 05:13:01'),(486,2,178,'2026-10-15 05:13:01'),(487,2,180,'2026-10-15 05:13:01'),(488,2,218,'2026-10-15 05:13:01'),(489,2,190,'2026-10-15 05:13:01'),(490,2,194,'2026-10-15 05:13:01'),(491,2,197,'2026-10-15 05:13:01'),(492,2,195,'2026-10-15 05:13:01'),(493,2,210,'2026-10-15 05:13:01'),(494,2,164,'2026-10-15 05:13:01'),(495,2,212,'2026-10-15 05:13:01'),(496,2,148,'2026-10-15 05:13:01'),(497,2,147,'2026-10-15 05:13:01'),(498,2,153,'2026-10-15 05:13:01'),(499,2,199,'2026-10-15 05:13:01'),(500,2,157,'2026-10-15 05:13:01'),(501,2,205,'2026-10-15 05:13:01'),(502,2,168,'2026-10-15 05:13:01'),(503,2,161,'2026-10-15 05:13:01'),(504,2,186,'2026-10-15 05:13:01'),(505,2,138,'2026-10-15 05:13:01'),(506,2,211,'2026-10-15 05:13:01'),(507,2,185,'2026-10-15 05:13:01'),(508,2,133,'2026-10-15 05:13:01'),(509,2,184,'2026-10-15 05:13:01'),(510,2,206,'2026-10-15 05:13:01'),(511,2,200,'2026-10-15 05:13:01'),(512,2,155,'2026-10-15 05:13:01'),(513,2,169,'2026-10-15 05:13:01'),(514,2,149,'2026-10-15 05:13:01'),(515,2,137,'2026-10-15 05:13:01'),(516,2,172,'2026-10-15 05:13:01'),(517,2,171,'2026-10-15 05:13:01'),(518,2,156,'2026-10-15 05:13:01'),(519,2,166,'2026-10-15 05:13:01'),(520,2,204,'2026-10-15 05:13:01'),(521,2,142,'2026-10-15 05:13:01'),(522,2,173,'2026-10-15 05:13:01'),(523,2,154,'2026-10-15 05:13:01'),(524,2,160,'2026-10-15 05:13:01'),(525,2,177,'2026-10-15 05:13:01'),(526,2,150,'2026-10-15 05:13:01'),(527,2,146,'2026-10-15 05:13:01'),(528,2,165,'2026-10-15 05:13:01'),(529,2,216,'2026-10-15 05:13:01'),(530,2,163,'2026-10-15 05:13:01'),(531,2,159,'2026-10-15 05:13:01'),(532,2,213,'2026-10-15 05:13:01'),(533,2,193,'2026-10-15 05:13:01'),(534,2,187,'2026-10-15 05:13:01'),(535,2,181,'2026-10-15 05:13:01'),(536,2,215,'2026-10-15 05:13:01'),(537,2,141,'2026-10-15 05:13:01'),(538,2,198,'2026-10-15 05:13:01'),(539,2,208,'2026-10-15 05:13:01'),(540,2,196,'2026-10-15 05:13:01'),(541,2,158,'2026-10-15 05:13:01'),(542,2,217,'2026-10-15 05:13:01'),(591,2,260,'2026-10-15 05:18:12'),(874,3,89,'2026-10-15 05:35:10'),(875,3,90,'2026-10-15 05:35:10'),(876,3,91,'2026-10-15 05:35:10'),(877,3,92,'2026-10-15 05:35:10'),(878,3,93,'2026-10-15 05:35:10'),(879,3,94,'2026-10-15 05:35:10'),(880,3,95,'2026-10-15 05:35:10'),(881,3,96,'2026-10-15 05:35:10'),(882,3,97,'2026-10-15 05:35:10'),(883,3,98,'2026-10-15 05:35:10'),(884,3,99,'2026-10-15 05:35:10'),(885,3,100,'2026-10-15 05:35:10'),(886,3,101,'2026-10-15 05:35:10'),(887,3,102,'2026-10-15 05:35:10'),(888,3,103,'2026-10-15 05:35:10'),(889,3,104,'2026-10-15 05:35:10'),(890,3,105,'2026-10-15 05:35:10'),(891,3,106,'2026-10-15 05:35:10'),(892,3,107,'2026-10-15 05:35:10'),(893,3,108,'2026-10-15 05:35:10'),(894,3,109,'2026-10-15 05:35:10'),(895,3,110,'2026-10-15 05:35:10'),(896,3,111,'2026-10-15 05:35:10'),(897,3,112,'2026-10-15 05:35:10'),(898,3,113,'2026-10-15 05:35:10'),(899,3,114,'2026-10-15 05:35:10'),(900,3,115,'2026-10-15 05:35:10'),(901,3,116,'2026-10-15 05:35:10'),(902,3,117,'2026-10-15 05:35:10'),(903,3,118,'2026-10-15 05:35:10'),(904,3,119,'2026-10-15 05:35:10'),(905,3,120,'2026-10-15 05:35:10'),(906,3,121,'2026-10-15 05:35:10'),(907,3,122,'2026-10-15 05:35:10'),(908,3,123,'2026-10-15 05:35:10'),(909,3,124,'2026-10-15 05:35:10'),(910,3,125,'2026-10-15 05:35:10'),(911,3,126,'2026-10-15 05:35:10'),(912,3,128,'2026-10-15 05:35:10'),(913,3,131,'2026-10-15 05:35:10'),(914,3,132,'2026-10-15 05:35:10'),(915,3,219,'2026-10-15 05:35:10'),(916,3,220,'2026-10-15 05:35:10'),(917,3,221,'2026-10-15 05:35:10'),(918,3,222,'2026-10-15 05:35:10'),(919,3,223,'2026-10-15 05:35:10'),(920,3,224,'2026-10-15 05:35:10');
/*!40000 ALTER TABLE `role_permission` ENABLE KEYS */;

--
-- Table structure for table `second_hand`
--

DROP TABLE IF EXISTS `second_hand`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `second_hand` (
  `sh_id` bigint NOT NULL AUTO_INCREMENT COMMENT '二手记录唯一标识',
  `product_id` bigint NOT NULL COMMENT '关联product.product_id，商品删除时同步删除二手记录',
  `quality_report` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '第三方质检报告路径（如 “/report/sh123.pdf”）',
  `used_time` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '使用时长（如 “3 个月”“1 年”）',
  `defect_desc` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '瑕疵描述（如 “镜头边缘轻微划痕，不影响成像”）',
  `defect_img` json DEFAULT NULL COMMENT '瑕疵图片路径（JSON 数组，无瑕疵则为空）',
  `seller_type` tinyint NOT NULL COMMENT '卖家类型：1 - 个人闲置，2 - 企业商家（优先展示个人闲置）',
  `negotiate_status` tinyint NOT NULL DEFAULT '0' COMMENT '议价状态：0 - 未议价，1 - 议价中，2 - 议价达成，3 - 议价失败',
  `final_price` decimal(12,2) DEFAULT NULL COMMENT '议价最终价格（无议价则与product.price一致）',
  `parameters` json DEFAULT NULL COMMENT '专业参数（JSON格式）',
  `warranty_info` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '保修信息',
  `img_urls` json DEFAULT NULL COMMENT '器材实拍图路径（JSON数组）',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '商品描述',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '二手记录创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '二手信息更新时间',
  `repair_history` tinyint NOT NULL DEFAULT '0' COMMENT '维修记录：0-无维修记录，1-有维修记录',
  `accessories` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '配件清单（如电池、充电器、说明书等）',
  PRIMARY KEY (`sh_id`) USING BTREE,
  UNIQUE KEY `product_id` (`product_id`) USING BTREE,
  KEY `used_time` (`used_time`,`seller_type`,`negotiate_status`) USING BTREE,
  CONSTRAINT `second_hand_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储二手器材的专属信息（质检报告、使用记录等），与product一对一关联（仅product_type=2时存在）。\r\n备注：禁止发布 “翻新机”“拼装机”，违规则product.audit_status=2且永久封禁seller_id对应的账号。\r\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `second_hand`
--

/*!40000 ALTER TABLE `second_hand` DISABLE KEYS */;
INSERT INTO `second_hand` VALUES (1,4,NULL,'5年',NULL,NULL,2,0,NULL,'{\"类型\": \"可换镜头数码相机\", \"总像素数\": \"约2,528万\", \"有效像素\": \"约2450万\", \"镜头卡口\": \"尼康F卡口\", \"传感器尺寸\": \"约35.9 mm x 23.9mm\", \"影像传感器类型\": \"FX\"}','','[\"/uploads/seed/D850_2.png\", \"/uploads/seed/D850_1.png\", \"/uploads/seed/D850_3.png\"]','单反时代的末代机皇','2026-10-15 03:42:34','2026-10-15 03:42:34',0,NULL),(2,5,'验机报告 #0005','约 1 年','机身底部有轻微使用痕迹，快门、对焦、防抖功能正常，无拆修记录。','[]',2,0,NULL,'{\"成色\": \"95新\", \"验机\": \"平台验机通过\", \"库存形态\": \"单件在售\"}','平台质检后 7 天内可退','[]','个人自用 Z6，95新，无暗病，可当面验机。','2026-10-15 03:44:15','2026-10-15 03:44:15',0,'原装电池、充电器、背带'),(3,22,'验机报告 #0022','约 2 年','机身有正常使用磨损，屏幕贴膜下有细微划痕，功能全部正常。','[]',2,0,NULL,'{\"成色\": \"90新\", \"验机\": \"平台验机通过\", \"库存形态\": \"单件在售\"}','平台质检后 7 天内可退','[]','个人自用 Z72，90新，无暗病，可当面验机。','2026-10-15 03:44:15','2026-10-15 03:44:15',0,'原装电池、充电器、背带'),(4,26,'验机报告 #0026','约 2 年','机身有正常使用磨损，屏幕贴膜下有细微划痕，功能全部正常。','[]',2,0,NULL,'{\"成色\": \"90新\", \"验机\": \"平台验机通过\", \"库存形态\": \"单件在售\"}','平台质检后 7 天内可退','[]','个人自用 EOS R5 Mark II，90新，无暗病，可当面验机。','2026-10-15 03:44:15','2026-10-15 03:44:15',0,'原装电池、充电器、背带'),(5,30,'验机报告 #0030','约 2 年','机身有正常使用磨损，屏幕贴膜下有细微划痕，功能全部正常。','[]',2,0,NULL,'{\"成色\": \"90新\", \"验机\": \"平台验机通过\", \"库存形态\": \"单件在售\"}','平台质检后 7 天内可退','[]','个人自用 ACTION 4，90新，无暗病，可当面验机。','2026-10-15 03:44:15','2026-10-15 03:44:15',0,'原装电池、充电器、背带');
/*!40000 ALTER TABLE `second_hand` ENABLE KEYS */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_second_hand_illegal_ban` AFTER UPDATE ON `second_hand` FOR EACH ROW BEGIN
    DECLARE v_audit_status INT;
    DECLARE v_reject_reason VARCHAR(255);
    DECLARE v_seller_id INT;

    
    SELECT p.audit_status, p.reject_reason, p.seller_id
    INTO v_audit_status, v_reject_reason, v_seller_id
    FROM product p
    WHERE p.product_id = NEW.product_id;

    
    IF v_audit_status = 2
    AND (v_reject_reason LIKE '%翻新机%' OR v_reject_reason LIKE '%拼装机%') THEN
        
        UPDATE user
        SET status = 0,
            update_time = CURRENT_TIMESTAMP
        WHERE user_id = v_seller_id;

        
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
            3, 
            CURRENT_TIMESTAMP,
            0
        );
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sku`
--

DROP TABLE IF EXISTS `sku`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sku` (
  `sku_id` bigint NOT NULL AUTO_INCREMENT COMMENT 'SKU ID',
  `product_id` bigint NOT NULL COMMENT '商品ID',
  `sku_attribute` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'SKU属性',
  `sku_value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'SKU值',
  `price` decimal(12,2) NOT NULL COMMENT 'SKU价格',
  `stock` int NOT NULL COMMENT 'SKU库存',
  `min_stock` int NOT NULL DEFAULT '10' COMMENT 'SKU安全库存',
  `sales` int NOT NULL DEFAULT '0' COMMENT 'SKU销量',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`sku_id`) USING BTREE,
  UNIQUE KEY `uk_product_attr_value` (`product_id`,`sku_attribute`,`sku_value`),
  KEY `idx_product_id` (`product_id`) USING BTREE,
  KEY `idx_sku_attribute` (`sku_attribute`) USING BTREE,
  KEY `idx_sku_value` (`sku_value`) USING BTREE,
  CONSTRAINT `fk_sku_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='SKU表，存储商品的库存单位信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sku`
--

/*!40000 ALTER TABLE `sku` DISABLE KEYS */;
INSERT INTO `sku` VALUES (1,1,'颜色','黑色',0.00,77,10,120,'2026-02-09 19:38:53','2026-02-09 19:38:53'),(2,2,'版本','国行',0.00,9,10,95,'2026-02-09 19:38:53','2026-02-09 19:38:53'),(3,3,'套餐','单机',0.00,99,10,88,'2026-02-09 19:38:53','2026-02-09 19:38:53'),(4,4,'成色','85新',5555.00,4,5,45,'2026-02-09 19:38:53','2026-02-09 19:56:17'),(5,5,'成色','90新',0.00,9,10,67,'2026-02-09 19:38:53','2026-02-09 19:38:53'),(6,6,'状态','可租',0.00,4,5,32,'2026-02-09 19:38:53','2026-02-09 19:38:53'),(7,7,'状态','可租',0.00,11,20,56,'2026-02-09 19:38:53','2026-02-09 19:38:53'),(8,4,'成色','8新',5000.00,7,10,0,'2026-02-09 19:55:29','2026-02-09 19:55:29'),(9,23,'黑色','BLACK',13999.00,200,10,0,'2026-04-08 21:19:25','2026-04-08 21:19:25'),(10,23,'白','W',13999.00,199,10,0,'2026-04-08 21:20:06','2026-04-08 21:20:06'),(11,8,'默认','默认',18999.00,88,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(12,15,'默认','默认',15999.00,88,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(13,20,'默认','默认',18888.00,8555,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(14,21,'默认','默认',14999.00,220,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(15,22,'默认','默认',9999.00,72,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(16,24,'默认','默认',14449.00,-137,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(17,25,'默认','默认',3299.00,90,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(18,26,'默认','默认',9999.00,88,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(19,27,'默认','默认',1499.00,200,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(20,28,'默认','默认',22999.00,99,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(21,29,'默认','默认',18999.00,99,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(22,30,'默认','默认',999.00,0,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(23,31,'默认','默认',2899.00,22,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(24,32,'默认','默认',18999.00,82,10,0,'2026-04-11 01:25:09','2026-04-11 01:25:09'),(26,33,'默认','默认',109.00,2,10,0,'2026-04-11 01:30:41','2026-04-11 01:30:41'),(27,34,'默认','默认',56.00,66,10,0,'2026-04-11 01:32:44','2026-04-11 01:32:44'),(28,35,'默认','默认',80.00,3,10,0,'2026-04-11 01:34:24','2026-04-11 01:34:24'),(29,36,'默认','默认',90.00,50,10,0,'2026-04-11 01:37:35','2026-04-11 01:37:35'),(30,37,'默认','默认',32.00,88,10,0,'2026-04-11 01:40:28','2026-04-11 01:40:28'),(31,38,'默认','默认',150.00,88,10,0,'2026-04-11 01:41:35','2026-04-11 01:41:35'),(32,39,'默认','默认',20.00,5555,10,0,'2026-04-11 01:42:46','2026-04-11 01:42:46'),(33,40,'默认','默认',70.00,63,10,0,'2026-04-11 01:44:45','2026-04-11 01:44:45'),(34,41,'默认','默认',40.00,11,10,0,'2026-04-11 01:47:17','2026-04-11 01:47:17'),(35,42,'默认','默认',21.00,55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(36,43,'默认','默认',21.00,55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(37,44,'默认','默认',2000.00,55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(38,45,'默认','默认',29.00,66,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(39,46,'默认','默认',1599.00,55,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36'),(40,47,'默认','默认',12999.00,22,10,0,'2026-10-15 05:18:36','2026-10-15 05:18:36');
/*!40000 ALTER TABLE `sku` ENABLE KEYS */;

--
-- Table structure for table `sys_image`
--

DROP TABLE IF EXISTS `sys_image`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_image` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `image_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '图片自定义名称',
  `original_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '图片原始文件名（如test.jpg）',
  `storage_path` varchar(512) NOT NULL COMMENT '对外访问 URL，如 /uploads/2026/10/ab12.png',
  `storage_key` varchar(255) DEFAULT NULL COMMENT '相对存储根目录的键，如 2026/10/ab12.png',
  `file_size` bigint DEFAULT NULL COMMENT '字节；历史回填数据可能为 NULL',
  `file_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '文件类型（如jpg/png/webp）',
  `width` int DEFAULT NULL COMMENT '图片宽度（px）',
  `height` int DEFAULT NULL COMMENT '图片高度（px）',
  `upload_user_id` bigint DEFAULT NULL COMMENT '上传人ID',
  `upload_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `business_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT '业务类型（product：商品图；banner：轮播图）',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '逻辑删除：0 正常 1 已删',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `sys_image_ibfk_1` (`upload_user_id`) USING BTREE,
  KEY `idx_biz_user` (`business_type`,`upload_user_id`),
  KEY `idx_storage_path` (`storage_path`),
  CONSTRAINT `sys_image_ibfk_1` FOREIGN KEY (`upload_user_id`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=146 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='存储所有图片的基础信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_image`
--

/*!40000 ALTER TABLE `sys_image` DISABLE KEYS */;
INSERT INTO `sys_image` VALUES (1,'Z62','Z62_1','/uploads/seed/Z62_1.png','seed/Z62_1.png',519881,'png',NULL,NULL,NULL,'2025-12-18 22:56:57','product',0),(2,'Z 24-120 F4S','Z 24-120 F4S_1','/uploads/seed/Z 24-120 F4S.png','seed/Z 24-120 F4S.png',441389,'png',NULL,NULL,NULL,'2025-12-20 17:04:31','product',0),(3,'A7R5','A7R5_1','/uploads/seed/A7R5.png','seed/A7R5.png',205298,'png',NULL,NULL,NULL,'2025-12-20 17:13:38','product',0),(4,'D850','D850_1','/uploads/seed/D850_1.png','seed/D850_1.png',126235,'png',NULL,NULL,NULL,'2025-12-27 17:16:45','product',0),(5,'Z6','Z6_1','/uploads/seed/Z6_1.png','seed/Z6_1.png',392002,'png',NULL,NULL,NULL,'2025-12-27 18:57:46','product',0),(6,'ZR','ZR_1','/uploads/seed/ZR_1.png','seed/ZR_1.png',563911,'png',NULL,NULL,NULL,'2025-12-28 18:26:25','product',0),(7,'Z 70-200mm f2.8 VR S','Z 70-200mm f2.8 VR S_1','/uploads/seed/Z 70-200mm f2.8 VR S_1.png','seed/Z 70-200mm f2.8 VR S_1.png',247594,'png',NULL,NULL,NULL,'2025-12-28 18:27:27','product',0),(38,'z8','image copy 3.png','/uploads/seed/ee2d0a66e4844750abc1238cf6773e9a.png','seed/ee2d0a66e4844750abc1238cf6773e9a.png',409989,'png',NULL,NULL,NULL,'2026-02-09 22:22:44','product',0),(39,NULL,'image.png','/uploads/seed/661e6ec68d3f4fb09728b434e0ed8dcd.png','seed/661e6ec68d3f4fb09728b434e0ed8dcd.png',408839,'image/png',NULL,NULL,NULL,'2026-02-09 22:46:47','product',0),(40,NULL,'image.png','/uploads/seed/cda9743e83854f6ab180a7d19a97afa7.png','seed/cda9743e83854f6ab180a7d19a97afa7.png',251325,'image/png',NULL,NULL,NULL,'2026-02-09 22:55:49','product',0),(41,NULL,'image.png','/uploads/seed/ac556fd1cf9b4cb1abfe283875a71b70.png','seed/ac556fd1cf9b4cb1abfe283875a71b70.png',251325,'image/png',NULL,NULL,NULL,'2026-02-09 23:40:24','product',0),(42,NULL,'image copy 2.png','/uploads/seed/bd47415b483848669345f762129938cf.png','seed/bd47415b483848669345f762129938cf.png',349819,'image/png',NULL,NULL,NULL,'2026-02-10 00:41:26','product',0),(43,NULL,'image.png','/uploads/seed/d12bf2e4e70f45928697a62bd20c80f8.png','seed/d12bf2e4e70f45928697a62bd20c80f8.png',563911,'image/png',NULL,NULL,NULL,'2026-02-10 00:43:16','product',0),(44,NULL,'image copy 2.png','/uploads/seed/06d51035f6d740edbb5769dc83eadd5e.png','seed/06d51035f6d740edbb5769dc83eadd5e.png',466436,'image/png',NULL,NULL,NULL,'2026-02-10 00:43:43','product',0),(45,NULL,'image copy 5.png','/uploads/seed/b1145ce27105475daab729bd2c044435.png','seed/b1145ce27105475daab729bd2c044435.png',453101,'image/png',NULL,NULL,NULL,'2026-02-10 00:51:39','product',0),(46,NULL,'image copy 2.png','/uploads/seed/6bd2429655c3436a9f3eb6047feaecd5.png','seed/6bd2429655c3436a9f3eb6047feaecd5.png',552445,'image/png',NULL,NULL,NULL,'2026-02-10 00:51:45','product',0),(47,NULL,'image copy 3.png','/uploads/seed/910b881ab68c4e38868df32553b1a270.png','seed/910b881ab68c4e38868df32553b1a270.png',503298,'image/png',NULL,NULL,NULL,'2026-02-10 00:51:48','product',0),(48,NULL,'image copy 4.png','/uploads/seed/2ce390ab01aa454fabb8c9d89f47c09b.png','seed/2ce390ab01aa454fabb8c9d89f47c09b.png',336401,'image/png',NULL,NULL,NULL,'2026-02-10 00:51:51','product',0),(49,NULL,'image.png','/uploads/seed/c5ea913d6c4f4b719992f595108073f5.png','seed/c5ea913d6c4f4b719992f595108073f5.png',324172,'image/png',NULL,NULL,NULL,'2026-03-08 01:34:32','product',0),(50,NULL,'image copy.png','/uploads/seed/52d572ee89a4443a849eb60955eb05ba.png','seed/52d572ee89a4443a849eb60955eb05ba.png',323591,'image/png',NULL,NULL,NULL,'2026-03-08 01:34:36','product',0),(51,NULL,'image copy 3.png','/uploads/seed/3ddfc3964aa34b4e98768fa7b91ba22c.png','seed/3ddfc3964aa34b4e98768fa7b91ba22c.png',409989,'image/png',NULL,NULL,NULL,'2026-03-08 01:52:53','product',0),(52,NULL,'image copy 5.png','/uploads/seed/8e59174ed13b4eec923021a2c6e91c24.png','seed/8e59174ed13b4eec923021a2c6e91c24.png',347919,'image/png',NULL,NULL,NULL,'2026-03-08 01:53:04','product',0),(53,NULL,'image copy.png','/uploads/seed/731841eab6f44f25a7012ad738aaf254.png','seed/731841eab6f44f25a7012ad738aaf254.png',462580,'image/png',NULL,NULL,NULL,'2026-03-08 01:53:33','product',0),(54,NULL,'image copy 3.png','/uploads/seed/3b887786a8de438a867649223fcb4389.png','seed/3b887786a8de438a867649223fcb4389.png',409989,'image/png',NULL,NULL,NULL,'2026-03-08 01:53:38','product',0),(55,NULL,'image copy 4.png','/uploads/seed/a005143dadc14798af03a344229cca26.png','seed/a005143dadc14798af03a344229cca26.png',390828,'image/png',NULL,NULL,NULL,'2026-03-08 01:53:50','product',0),(56,NULL,'image copy 2.png','/uploads/seed/7085b9abc95849de855aa2e7e2365a2a.png','seed/7085b9abc95849de855aa2e7e2365a2a.png',375089,'image/png',NULL,NULL,NULL,'2026-04-10 22:30:42','product',0),(57,NULL,'image.png','/uploads/seed/dbbd8f3903924bb6b8c188467ae42574.png','seed/dbbd8f3903924bb6b8c188467ae42574.png',328283,'image/png',NULL,NULL,NULL,'2026-04-10 22:30:47','product',0),(58,NULL,'image.png','/uploads/seed/59f76d18f65a49c7937b7d3736afb037.png','seed/59f76d18f65a49c7937b7d3736afb037.png',787769,'image/png',NULL,NULL,NULL,'2026-04-10 22:39:50','product',0),(59,NULL,'image copy.png','/uploads/seed/5ad51b941ccc432fac17b738b51664a6.png','seed/5ad51b941ccc432fac17b738b51664a6.png',867345,'image/png',NULL,NULL,NULL,'2026-04-10 22:39:54','product',0),(60,NULL,'image copy 4.png','/uploads/seed/300d0b01b0384218941799908a1276bd.png','seed/300d0b01b0384218941799908a1276bd.png',334883,'image/png',NULL,NULL,NULL,'2026-04-10 22:46:03','product',0),(61,NULL,'image copy 2.png','/uploads/seed/430f57fce15f41b18ab35511c2880521.png','seed/430f57fce15f41b18ab35511c2880521.png',479712,'image/png',NULL,NULL,NULL,'2026-04-10 22:46:08','product',0),(62,NULL,'image.png','/uploads/seed/05a7dc58042446a3912f50a3cc9d047d.png','seed/05a7dc58042446a3912f50a3cc9d047d.png',209936,'image/png',NULL,NULL,NULL,'2026-04-10 22:48:55','product',0),(63,NULL,'image copy.png','/uploads/seed/952d5911e845479cb1ba3072eb420219.png','seed/952d5911e845479cb1ba3072eb420219.png',204181,'image/png',NULL,NULL,NULL,'2026-04-10 22:48:59','product',0),(64,NULL,'image copy 3.png','/uploads/seed/d77ea52193414947b1133a640b00fe91.png','seed/d77ea52193414947b1133a640b00fe91.png',783316,'image/png',NULL,NULL,NULL,'2026-04-10 23:05:16','product',0),(65,NULL,'image.png','/uploads/seed/00170959838740d1ad2e5e8f1ef3bb5b.png','seed/00170959838740d1ad2e5e8f1ef3bb5b.png',2767546,'image/png',NULL,NULL,NULL,'2026-04-10 23:10:46','product',0),(66,NULL,'image copy.png','/uploads/seed/19dae3d4911147f6a9f907ad0070f639.png','seed/19dae3d4911147f6a9f907ad0070f639.png',265578,'image/png',NULL,NULL,NULL,'2026-04-10 23:35:59','product',0),(67,NULL,'image.png','/uploads/seed/fc0ee5a8bc2c456aa7b4e8d9d68ab0ea.png','seed/fc0ee5a8bc2c456aa7b4e8d9d68ab0ea.png',259041,'image/png',NULL,NULL,NULL,'2026-04-11 01:30:13','product',0),(68,NULL,'image copy.png','/uploads/seed/7fd64253bfcf4698b133316df2cdda8e.png','seed/7fd64253bfcf4698b133316df2cdda8e.png',193442,'image/png',NULL,NULL,NULL,'2026-04-11 01:32:20','product',0),(69,NULL,'image copy 3.png','/uploads/seed/3d1dd6799f004f928ffaed8687a0c8ae.png','seed/3d1dd6799f004f928ffaed8687a0c8ae.png',182052,'image/png',NULL,NULL,NULL,'2026-04-11 01:32:26','product',0),(70,NULL,'image.png','/uploads/seed/459d8113fe2a49d6be48352176d6e277.png','seed/459d8113fe2a49d6be48352176d6e277.png',251325,'image/png',NULL,NULL,NULL,'2026-04-11 01:34:08','product',0),(71,NULL,'image.png','/uploads/seed/3d433a2c80b9471ea9dd30b2ec637710.png','seed/3d433a2c80b9471ea9dd30b2ec637710.png',193991,'image/png',NULL,NULL,NULL,'2026-04-11 01:37:10','product',0),(72,NULL,'image copy 2.png','/uploads/seed/24e668afd9de4e2db4ee14ae9ae5049d.png','seed/24e668afd9de4e2db4ee14ae9ae5049d.png',414015,'image/png',NULL,NULL,NULL,'2026-04-11 01:40:12','product',0),(73,NULL,'image copy 2.png','/uploads/seed/a8df6409afac400b81ef80f6c4a62374.png','seed/a8df6409afac400b81ef80f6c4a62374.png',479712,'image/png',NULL,NULL,NULL,'2026-04-11 01:41:12','product',0),(74,NULL,'image.png','/uploads/seed/acf67e5d43ee45138555618b70afa5dd.png','seed/acf67e5d43ee45138555618b70afa5dd.png',100787,'image/png',NULL,NULL,NULL,'2026-04-11 01:42:20','product',0),(75,NULL,'image copy 2.png','/uploads/seed/2fd8e973dd5447d1947d9983ea87ce20.png','seed/2fd8e973dd5447d1947d9983ea87ce20.png',552445,'image/png',NULL,NULL,NULL,'2026-04-11 01:44:26','product',0),(76,NULL,'image copy 2.png','/uploads/seed/3fa0a908d12f4006b58941aee0883324.png','seed/3fa0a908d12f4006b58941aee0883324.png',318380,'image/png',NULL,NULL,NULL,'2026-04-11 01:46:49','product',0),(77,NULL,'image copy 2.png','/uploads/seed/ad3aba846fc5463eadb918ece9e2217c.png','seed/ad3aba846fc5463eadb918ece9e2217c.png',713892,'image/png',NULL,NULL,NULL,'2026-04-11 02:09:33','product',0),(78,NULL,'image copy 2.png','/uploads/seed/43bfac6b609446638a0556e291c3738c.png','seed/43bfac6b609446638a0556e291c3738c.png',713892,'image/png',NULL,NULL,NULL,'2026-04-11 02:10:38','product',0),(79,NULL,'image copy 2.png','/uploads/seed/26092a1a5b9843d19d79da3ae1663c1c.png','seed/26092a1a5b9843d19d79da3ae1663c1c.png',713892,'image/png',NULL,NULL,NULL,'2026-04-11 02:15:09','product',0),(80,NULL,'image copy 2.png','/uploads/seed/31dd7312ff224dbbb2ec3410f8bbf367.png','seed/31dd7312ff224dbbb2ec3410f8bbf367.png',713892,'image/png',NULL,NULL,NULL,'2026-04-11 02:30:37','product',0),(81,NULL,'image copy 2.png','/uploads/seed/aea993f8f98f4d75a4831b23de9330ab.png','seed/aea993f8f98f4d75a4831b23de9330ab.png',466436,'image/png',NULL,NULL,NULL,'2026-04-11 11:04:09','product',0),(82,'04953aa3-09d4-420b-970b-29ebd4ce31f1.JPG','04953aa3-09d4-420b-970b-29ebd4ce31f1.JPG','/uploads/avatar/04953aa3-09d4-420b-970b-29ebd4ce31f1.JPG','avatar/04953aa3-09d4-420b-970b-29ebd4ce31f1.JPG',40700,'image/jpeg',640,586,NULL,'2026-10-15 03:42:52','avatar',0),(83,'06b3cdf7-de50-4c66-9b5c-79546fddac1f.png','06b3cdf7-de50-4c66-9b5c-79546fddac1f.png','/uploads/avatar/06b3cdf7-de50-4c66-9b5c-79546fddac1f.png','avatar/06b3cdf7-de50-4c66-9b5c-79546fddac1f.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','avatar',0),(84,'44989500-ec1a-4be6-a742-c9bd3880cf39.JPG','44989500-ec1a-4be6-a742-c9bd3880cf39.JPG','/uploads/avatar/44989500-ec1a-4be6-a742-c9bd3880cf39.JPG','avatar/44989500-ec1a-4be6-a742-c9bd3880cf39.JPG',17487,'image/jpeg',640,594,NULL,'2026-10-15 03:42:52','avatar',0),(85,'460513ea-22e2-449f-bfe6-f8c84fd4b122.JPEG','460513ea-22e2-449f-bfe6-f8c84fd4b122.JPEG','/uploads/avatar/460513ea-22e2-449f-bfe6-f8c84fd4b122.JPEG','avatar/460513ea-22e2-449f-bfe6-f8c84fd4b122.JPEG',21145,'image/jpeg',480,480,NULL,'2026-10-15 03:42:52','avatar',0),(86,'4e9b668a-9f84-4818-b03b-267f573f1be4.jpg','4e9b668a-9f84-4818-b03b-267f573f1be4.jpg','/uploads/avatar/4e9b668a-9f84-4818-b03b-267f573f1be4.jpg','avatar/4e9b668a-9f84-4818-b03b-267f573f1be4.jpg',45898,'image/jpeg',1080,1080,NULL,'2026-10-15 03:42:52','avatar',0),(87,'a67be7dc-81e6-4d93-8f3d-c019fa237e3d.jpg','a67be7dc-81e6-4d93-8f3d-c019fa237e3d.jpg','/uploads/avatar/a67be7dc-81e6-4d93-8f3d-c019fa237e3d.jpg','avatar/a67be7dc-81e6-4d93-8f3d-c019fa237e3d.jpg',325627,'image/jpeg',1080,2339,NULL,'2026-10-15 03:42:52','avatar',0),(88,'shop_58711c1b-1b43-4275-84d3-5ca6248828a1.png','shop_58711c1b-1b43-4275-84d3-5ca6248828a1.png','/uploads/avatar/shop_58711c1b-1b43-4275-84d3-5ca6248828a1.png','avatar/shop_58711c1b-1b43-4275-84d3-5ca6248828a1.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_logo',0),(89,'shop_96af7a46-e549-4fbf-8452-419d93a08b2e.png','shop_96af7a46-e549-4fbf-8452-419d93a08b2e.png','/uploads/avatar/shop_96af7a46-e549-4fbf-8452-419d93a08b2e.png','avatar/shop_96af7a46-e549-4fbf-8452-419d93a08b2e.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_logo',0),(90,'auth_18_40900845-4802-42f9-9288-ff85d95a7009.png','auth_18_40900845-4802-42f9-9288-ff85d95a7009.png','/uploads/auth/auth_18_40900845-4802-42f9-9288-ff85d95a7009.png','auth/auth_18_40900845-4802-42f9-9288-ff85d95a7009.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(91,'auth_18_45a769f9-2a23-4be6-8e6b-508cb127861d.png','auth_18_45a769f9-2a23-4be6-8e6b-508cb127861d.png','/uploads/auth/auth_18_45a769f9-2a23-4be6-8e6b-508cb127861d.png','auth/auth_18_45a769f9-2a23-4be6-8e6b-508cb127861d.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(92,'auth_18_6510ae5f-f1da-4317-9172-6684d45fc091.png','auth_18_6510ae5f-f1da-4317-9172-6684d45fc091.png','/uploads/auth/auth_18_6510ae5f-f1da-4317-9172-6684d45fc091.png','auth/auth_18_6510ae5f-f1da-4317-9172-6684d45fc091.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(93,'auth_18_6cc106e7-16af-4512-bc86-89332ae048eb.png','auth_18_6cc106e7-16af-4512-bc86-89332ae048eb.png','/uploads/auth/auth_18_6cc106e7-16af-4512-bc86-89332ae048eb.png','auth/auth_18_6cc106e7-16af-4512-bc86-89332ae048eb.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(94,'auth_19_1407ca17-25fc-424c-b525-341fea93bb2b.png','auth_19_1407ca17-25fc-424c-b525-341fea93bb2b.png','/uploads/auth/auth_19_1407ca17-25fc-424c-b525-341fea93bb2b.png','auth/auth_19_1407ca17-25fc-424c-b525-341fea93bb2b.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(95,'auth_19_37a72686-60b1-438b-9627-65eea33748c4.png','auth_19_37a72686-60b1-438b-9627-65eea33748c4.png','/uploads/auth/auth_19_37a72686-60b1-438b-9627-65eea33748c4.png','auth/auth_19_37a72686-60b1-438b-9627-65eea33748c4.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(96,'auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png','auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png','/uploads/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png','auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(97,'auth_19_a6367c0a-31fe-46ea-943d-11a026eb4355.png','auth_19_a6367c0a-31fe-46ea-943d-11a026eb4355.png','/uploads/auth/auth_19_a6367c0a-31fe-46ea-943d-11a026eb4355.png','auth/auth_19_a6367c0a-31fe-46ea-943d-11a026eb4355.png',347919,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(98,'auth_19_e6e0010a-f4d7-4df2-867c-e065c6377cc8.png','auth_19_e6e0010a-f4d7-4df2-867c-e065c6377cc8.png','/uploads/auth/auth_19_e6e0010a-f4d7-4df2-867c-e065c6377cc8.png','auth/auth_19_e6e0010a-f4d7-4df2-867c-e065c6377cc8.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(99,'auth_19_e86e1ef7-60c3-43ee-a473-dbc1ee60f922.png','auth_19_e86e1ef7-60c3-43ee-a473-dbc1ee60f922.png','/uploads/auth/auth_19_e86e1ef7-60c3-43ee-a473-dbc1ee60f922.png','auth/auth_19_e86e1ef7-60c3-43ee-a473-dbc1ee60f922.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(100,'auth_21_1fa8d31f-8307-4643-8f2e-4812107d5e6a.png','auth_21_1fa8d31f-8307-4643-8f2e-4812107d5e6a.png','/uploads/auth/auth_21_1fa8d31f-8307-4643-8f2e-4812107d5e6a.png','auth/auth_21_1fa8d31f-8307-4643-8f2e-4812107d5e6a.png',71467,'image/png',577,447,NULL,'2026-10-15 03:42:52','shop_auth',0),(101,'auth_21_3e70886e-69db-4151-9a16-e095e87fb106.png','auth_21_3e70886e-69db-4151-9a16-e095e87fb106.png','/uploads/auth/auth_21_3e70886e-69db-4151-9a16-e095e87fb106.png','auth/auth_21_3e70886e-69db-4151-9a16-e095e87fb106.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(102,'auth_21_4a6dcafb-e676-4033-8eb0-85a2b2549ee2.png','auth_21_4a6dcafb-e676-4033-8eb0-85a2b2549ee2.png','/uploads/auth/auth_21_4a6dcafb-e676-4033-8eb0-85a2b2549ee2.png','auth/auth_21_4a6dcafb-e676-4033-8eb0-85a2b2549ee2.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(103,'auth_21_6ff9c130-75c9-41fe-9dd3-63492b6b9fb4.png','auth_21_6ff9c130-75c9-41fe-9dd3-63492b6b9fb4.png','/uploads/auth/auth_21_6ff9c130-75c9-41fe-9dd3-63492b6b9fb4.png','auth/auth_21_6ff9c130-75c9-41fe-9dd3-63492b6b9fb4.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(104,'auth_21_88f42df8-0740-49ea-a076-8759bf913786.png','auth_21_88f42df8-0740-49ea-a076-8759bf913786.png','/uploads/auth/auth_21_88f42df8-0740-49ea-a076-8759bf913786.png','auth/auth_21_88f42df8-0740-49ea-a076-8759bf913786.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(105,'auth_21_8bce9962-4985-4d47-b1cd-c03e8b0e34f3.png','auth_21_8bce9962-4985-4d47-b1cd-c03e8b0e34f3.png','/uploads/auth/auth_21_8bce9962-4985-4d47-b1cd-c03e8b0e34f3.png','auth/auth_21_8bce9962-4985-4d47-b1cd-c03e8b0e34f3.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(106,'auth_21_9d878919-d212-44b3-869b-24e863bca205.png','auth_21_9d878919-d212-44b3-869b-24e863bca205.png','/uploads/auth/auth_21_9d878919-d212-44b3-869b-24e863bca205.png','auth/auth_21_9d878919-d212-44b3-869b-24e863bca205.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(107,'auth_21_b931fcfc-a8c7-451a-ba8b-23385c4f59b5.png','auth_21_b931fcfc-a8c7-451a-ba8b-23385c4f59b5.png','/uploads/auth/auth_21_b931fcfc-a8c7-451a-ba8b-23385c4f59b5.png','auth/auth_21_b931fcfc-a8c7-451a-ba8b-23385c4f59b5.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(108,'auth_21_bc8e8060-6dbf-4b81-aa08-9f77209b9c34.png','auth_21_bc8e8060-6dbf-4b81-aa08-9f77209b9c34.png','/uploads/auth/auth_21_bc8e8060-6dbf-4b81-aa08-9f77209b9c34.png','auth/auth_21_bc8e8060-6dbf-4b81-aa08-9f77209b9c34.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(109,'auth_21_c9443447-5f4d-451d-b53f-70234055ab05.png','auth_21_c9443447-5f4d-451d-b53f-70234055ab05.png','/uploads/auth/auth_21_c9443447-5f4d-451d-b53f-70234055ab05.png','auth/auth_21_c9443447-5f4d-451d-b53f-70234055ab05.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(110,'auth_21_e94086c6-c7ce-41fd-a0ed-e23cd21e30cb.png','auth_21_e94086c6-c7ce-41fd-a0ed-e23cd21e30cb.png','/uploads/auth/auth_21_e94086c6-c7ce-41fd-a0ed-e23cd21e30cb.png','auth/auth_21_e94086c6-c7ce-41fd-a0ed-e23cd21e30cb.png',811302,'image/png',643,811,NULL,'2026-10-15 03:42:52','shop_auth',0),(111,'auth_8_248beae1-4868-450a-96ce-9b84b1c3d3e4.png','auth_8_248beae1-4868-450a-96ce-9b84b1c3d3e4.png','/uploads/auth/auth_8_248beae1-4868-450a-96ce-9b84b1c3d3e4.png','auth/auth_8_248beae1-4868-450a-96ce-9b84b1c3d3e4.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(112,'auth_8_37205e79-6540-4c19-9f38-6bad8c4ff227.png','auth_8_37205e79-6540-4c19-9f38-6bad8c4ff227.png','/uploads/auth/auth_8_37205e79-6540-4c19-9f38-6bad8c4ff227.png','auth/auth_8_37205e79-6540-4c19-9f38-6bad8c4ff227.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(113,'auth_8_40d3e422-b32c-4383-91ec-7a21e42f7140.png','auth_8_40d3e422-b32c-4383-91ec-7a21e42f7140.png','/uploads/auth/auth_8_40d3e422-b32c-4383-91ec-7a21e42f7140.png','auth/auth_8_40d3e422-b32c-4383-91ec-7a21e42f7140.png',413566,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(114,'auth_8_47fa6f52-3a95-46c7-9883-9459bedbbd80.png','auth_8_47fa6f52-3a95-46c7-9883-9459bedbbd80.png','/uploads/auth/auth_8_47fa6f52-3a95-46c7-9883-9459bedbbd80.png','auth/auth_8_47fa6f52-3a95-46c7-9883-9459bedbbd80.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(115,'auth_8_53242743-b96d-4d6c-badd-c3a2a0529fa1.png','auth_8_53242743-b96d-4d6c-badd-c3a2a0529fa1.png','/uploads/auth/auth_8_53242743-b96d-4d6c-badd-c3a2a0529fa1.png','auth/auth_8_53242743-b96d-4d6c-badd-c3a2a0529fa1.png',347919,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(116,'auth_8_7bd9106b-a8e4-4979-8daa-6c9948d77bf5.png','auth_8_7bd9106b-a8e4-4979-8daa-6c9948d77bf5.png','/uploads/auth/auth_8_7bd9106b-a8e4-4979-8daa-6c9948d77bf5.png','auth/auth_8_7bd9106b-a8e4-4979-8daa-6c9948d77bf5.png',347919,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(117,'auth_8_a037c38e-e943-49ba-8aee-a9e04da3f48d.png','auth_8_a037c38e-e943-49ba-8aee-a9e04da3f48d.png','/uploads/auth/auth_8_a037c38e-e943-49ba-8aee-a9e04da3f48d.png','auth/auth_8_a037c38e-e943-49ba-8aee-a9e04da3f48d.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(118,'auth_8_a0ce138d-27a3-4d1f-96e4-ed881e3230ba.png','auth_8_a0ce138d-27a3-4d1f-96e4-ed881e3230ba.png','/uploads/auth/auth_8_a0ce138d-27a3-4d1f-96e4-ed881e3230ba.png','auth/auth_8_a0ce138d-27a3-4d1f-96e4-ed881e3230ba.png',347919,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(119,'auth_8_ba8cd281-52e2-4788-91bf-598d31d0e9c1.png','auth_8_ba8cd281-52e2-4788-91bf-598d31d0e9c1.png','/uploads/auth/auth_8_ba8cd281-52e2-4788-91bf-598d31d0e9c1.png','auth/auth_8_ba8cd281-52e2-4788-91bf-598d31d0e9c1.png',408839,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(120,'auth_8_baadaf4e-7420-4074-b1a2-65e6604539b7.png','auth_8_baadaf4e-7420-4074-b1a2-65e6604539b7.png','/uploads/auth/auth_8_baadaf4e-7420-4074-b1a2-65e6604539b7.png','auth/auth_8_baadaf4e-7420-4074-b1a2-65e6604539b7.png',409989,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0),(121,'auth_8_f774b285-c84a-472a-be0c-7508760ea4d0.png','auth_8_f774b285-c84a-472a-be0c-7508760ea4d0.png','/uploads/auth/auth_8_f774b285-c84a-472a-be0c-7508760ea4d0.png','auth/auth_8_f774b285-c84a-472a-be0c-7508760ea4d0.png',462580,'image/png',718,610,NULL,'2026-10-15 03:42:52','shop_auth',0);
/*!40000 ALTER TABLE `sys_image` ENABLE KEYS */;

--
-- Table structure for table `sys_log`
--

DROP TABLE IF EXISTS `sys_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_log` (
  `log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志唯一标识',
  `user_id` bigint NOT NULL COMMENT '关联user.user_id，未登录操作（如浏览商品）为 null',
  `log_type` tinyint NOT NULL COMMENT '日志类型：1 - 操作日志，2 - 错误日志',
  `operation` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '操作描述（如 “商品审核通过”“订单取消”）',
  `module` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '操作模块（如 “商品管理”“订单管理”）',
  `ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '操作 IP 地址（如 “127.0.0.1”）',
  `error_msg` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '错误信息（仅log_type=2时填写，如 “数据库连接超时”）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '日志生成时间',
  PRIMARY KEY (`log_id`) USING BTREE,
  KEY `user_id` (`user_id`,`log_type`,`module`,`ip`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_log`
--

/*!40000 ALTER TABLE `sys_log` DISABLE KEYS */;
INSERT INTO `sys_log` VALUES (1,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-03-08 00:02:39'),(2,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-03-08 00:02:42'),(3,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-03-08 00:02:51'),(4,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-03-08 00:02:52'),(5,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-03-08 00:14:23'),(6,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-03-08 00:14:24'),(7,1,1,'禁用商家','商家管理','127.0.0.1',NULL,'2026-03-08 00:27:23'),(8,1,1,'启用商家','商家管理','127.0.0.1',NULL,'2026-03-08 00:27:26'),(9,1,1,'添加公告','公告管理','127.0.0.1',NULL,'2026-03-08 01:27:23'),(10,1,1,'商品审核通过','商品管理','127.0.0.1',NULL,'2026-03-08 01:59:00'),(11,1,1,'商品审核通过','商品管理','127.0.0.1',NULL,'2026-03-08 01:59:02'),(12,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:05:57'),(13,1,1,'商家审核通过','商家管理','127.0.0.1',NULL,'2026-03-17 20:06:19'),(14,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:07:11'),(15,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:13:50'),(16,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:13:59'),(17,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:14:14'),(18,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:15:13'),(19,1,1,'商家审核驳回','商家管理','127.0.0.1',NULL,'2026-03-17 20:23:34'),(20,1,1,'商品审核通过','商品管理','127.0.0.1',NULL,'2026-04-10 22:40:34'),(21,1,1,'商品审核通过','商品管理','127.0.0.1',NULL,'2026-04-10 22:40:35'),(22,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-10 22:47:36'),(23,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-10 22:49:15'),(24,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-10 23:05:44'),(25,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-10 23:11:04'),(26,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-10 23:37:17'),(27,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:30:51'),(28,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:32:51'),(29,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:34:46'),(30,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:37:42'),(31,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:42:56'),(32,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:42:57'),(33,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:42:58'),(34,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 01:44:50'),(35,1,1,'商品审核驳回','商品管理','127.0.0.1',NULL,'2026-04-11 02:16:27'),(36,1,1,'添加公告','公告管理','127.0.0.1',NULL,'2026-04-11 08:58:14'),(37,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-04-11 13:54:47'),(38,1,1,'添加分类','分类管理','127.0.0.1',NULL,'2026-10-15 04:00:52'),(39,1,1,'删除分类','分类管理','127.0.0.1',NULL,'2026-10-15 04:00:53'),(40,1,1,'商品上架','商品管理','127.0.0.1',NULL,'2026-10-15 04:00:59'),(41,1,1,'商品下架','商品管理','127.0.0.1',NULL,'2026-10-15 04:00:59'),(42,1,1,'商品审核驳回','商品管理','127.0.0.1',NULL,'2026-10-15 04:00:59'),(43,1,1,'商品审核驳回','商品管理','127.0.0.1',NULL,'2026-10-15 04:00:59'),(44,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-10-15 04:00:59'),(45,1,1,'更新用户状态','用户管理','127.0.0.1',NULL,'2026-10-15 04:00:59'),(46,1,1,'启用商家','商家管理','127.0.0.1',NULL,'2026-10-15 04:59:44'),(47,1,1,'禁用商家','商家管理','127.0.0.1',NULL,'2026-10-15 04:59:46'),(48,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-10-15 05:25:27'),(49,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-10-15 05:27:07'),(50,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-10-15 05:27:17'),(51,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-10-15 05:27:30'),(52,1,1,'商品审核通过并上架','商品管理','127.0.0.1',NULL,'2026-10-15 05:29:42');
/*!40000 ALTER TABLE `sys_log` ENABLE KEYS */;

--
-- Table structure for table `sys_notice`
--

DROP TABLE IF EXISTS `sys_notice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_notice` (
  `notice_id` bigint NOT NULL AUTO_INCREMENT COMMENT '通知唯一标识（自增主键）',
  `user_id` bigint DEFAULT NULL COMMENT '接收通知的用户ID，关联user.user_id（个人/企业/管理员用户）',
  `content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '通知内容（需包含关键业务信息，如商品名称、订单号、违规原因等）',
  `notice_type` tinyint NOT NULL COMMENT '通知类型：0-通用通知，1-库存预警通知（3.2模块），2-退款通知（3.6/3.7模块），3-账号封禁/冻结通知（3.8/3.9模块），4-差评提醒通知（3.10模块），5-租赁到期提醒（3.8模块）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '通知创建时间（自动化触发时间）',
  `is_read` tinyint NOT NULL DEFAULT '0' COMMENT '是否已读：0-未读，1-已读（用户查看后更新）',
  `expire_time` date DEFAULT NULL COMMENT '通知有效期（如差评提醒48小时有效期，3.10模块），过期后可标记为无效',
  `notice_status` tinyint NOT NULL DEFAULT '0' COMMENT '通知状态：0-正常，1-已过期，2-已删除（逻辑删除，避免物理删除丢失记录）',
  PRIMARY KEY (`notice_id`) USING BTREE,
  KEY `idx_sys_notice_user_id` (`user_id`) USING BTREE,
  KEY `idx_sys_notice_user_create` (`user_id`,`create_time`) USING BTREE,
  KEY `idx_sys_notice_type_status` (`notice_type`,`notice_status`) USING BTREE,
  CONSTRAINT `fk_sys_notice_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=183 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='系统通知表：存储库存预警、退款提醒、账号封禁、差评提醒等自动化通知，支撑业务规则落地';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_notice`
--

/*!40000 ALTER TABLE `sys_notice` DISABLE KEYS */;
INSERT INTO `sys_notice` VALUES (1,8,'您的商品【11 ZR】库存仅剩4件，请及时补货..',1,'2025-12-29 23:05:05',1,NULL,0),(2,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2025-12-29 23:05:07',1,NULL,0),(4,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-01-02 05:08:07',1,NULL,0),(5,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-01-02 05:10:47',1,NULL,0),(6,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-01-02 05:10:50',1,NULL,0),(9,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-01-08 22:18:40',1,NULL,0),(10,8,'您的商品【11 ZR】库存仅剩4件，请及时补货',1,'2026-01-08 22:21:36',1,NULL,0),(11,8,'您的商品【11 ZR】库存仅剩4件，请及时补货',1,'2026-01-08 22:21:56',1,NULL,0),(12,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-01-11 16:25:57',1,NULL,0),(14,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-01-11 16:31:56',1,NULL,0),(15,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-01-11 16:40:06',1,NULL,0),(16,8,'你好',0,'2026-01-11 16:54:34',1,NULL,0),(17,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-01-21 21:14:20',1,NULL,0),(18,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-01-21 21:14:21',1,NULL,0),(19,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-01-21 21:25:55',1,NULL,0),(20,8,'您的商品【11 ZR】库存仅剩4件，请及时补货',1,'2026-01-21 21:26:48',1,NULL,0),(21,8,'您的商品\"Z8\"审核通过，已自动上架。',0,'2026-01-22 00:54:05',1,NULL,0),(22,8,'您的商品\"Z8\"审核驳回，原因：111111',0,'2026-01-22 00:54:17',1,NULL,0),(23,8,'您的商品\"Z8\"已被管理员强制下架',0,'2026-01-22 01:23:19',1,NULL,0),(24,8,'您的商品\"Z8\"已被管理员撤销，需要重新审核',0,'2026-01-22 01:27:27',1,NULL,0),(25,8,'您的商品\"Z8\"审核通过，已自动上架。',0,'2026-01-22 01:28:41',1,NULL,0),(26,8,'您的商品\"Z8\"已被管理员强制下架',0,'2026-01-22 01:28:47',1,NULL,0),(27,8,'您的商品\"Z8\"已被管理员撤销，需要重新审核',0,'2026-01-22 01:28:54',1,NULL,0),(28,8,'您的店铺\"摄影器材专营店\"认证审核驳回，原因：缺少材料',0,'2026-02-09 17:42:27',1,NULL,0),(29,19,'您的店铺\"爱爱爱\"认证审核驳回，原因：111',0,'2026-02-09 18:41:23',0,NULL,0),(30,19,'您的店铺\"爱爱爱\"认证审核通过，店铺已成功开通。',0,'2026-02-09 19:21:26',0,NULL,0),(31,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-02-09 20:13:51',0,NULL,0),(32,8,'您的商品【11 ZR】库存仅剩2件，请及时补货',1,'2026-02-09 20:13:53',0,NULL,0),(33,8,'您的商品\"z8\"审核通过，已自动上架。',0,'2026-02-09 21:20:44',1,NULL,0),(34,8,'您的商品\"z8\"审核通过，已自动上架。',0,'2026-02-09 22:23:10',1,NULL,0),(35,8,'您的商品\"A7M4\"审核通过，已自动上架。',0,'2026-02-09 22:56:08',1,NULL,0),(36,8,'您的商品\"Z72\"审核通过，已自动上架。',0,'2026-02-10 00:42:14',1,NULL,0),(37,8,'您的商品\"ZR\"审核通过，已自动上架。',0,'2026-02-10 00:44:07',1,NULL,0),(38,19,'您的商品\"Z63\"审核通过，已自动上架。',0,'2026-02-10 00:52:16',0,NULL,0),(39,19,'您的商品\"Z63\"已被管理员强制下架',0,'2026-02-10 00:52:22',0,NULL,0),(40,19,'您的商品\"Z63\"已被管理员撤销，需要重新审核',0,'2026-02-10 00:52:31',0,NULL,0),(41,19,'您的商品\"Z63\"审核通过，已自动上架。',0,'2026-02-10 01:09:53',0,NULL,0),(42,19,'您的商品\"Z63\"已被管理员强制下架',0,'2026-02-10 01:09:58',0,NULL,0),(43,19,'您的商品\"Z63\"已被管理员撤销，需要重新审核',0,'2026-02-10 01:10:01',0,NULL,0),(44,19,'您的商品\"Z63\"审核通过，已自动上架。',0,'2026-02-10 01:52:29',0,NULL,0),(45,NULL,'',0,'2026-03-07 23:13:48',0,NULL,0),(46,NULL,'',0,'2026-03-07 23:13:55',0,NULL,0),(47,8,'啊啊啊啊啊啊啊啊啊啊',0,'2026-03-08 00:01:28',1,NULL,0),(48,8,'21',0,'2026-03-08 01:27:23',1,NULL,2),(49,21,'您的店铺审核已驳回，原因：111111111111111111111',1,'2026-03-17 20:23:34',0,NULL,0),(50,8,'您的商品【11 ZR】库存仅剩-3件，请及时补货',1,'2026-03-17 21:11:39',0,NULL,0),(51,8,'您的商品【11 ZR】库存仅剩-8件，请及时补货',1,'2026-03-17 21:11:49',0,NULL,0),(52,19,'您的商品【11 Z63】库存仅剩-37件，请及时补货',1,'2026-04-07 17:57:25',0,NULL,0),(53,19,'您的商品【11 Z63】库存仅剩-137件，请及时补货',1,'2026-04-07 17:57:27',0,NULL,0),(54,8,'您的商品【11 Z62】库存仅剩-137件，请及时补货',1,'2026-04-07 17:57:51',1,NULL,0),(55,8,'您的商品【11 Z62】库存仅剩-336件，请及时补货',1,'2026-04-07 17:57:52',1,NULL,0),(56,8,'您的商品【41 ACTION 4】库存仅剩2件，请及时补货',1,'2026-04-10 23:05:43',1,NULL,0),(57,8,'您的商品【41 ACTION 4】库存仅剩1件，请及时补货',1,'2026-04-11 00:18:05',0,NULL,0),(58,8,'您的商品【41 ACTION 4】库存仅剩0件，请及时补货',1,'2026-04-11 00:18:07',0,NULL,0),(59,8,'您的商品【21 Z 70-200mm f2.8 VR S】库存仅剩4件，请及时补货',1,'2026-04-11 01:01:18',0,NULL,0),(60,8,'您的商品【21 Z 70-200mm f2.8 VR S】库存仅剩3件，请及时补货',1,'2026-04-11 01:01:20',0,NULL,0),(61,8,'您的商品【21 Z 70-200mm f2.8 VR S】库存仅剩4件，请及时补货',1,'2026-04-11 01:02:25',0,NULL,0),(62,8,'您的商品【11 ZR】库存仅剩4件，请及时补货',1,'2026-04-11 01:03:04',0,NULL,0),(63,8,'您的商品【11 ZR】库存仅剩3件，请及时补货',1,'2026-04-11 01:03:06',0,NULL,0),(64,8,'您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货',1,'2026-04-11 01:30:50',0,NULL,0),(65,8,'您的商品【12 A7M4】库存仅剩3件，请及时补货',1,'2026-04-11 01:34:45',0,NULL,0),(66,8,'您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货',1,'2026-04-11 01:47:44',0,NULL,0),(67,8,'您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货',1,'2026-04-11 01:55:37',0,NULL,0),(68,8,'您的商品【12 Mavic 3 Pro】库存仅剩2件，请及时补货',1,'2026-04-11 01:55:55',0,NULL,0),(69,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-04-11 02:11:13',0,NULL,0),(70,8,'您的商品【11 ZR】库存仅剩1件，请及时补货',1,'2026-04-11 08:35:38',0,NULL,0),(71,8,'您的商品【11 ZR】库存仅剩-1件，请及时补货',1,'2026-04-11 08:35:40',0,NULL,2),(72,7,'测试',0,'2026-04-11 08:58:14',0,'2026-04-11',0),(73,7,'您的订单 ORD2604110912117402400001 已创建，等待支付',1,'2026-04-11 09:12:12',1,NULL,0),(74,7,'您的订单 ORD2604110912117402400001 支付成功',1,'2026-04-11 09:12:13',1,NULL,0),(75,7,'您的订单 ORD2604110912117402400001 支付成功',1,'2026-04-11 09:12:15',0,NULL,0),(76,8,'您的商品【21 Z 24-120 F4S】库存仅剩3件，请及时补货',1,'2026-04-11 09:12:15',0,NULL,0),(77,7,'您的订单 ORD2604110912117402400001 已发货',1,'2026-04-11 09:12:29',0,NULL,0),(78,7,'您的订单 ORD2604111228302622400002 已创建，等待支付',1,'2026-04-11 12:28:30',0,NULL,0),(79,7,'您的订单 ORD2604111228302622400002 支付成功',1,'2026-04-11 12:28:33',0,NULL,0),(80,7,'您的订单 ORD2604111228302622400002 支付成功',1,'2026-04-11 12:28:36',0,NULL,0),(81,7,'您的订单 ORD2604111228302622400002 已发货',1,'2026-04-11 12:28:56',0,NULL,0),(82,7,'您的租赁订单 ORD2604111228302622400002 已确认收货，开始租赁',1,'2026-04-11 12:29:08',0,NULL,0),(83,7,'您的租赁订单 ORD2604111228302622400002 正在归还中',1,'2026-04-11 12:29:13',0,NULL,0),(84,7,'您的订单 ORD2604111228302622400002 已完成',1,'2026-04-11 12:29:27',0,NULL,0),(85,7,'您的订单 ORD2604111231382552400003 已创建，等待支付',1,'2026-04-11 12:31:38',0,NULL,0),(86,7,'您的订单 ORD2604111231382552400003 支付成功',1,'2026-04-11 12:31:41',0,NULL,0),(87,7,'您的订单 ORD2604111231382552400003 支付成功',1,'2026-04-11 12:31:43',0,NULL,0),(88,7,'您的订单 ORD2604111231382552400003 已发货',1,'2026-04-11 12:32:00',0,NULL,0),(89,7,'您的租赁订单 ORD2604111231382552400003 已确认收货，开始租赁',1,'2026-04-11 12:32:07',0,NULL,0),(90,7,'您的租赁订单 ORD2604111231382552400003 正在归还中',1,'2026-04-11 12:32:17',0,NULL,0),(91,7,'您的订单 ORD2604111231382552400003 已完成',1,'2026-04-11 12:32:27',0,NULL,0),(92,7,'您的订单 ORD2604111457191642400004 已创建，等待支付',1,'2026-04-11 14:57:19',0,NULL,0),(93,7,'您的订单 ORD2604111457191642400004 支付成功',1,'2026-04-11 14:57:22',0,NULL,0),(94,7,'您的订单 ORD2604111457191642400004 支付成功',1,'2026-04-11 14:57:25',0,NULL,0),(95,7,'您的订单 ORD2604111457191642400004 已发货',1,'2026-04-11 14:57:46',0,NULL,0),(96,7,'您的租赁订单 ORD2604111457191642400004 已确认收货，开始租赁',1,'2026-04-11 14:58:01',0,NULL,0),(97,7,'您的租赁订单 ORD2604111457191642400004 正在归还中',1,'2026-04-11 14:58:13',0,NULL,0),(98,7,'您的订单 ORD2604111457191642400004 已完成',1,'2026-04-11 14:58:22',0,NULL,0),(99,19,'您的商品【11 Z63】库存仅剩0件，请及时补货',1,'2026-10-15 03:42:34',0,NULL,0),(100,8,'您的商品【21 Z 24-120 F4S】库存仅剩3件，请及时补货',1,'2026-10-15 03:42:34',0,NULL,0),(101,8,'您的商品【11 D850】库存仅剩4件，请及时补货',1,'2026-10-15 03:42:34',0,NULL,0),(102,19,'您的商品【11 Z63】库存仅剩0件，请及时补货',1,'2026-10-15 03:42:34',0,NULL,0),(103,8,'您的商品【41 ACTION 4】库存仅剩0件，请及时补货',1,'2026-10-15 03:42:34',0,NULL,0),(104,8,'您的商品【37 Mavic 3 Pro】库存仅剩2件，请及时补货',1,'2026-10-15 03:42:34',0,NULL,0),(105,8,'您的商品【11 D850】库存仅剩1件，请及时补货',1,'2026-10-15 03:44:09',0,NULL,0),(106,8,'您的商品【11 Z6】库存仅剩1件，请及时补货',1,'2026-10-15 03:44:09',0,NULL,0),(107,8,'您的商品【11 Z72】库存仅剩1件，请及时补货',1,'2026-10-15 03:44:09',0,NULL,0),(108,8,'您的商品【13 EOS R5 Mark II】库存仅剩1件，请及时补货',1,'2026-10-15 03:44:09',0,NULL,0),(109,23,'您的订单 ORD2610150348188528360001 已创建，等待支付',1,'2026-10-15 03:48:19',0,NULL,0),(110,23,'您的订单 ORD2610150348188528360001 支付成功',1,'2026-10-15 03:48:27',0,NULL,0),(111,23,'您的订单 ORD2610150348188528360001 已发货',1,'2026-10-15 03:48:27',0,NULL,0),(112,23,'您的订单 ORD2610150348188528360001 已完成',1,'2026-10-15 03:48:27',0,NULL,0),(113,23,'您的订单 ORD2610150348346578360002 已创建，等待支付',1,'2026-10-15 03:48:35',0,NULL,0),(114,23,'您的订单 ORD2610150348346578360002 支付成功',1,'2026-10-15 03:48:40',0,NULL,0),(115,8,'您的商品【37 Mavic 3 Pro】库存仅剩1件，请及时补货',1,'2026-10-15 03:48:40',0,NULL,0),(116,23,'您的订单 ORD2610150348346578360002 已发货',1,'2026-10-15 03:48:40',0,NULL,0),(117,23,'您的租赁订单 ORD2610150348346578360002 已确认收货，开始租赁',1,'2026-10-15 03:48:40',0,NULL,0),(118,23,'您的租赁订单 ORD2610150348346578360002 正在归还中',1,'2026-10-15 03:48:40',0,NULL,0),(119,23,'您的订单 ORD2610150350583478360003 已创建，等待支付',1,'2026-10-15 03:50:58',0,NULL,0),(120,23,'您的订单 ORD2610150350583478360003 支付成功',1,'2026-10-15 03:50:58',0,NULL,0),(121,23,'您的订单 ORD2610150350583478360003 正在退款处理中',1,'2026-10-15 03:50:59',0,NULL,0),(122,23,'您的订单 ORD2610150359025928360004 已创建，等待支付',1,'2026-10-15 03:59:03',0,NULL,0),(123,23,'您的订单 ORD2610150359025928360004 支付成功',1,'2026-10-15 03:59:06',0,NULL,0),(124,23,'您的订单 ORD2610150525264389360001 已创建，等待支付',1,'2026-10-15 05:25:26',0,NULL,0),(126,8,'您的商品「Z 24-70mm F4 S」已通过审核并上架。',1,'2026-10-15 05:25:27',0,NULL,1),(127,23,'您的订单 ORD2610150525276799360002 已创建，等待支付',1,'2026-10-15 05:25:28',0,NULL,0),(129,23,'您的订单 ORD2610150527064649480001 已创建，等待支付',1,'2026-10-15 05:27:06',0,NULL,0),(130,23,'您的订单 ORD2610150527064649480001 支付成功',1,'2026-10-15 05:27:07',0,NULL,0),(131,23,'您的订单 ORD2610150527064649480001 已发货',1,'2026-10-15 05:27:07',0,NULL,0),(132,23,'您的订单 ORD2610150527064649480001 已完成',1,'2026-10-15 05:27:07',0,NULL,0),(133,8,'您的商品「ACTION 5 PRO」已通过审核并上架。',1,'2026-10-15 05:27:07',0,NULL,1),(134,23,'您的订单 ORD2610150527079979480002 已创建，等待支付',1,'2026-10-15 05:27:08',0,NULL,0),(135,23,'您的订单 ORD2610150527079979480002 支付成功',1,'2026-10-15 05:27:08',0,NULL,0),(136,23,'您的订单 ORD2610150527079979480002 正在退款处理中',1,'2026-10-15 05:27:08',0,NULL,0),(137,23,'您的订单 ORD2610150527079979480002 退款成功',1,'2026-10-15 05:27:08',0,NULL,0),(138,23,'您的订单 ORD2610150527172519480003 已创建，等待支付',1,'2026-10-15 05:27:17',0,NULL,0),(139,23,'您的订单 ORD2610150527172519480003 支付成功',1,'2026-10-15 05:27:17',0,NULL,0),(140,23,'您的订单 ORD2610150527172519480003 已发货',1,'2026-10-15 05:27:17',0,NULL,0),(141,23,'您的订单 ORD2610150527172519480003 已完成',1,'2026-10-15 05:27:17',0,NULL,0),(142,8,'您的商品「ZR」已通过审核并上架。',1,'2026-10-15 05:27:17',0,NULL,1),(143,23,'您的订单 ORD2610150527181079480004 已创建，等待支付',1,'2026-10-15 05:27:18',0,NULL,0),(144,23,'您的订单 ORD2610150527181079480004 支付成功',1,'2026-10-15 05:27:18',0,NULL,0),(145,23,'您的订单 ORD2610150527181079480004 正在退款处理中',1,'2026-10-15 05:27:18',0,NULL,0),(146,23,'您的订单 ORD2610150527181079480004 退款成功',1,'2026-10-15 05:27:19',0,NULL,0),(147,23,'您的订单 ORD2610150527297759480005 已创建，等待支付',1,'2026-10-15 05:27:30',0,NULL,0),(148,23,'您的订单 ORD2610150527297759480005 支付成功',1,'2026-10-15 05:27:30',0,NULL,0),(149,23,'您的订单 ORD2610150527297759480005 已发货',1,'2026-10-15 05:27:30',0,NULL,0),(150,23,'您的订单 ORD2610150527297759480005 已完成',1,'2026-10-15 05:27:30',0,NULL,0),(151,8,'您的商品「Action 5 PRO」已通过审核并上架。',1,'2026-10-15 05:27:30',0,NULL,1),(152,23,'您的订单 ORD2610150527306499480006 已创建，等待支付',1,'2026-10-15 05:27:31',0,NULL,0),(153,23,'您的订单 ORD2610150527306499480006 支付成功',1,'2026-10-15 05:27:31',0,NULL,0),(154,23,'您的订单 ORD2610150527306499480006 正在退款处理中',1,'2026-10-15 05:27:31',0,NULL,0),(155,23,'您的订单 ORD2610150527306499480006 退款成功',1,'2026-10-15 05:27:31',0,NULL,0),(156,23,'您的订单 ORD2610150529414579480007 已创建，等待支付',1,'2026-10-15 05:29:41',0,NULL,0),(157,23,'您的订单 ORD2610150529414579480007 支付成功',1,'2026-10-15 05:29:41',0,NULL,0),(158,23,'您的订单 ORD2610150529414579480007 已发货',1,'2026-10-15 05:29:42',0,NULL,0),(159,23,'您的订单 ORD2610150529414579480007 已完成',1,'2026-10-15 05:29:42',0,NULL,0),(160,8,'您的商品「ACTION 5 PRO」已通过审核并上架。',1,'2026-10-15 05:29:42',0,NULL,1),(161,23,'您的订单 ORD2610150529422509480008 已创建，等待支付',1,'2026-10-15 05:29:42',0,NULL,0),(162,23,'您的订单 ORD2610150529422509480008 支付成功',1,'2026-10-15 05:29:42',0,NULL,0),(163,23,'您的订单 ORD2610150529422509480008 正在退款处理中',1,'2026-10-15 05:29:42',0,NULL,0),(164,23,'您的订单 ORD2610150529422509480008 退款成功',1,'2026-10-15 05:29:43',0,NULL,0),(165,23,'您的订单 ORD2610150531432279480009 已创建，等待支付',1,'2026-10-15 05:31:43',0,NULL,0),(166,23,'您的订单 ORD2610150531432279480009 支付成功',1,'2026-10-15 05:31:43',0,NULL,0),(167,23,'您的订单 ORD2610150531432279480009 已发货',1,'2026-10-15 05:31:43',0,NULL,0),(168,23,'您的订单 ORD2610150531432279480009 已完成',1,'2026-10-15 05:31:43',0,NULL,0),(169,23,'您的订单 ORD2610150531439539480010 已创建，等待支付',1,'2026-10-15 05:31:44',0,NULL,0),(170,23,'您的订单 ORD2610150531439539480010 支付成功',1,'2026-10-15 05:31:44',0,NULL,0),(171,23,'您的订单 ORD2610150531439539480010 正在退款处理中',1,'2026-10-15 05:31:44',0,NULL,0),(172,23,'您的订单 ORD2610150531439539480010 退款成功',1,'2026-10-15 05:31:44',0,NULL,0),(173,23,'您的订单 ORD2610150535096000080001 已创建，等待支付',1,'2026-10-15 05:35:10',0,NULL,0),(174,23,'您的订单 ORD2610150535096000080001 支付成功',1,'2026-10-15 05:35:10',0,NULL,0),(175,23,'您的订单 ORD2610150535096000080001 已发货',1,'2026-10-15 05:35:10',0,NULL,0),(176,23,'您的订单 ORD2610150535096000080001 已完成',1,'2026-10-15 05:35:10',0,NULL,0),(177,23,'您的订单 ORD2610150535105080080002 已创建，等待支付',1,'2026-10-15 05:35:11',0,NULL,0),(178,23,'您的订单 ORD2610150535105080080002 支付成功',1,'2026-10-15 05:35:11',0,NULL,0),(179,23,'您的订单 ORD2610150535105080080002 正在退款处理中',1,'2026-10-15 05:35:11',0,NULL,0),(180,23,'您的订单 ORD2610150535105080080002 退款成功',1,'2026-10-15 05:35:11',0,NULL,0),(181,23,'您的订单 ORD2610150608368821880001 已创建，等待支付',1,'2026-10-15 06:08:37',0,NULL,0),(182,23,'您的订单 ORD2610150608368821880001 支付成功',1,'2026-10-15 06:08:47',0,NULL,0);
/*!40000 ALTER TABLE `sys_notice` ENABLE KEYS */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `user_id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识（自增 ID）',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '登录账号（个人为手机号 / 邮箱，企业为统一信用代码）',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '随机昵称（用户_+6位随机数）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '加密存储的密码（MD5 + 盐值）',
  `user_type` tinyint NOT NULL COMMENT '用户类型：1 - 个人用户，2 - 企业用户（器材商家），3 - 管理员，4 -超级管理员',
  `real_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '个人用户真实姓名（实名认证用）',
  `id_card` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '个人用户身份证号（加密存储，仅管理员可查看）',
  `avatar_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '用户头像路径（存储于本地public/head目录）',
  `shop_logo_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '店铺 logo',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '联系电话（用于验证码登录、订单通知）',
  `business_license` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业营业执照图片路径（存储于 MinIO / 本地）',
  `legal_id_front` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '法人身份证正面图片路径',
  `legal_id_back` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '法人身份证反面图片路径',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '邮箱（用于密码重置、系统通知）',
  `gender` tinyint DEFAULT '0' COMMENT '性别：0 - 未知，1 - 男，2 - 女',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '账号状态：0 - 禁用（违规），1 - 正常，2 - 待审核（企业 / 个人未认证）',
  `create_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '账号创建时间',
  `update_time` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '账号信息更新时间',
  `shop_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '店铺名称',
  `business_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '企业类型：personal-个人店铺，enterprise-企业店铺',
  `shop_status` tinyint NOT NULL DEFAULT '1' COMMENT '店铺状态：0-关闭，1-正常，2-审核中',
  `open_time` datetime DEFAULT NULL COMMENT '开店时间',
  `shop_address` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '店铺地址',
  `shop_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin COMMENT '店铺简介',
  `has_shop` tinyint NOT NULL DEFAULT '0' COMMENT '是否有店铺：0-无，1-有',
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE KEY `username` (`username`,`id_card`,`email`) USING BTREE,
  KEY `user_type` (`user_type`,`phone`,`status`) USING BTREE,
  KEY `user_id` (`user_id`,`username`) USING BTREE,
  CONSTRAINT `user_ibfk_1` FOREIGN KEY (`user_type`) REFERENCES `role` (`user_type`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。\r\n备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'18344551990','Seventy7超管','$2a$12$etCitOk68ONZtMTg6N25ZOXCVpWjqrBm4i7gtznXUD4TV1d5J7U5m',4,'詹仕杰','','',NULL,'18344551990',NULL,NULL,NULL,'3324879861@qq.com',1,1,'2026-03-07 20:34:37','2026-03-07 20:34:37',NULL,NULL,1,NULL,NULL,NULL,0),(2,'18344551993','Seventy7普管','$2a$12$etCitOk68ONZtMTg6N25ZOXCVpWjqrBm4i7gtznXUD4TV1d5J7U5m',3,'詹仕杰','','',NULL,'18344551993',NULL,NULL,NULL,'3324879861@qq.com',1,1,'2026-03-07 20:34:39','2026-03-07 20:34:39',NULL,NULL,1,NULL,NULL,NULL,0),(7,'18344551991','Seventy7','$2a$12$y.Rt69W9faL0lPR.vniTpe.Np4PDPNeuoBjCVcKDTF8K2uh5KUhq.',1,'詹仕杰','445122200308210917','/uploads/avatar/04953aa3-09d4-420b-970b-29ebd4ce31f1.JPG',NULL,'18344551991',NULL,NULL,NULL,'3324879861@qq.com',1,1,'2026-10-15 03:42:34','2026-10-15 03:42:34',NULL,NULL,1,NULL,NULL,NULL,0),(8,'52440000799352866W','摄影优品','$2a$12$oEeivQpmHhIGFNziDyxYIOYaibQ.uAHGf3UUAM7ZzfKUYxajlthp6',2,'广软',NULL,NULL,'/uploads/avatar/shop_58711c1b-1b43-4275-84d3-5ca6248828a1.png','18344551992','/uploads/auth/auth_8_53242743-b96d-4d6c-badd-c3a2a0529fa1.png','/uploads/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png','/uploads/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png','3324879861@qq.com',0,1,'2026-10-15 03:42:34','2026-10-15 03:42:34','摄影器材专营店','enterprise',1,'2025-01-15 00:00:00','北京市朝阳区建国路88号','专业摄影器材销售、租赁和二手交易.',1),(9,'18344551999','用户_418092','$2a$12$cyG5Q8FzHvCHfvRTzX4bTecytZPgfnInlQfHZzJ0tjtTmi8mr1zOa',3,NULL,NULL,NULL,NULL,'',NULL,NULL,NULL,'3324879861@qq.com',0,0,'2026-10-15 04:58:05','2026-10-15 04:58:06',NULL,NULL,1,NULL,NULL,NULL,0),(11,'18344551994','用户_539209','$2a$12$cyG5Q8FzHvCHfvRTzX4bTecytZPgfnInlQfHZzJ0tjtTmi8mr1zOa',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'3324879861@qq.com',0,1,'2026-03-07 20:34:42','2026-03-07 20:34:42',NULL,NULL,1,NULL,NULL,NULL,0),(17,'18344551998','用户_885077','$2a$12$cPVMHtcAn0hKFR7KUKAmsejqqajcoJ64xgWpASabzgvFhhMZREWqm',3,NULL,NULL,NULL,NULL,'',NULL,NULL,NULL,'3324879861@qq.com',0,1,'2026-03-07 20:34:44','2026-03-07 20:34:44',NULL,NULL,1,NULL,NULL,NULL,0),(19,'123456789123456789','用户_889684','$2a$12$c45vhPps7FL8DuA.07Jdn.zKn5JVkA5FqQgt9zxaWrf4qBWQR1U3O',2,NULL,NULL,NULL,'/uploads/avatar/shop_96af7a46-e549-4fbf-8452-419d93a08b2e.png','18344551990','/uploads/auth/auth_19_e86e1ef7-60c3-43ee-a473-dbc1ee60f922.png','/uploads/auth/auth_19_784d7ab9-648b-42fe-86c3-8b6ffb1e800b.png','/uploads/auth/auth_19_a6367c0a-31fe-46ea-943d-11a026eb4355.png','3324879861@qq.com',0,1,'2026-10-15 03:42:34','2026-10-15 03:42:34','AAA','personal',1,'2026-02-09 19:21:26','66666666','啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊',1),(20,'15113747673','用户_791222','$2a$12$kIxuvY35kdDYWjUFJzQeA.VloOmB.SfN/nmc0Skaw.kdKldbnalFi',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'3324879861@qq.com',0,1,'2026-03-07 20:39:49','2026-03-07 20:39:49',NULL,NULL,1,NULL,NULL,NULL,0),(21,'888888888888888888','用户_378138','$2a$12$PrH4w1gz/yWTQNdOlUbDaexbJFmFUVwSF/EZESR72BN0SX5UFDM3y',2,NULL,NULL,NULL,NULL,NULL,'/uploads/auth/auth_21_b931fcfc-a8c7-451a-ba8b-23385c4f59b5.png','/uploads/auth/auth_21_3e70886e-69db-4151-9a16-e095e87fb106.png','/uploads/auth/auth_21_e94086c6-c7ce-41fd-a0ed-e23cd21e30cb.png','3324879861@qq.com',0,2,'2026-10-15 03:42:34','2026-10-15 03:42:34',NULL,NULL,0,NULL,NULL,NULL,1),(22,'15113747674','用户_985045','$2a$12$TvOMKoA00/mS8rd88fabxufeQVMqe0ozit/TuMb8hcG8hIXW5uHzq',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'3324879861@qq.com',0,1,'2026-04-11 02:22:30','2026-04-11 02:22:30',NULL,NULL,1,NULL,NULL,NULL,0),(23,'13800138000','验收买家','$2a$12$j0OAzLJHJ4pQiBYTyT5KzudcXry76O.j/sV4qVsEUYJTLLK7cRAni',1,NULL,NULL,NULL,NULL,'13800138000',NULL,NULL,NULL,'verify@example.com',0,1,'2026-10-15 03:47:25','2026-10-15 03:47:25',NULL,NULL,1,NULL,NULL,NULL,0);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_user_nickname` BEFORE INSERT ON `user` FOR EACH ROW BEGIN
    IF NEW.`nickname` IS NULL OR NEW.`nickname` = '' THEN
        SET NEW.`nickname` = CONCAT('用户_', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `user_address`
--

DROP TABLE IF EXISTS `user_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_address` (
  `address_id` bigint NOT NULL AUTO_INCREMENT COMMENT '地址ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `recipient` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '收货人',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '电话',
  `province` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '省份',
  `city` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '城市',
  `district` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '区/县',
  `detail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '详细地址',
  `is_default` tinyint NOT NULL DEFAULT '0' COMMENT '是否默认地址',
  PRIMARY KEY (`address_id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  CONSTRAINT `user_address_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_address`
--

/*!40000 ALTER TABLE `user_address` DISABLE KEYS */;
INSERT INTO `user_address` VALUES (15,1,'詹仕杰','18344551990','广东省','广州市','从化区','广从南路548号广州软件学院',1),(16,1,'詹先生','18344551990','广东省','潮州市','饶平县','饶洋镇陈坑村上坑202号',1),(17,7,'詹','18344551990','44','4401','440117','广从南路548号广州软件学院',1),(18,11,'111','18344551994','11','1101','110101','111',1),(19,7,'shijie','18344551990','44','4401','440117','广从南路548号11111',0),(20,23,'验收买家','13800138000','广东省','广州市','从化区','广从南路 548 号',1);
/*!40000 ALTER TABLE `user_address` ENABLE KEYS */;

--
-- Dumping events for database 'db_bysj_pets'
--

--
-- Dumping routines for database 'db_bysj_pets'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-15  6:32:27
