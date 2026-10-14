INSERT INTO `permission` (`permission_name`, `permission_code`, `url`, `method`, `parent_id`, `create_time`, `update_time`)
SELECT t.n, t.c, t.u, t.m, 42, NOW(), NOW() FROM (
    SELECT '查看个人资料' AS n, 'USER_PROFILE_GET' AS c, '/user/profile' AS u, 'GET' AS m UNION ALL
    SELECT '修改个人资料' AS n, 'USER_PROFILE_UPDATE' AS c, '/user/profile' AS u, 'PUT' AS m UNION ALL
    SELECT '修改登录密码' AS n, 'USER_PASSWORD_UPDATE' AS c, '/user/password' AS u, 'PUT' AS m UNION ALL
    SELECT '上传头像' AS n, 'USER_AVATAR_UPLOAD' AS c, '/user/avatar' AS u, 'POST' AS m UNION ALL
    SELECT '查看收货地址' AS n, 'USER_ADDRESS_LIST' AS c, '/user/addresses' AS u, 'GET' AS m UNION ALL
    SELECT '新增收货地址' AS n, 'USER_ADDRESS_ADD' AS c, '/user/addresses' AS u, 'POST' AS m UNION ALL
    SELECT '修改收货地址' AS n, 'USER_ADDRESS_UPDATE' AS c, '/user/addresses' AS u, 'PUT' AS m UNION ALL
    SELECT '删除收货地址' AS n, 'USER_ADDRESS_DELETE' AS c, '/user/addresses/{addressId}' AS u, 'DELETE' AS m UNION ALL
    SELECT '设为默认地址' AS n, 'USER_ADDRESS_DEFAULT' AS c, '/user/addresses/{addressId}/default' AS u, 'PUT' AS m UNION ALL
    SELECT '查看购物车' AS n, 'CART_LIST' AS c, '/cart/items' AS u, 'GET' AS m UNION ALL
    SELECT '加入购物车' AS n, 'CART_ADD' AS c, '/cart/add' AS u, 'POST' AS m UNION ALL
    SELECT '修改购物车数量' AS n, 'CART_UPDATE' AS c, '/cart/items/{cartItemId}' AS u, 'PUT' AS m UNION ALL
    SELECT '删除购物车项' AS n, 'CART_DELETE' AS c, '/cart/items/{cartItemId}' AS u, 'DELETE' AS m UNION ALL
    SELECT '清空购物车' AS n, 'CART_CLEAR' AS c, '/cart/clear' AS u, 'DELETE' AS m UNION ALL
    SELECT '批量加入购物车' AS n, 'CART_BATCH_ADD' AS c, '/cart/batch-add' AS u, 'POST' AS m UNION ALL
    SELECT '批量删除购物车项' AS n, 'CART_BATCH_DELETE' AS c, '/cart/batch-delete' AS u, 'POST' AS m UNION ALL
    SELECT '查看收藏' AS n, 'FAVORITE_LIST' AS c, '/favorites' AS u, 'GET' AS m UNION ALL
    SELECT '添加收藏' AS n, 'FAVORITE_ADD' AS c, '/favorites' AS u, 'POST' AS m UNION ALL
    SELECT '取消收藏（按商品）' AS n, 'FAVORITE_REMOVE' AS c, '/favorites' AS u, 'DELETE' AS m UNION ALL
    SELECT '取消收藏（按收藏ID）' AS n, 'FAVORITE_REMOVE_BY_ID' AS c, '/favorites/{favoriteId}' AS u, 'DELETE' AS m UNION ALL
    SELECT '批量取消收藏' AS n, 'FAVORITE_BATCH_DELETE' AS c, '/favorites/batch-delete' AS u, 'POST' AS m UNION ALL
    SELECT '检查收藏状态' AS n, 'FAVORITE_CHECK' AS c, '/favorites/check' AS u, 'GET' AS m UNION ALL
    SELECT '查看我的订单' AS n, 'ORDER_LIST' AS c, '/orders/list' AS u, 'GET' AS m UNION ALL
    SELECT '查看订单详情' AS n, 'ORDER_DETAIL' AS c, '/orders/{orderId}' AS u, 'GET' AS m UNION ALL
    SELECT '按订单号查详情' AS n, 'ORDER_DETAIL_BY_NO' AS c, '/orders/by-order-no/{orderNo}' AS u, 'GET' AS m UNION ALL
    SELECT '购物车下单' AS n, 'ORDER_CREATE_FROM_CART' AS c, '/orders/create-from-cart' AS u, 'POST' AS m UNION ALL
    SELECT '立即购买下单' AS n, 'ORDER_TEMP' AS c, '/orders/temp' AS u, 'POST' AS m UNION ALL
    SELECT '检查未支付订单' AS n, 'ORDER_CHECK_PENDING' AS c, '/orders/check-pending' AS u, 'POST' AS m UNION ALL
    SELECT '支付订单' AS n, 'ORDER_PAY' AS c, '/orders/pay/{orderId}' AS u, 'POST' AS m UNION ALL
    SELECT '取消订单' AS n, 'ORDER_CANCEL' AS c, '/orders/{orderId}/cancel' AS u, 'POST' AS m UNION ALL
    SELECT '确认收货' AS n, 'ORDER_CONFIRM_RECEIVE' AS c, '/orders/{orderId}/confirm-receive' AS u, 'POST' AS m UNION ALL
    SELECT '归还租赁器材' AS n, 'ORDER_RETURN' AS c, '/orders/{orderId}/return' AS u, 'POST' AS m UNION ALL
    SELECT '申请退款' AS n, 'REFUND_APPLY' AS c, '/refunds/apply' AS u, 'POST' AS m UNION ALL
    SELECT '查看订单退款' AS n, 'REFUND_BY_ORDER' AS c, '/refunds/order/{orderId}' AS u, 'GET' AS m UNION ALL
    SELECT '判断能否退款' AS n, 'REFUND_CAN' AS c, '/refunds/can-refund/{orderId}' AS u, 'GET' AS m UNION ALL
    SELECT '提交评价' AS n, 'EVAL_CREATE' AS c, '/evaluations' AS u, 'POST' AS m UNION ALL
    SELECT '查看我的评价' AS n, 'EVAL_MINE' AS c, '/evaluations/user' AS u, 'GET' AS m UNION ALL
    SELECT '删除评价' AS n, 'EVAL_DELETE' AS c, '/evaluations/{evaluationId}' AS u, 'DELETE' AS m UNION ALL
    SELECT '查看消息' AS n, 'MESSAGE_LIST' AS c, '/message/list' AS u, 'GET' AS m UNION ALL
    SELECT '查看未读数' AS n, 'MESSAGE_UNREAD' AS c, '/message/unread/count' AS u, 'GET' AS m UNION ALL
    SELECT '标记消息已读' AS n, 'MESSAGE_READ' AS c, '/message/{id}/read' AS u, 'PUT' AS m UNION ALL
    SELECT '全部标记已读' AS n, 'MESSAGE_READ_ALL' AS c, '/message/all/read' AS u, 'PUT' AS m UNION ALL
    SELECT '删除消息' AS n, 'MESSAGE_DELETE' AS c, '/message/{id}' AS u, 'DELETE' AS m UNION ALL
    SELECT '上传文件' AS n, 'FILE_UPLOAD' AS c, '/files/upload' AS u, 'POST' AS m UNION ALL
    SELECT '浏览图库' AS n, 'FILE_PAGE' AS c, '/files/page' AS u, 'GET' AS m UNION ALL
    SELECT '商品列表' AS n, 'MERCHANT_PRODUCT_LIST' AS c, '/merchant/product/list' AS u, 'GET' AS m UNION ALL
    SELECT '发布商品' AS n, 'MERCHANT_PRODUCT_ADD' AS c, '/merchant/product' AS u, 'POST' AS m UNION ALL
    SELECT '商品详情' AS n, 'MERCHANT_PRODUCT_DETAIL' AS c, '/merchant/product/{productId}' AS u, 'GET' AS m UNION ALL
    SELECT '编辑商品' AS n, 'MERCHANT_PRODUCT_UPDATE' AS c, '/merchant/product/{productId}' AS u, 'PUT' AS m UNION ALL
    SELECT '删除商品' AS n, 'MERCHANT_PRODUCT_DELETE' AS c, '/merchant/product/{productId}' AS u, 'DELETE' AS m UNION ALL
    SELECT '上下架商品' AS n, 'MERCHANT_PRODUCT_STATUS' AS c, '/merchant/product/{productId}/status' AS u, 'PUT' AS m UNION ALL
    SELECT '查看商品图片' AS n, 'MERCHANT_PRODUCT_IMAGES' AS c, '/merchant/product/{productId}/images' AS u, 'GET' AS m UNION ALL
    SELECT '查看SKU' AS n, 'MERCHANT_SKU_LIST' AS c, '/merchant/product/{productId}/skus' AS u, 'GET' AS m UNION ALL
    SELECT '新增SKU' AS n, 'MERCHANT_SKU_ADD' AS c, '/merchant/product/{productId}/skus' AS u, 'POST' AS m UNION ALL
    SELECT '编辑SKU' AS n, 'MERCHANT_SKU_UPDATE' AS c, '/merchant/product/{productId}/skus/{skuId}' AS u, 'PUT' AS m UNION ALL
    SELECT '删除SKU' AS n, 'MERCHANT_SKU_DELETE' AS c, '/merchant/product/{productId}/skus/{skuId}' AS u, 'DELETE' AS m UNION ALL
    SELECT '分类下拉' AS n, 'MERCHANT_META_CATEGORIES' AS c, '/merchant/product/categories' AS u, 'GET' AS m UNION ALL
    SELECT '子类下拉' AS n, 'MERCHANT_META_SUB_CATEGORIES' AS c, '/merchant/product/sub-categories' AS u, 'GET' AS m UNION ALL
    SELECT '品牌下拉' AS n, 'MERCHANT_META_BRANDS' AS c, '/merchant/product/brands' AS u, 'GET' AS m UNION ALL
    SELECT '品牌树' AS n, 'MERCHANT_META_BRAND_TREE' AS c, '/merchant/product/brand-tree' AS u, 'GET' AS m UNION ALL
    SELECT '绑定商品图片' AS n, 'MERCHANT_IMAGE_BIND' AS c, '/image/bind/product' AS u, 'POST' AS m UNION ALL
    SELECT '库存列表' AS n, 'MERCHANT_INVENTORY_LIST' AS c, '/merchant/inventory' AS u, 'GET' AS m UNION ALL
    SELECT '库存详情' AS n, 'MERCHANT_INVENTORY_DETAIL' AS c, '/merchant/inventory/{inventoryId}' AS u, 'GET' AS m UNION ALL
    SELECT '调整库存' AS n, 'MERCHANT_INVENTORY_ADJUST' AS c, '/merchant/inventory/adjust' AS u, 'POST' AS m UNION ALL
    SELECT '库存变更记录' AS n, 'MERCHANT_INVENTORY_HISTORY' AS c, '/merchant/inventory/history' AS u, 'GET' AS m UNION ALL
    SELECT '设置安全库存' AS n, 'MERCHANT_INVENTORY_MIN_STOCK' AS c, '/merchant/inventory/{inventoryId}/min-stock' AS u, 'PUT' AS m UNION ALL
    SELECT '批量导入库存' AS n, 'MERCHANT_INVENTORY_IMPORT' AS c, '/merchant/inventory/import' AS u, 'POST' AS m UNION ALL
    SELECT '查看店铺资料' AS n, 'MERCHANT_SHOP_INFO_GET' AS c, '/merchant/shop/info' AS u, 'GET' AS m UNION ALL
    SELECT '修改店铺资料' AS n, 'MERCHANT_SHOP_INFO_UPDATE' AS c, '/merchant/shop/info' AS u, 'PUT' AS m UNION ALL
    SELECT '上传店铺logo' AS n, 'MERCHANT_SHOP_LOGO' AS c, '/merchant/shop/upload-logo' AS u, 'POST' AS m UNION ALL
    SELECT '上传资质材料' AS n, 'MERCHANT_SHOP_AUTH_UPLOAD' AS c, '/merchant/shop/upload-auth-material' AS u, 'POST' AS m UNION ALL
    SELECT '查看认证信息' AS n, 'MERCHANT_SHOP_AUTH_GET' AS c, '/merchant/shop/auth-info' AS u, 'GET' AS m UNION ALL
    SELECT '提交认证信息' AS n, 'MERCHANT_SHOP_AUTH_POST' AS c, '/merchant/shop/auth-info' AS u, 'POST' AS m UNION ALL
    SELECT '查看安全设置' AS n, 'MERCHANT_SHOP_SECURITY' AS c, '/merchant/shop/security-info' AS u, 'GET' AS m UNION ALL
    SELECT '修改店铺密码' AS n, 'MERCHANT_SHOP_PWD' AS c, '/merchant/shop/change-password' AS u, 'POST' AS m UNION ALL
    SELECT '设置支付密码' AS n, 'MERCHANT_SHOP_PAY_PWD_SET' AS c, '/merchant/shop/set-pay-password' AS u, 'POST' AS m UNION ALL
    SELECT '修改支付密码' AS n, 'MERCHANT_SHOP_PAY_PWD_CHANGE' AS c, '/merchant/shop/change-pay-password' AS u, 'POST' AS m UNION ALL
    SELECT '店铺看板' AS n, 'MERCHANT_SHOP_DASHBOARD' AS c, '/merchant/shop/dashboard' AS u, 'GET' AS m UNION ALL
    SELECT '最近订单' AS n, 'MERCHANT_SHOP_RECENT_ORDERS' AS c, '/merchant/shop/recent-orders' AS u, 'GET' AS m UNION ALL
    SELECT '成交趋势' AS n, 'MERCHANT_SHOP_CHART' AS c, '/merchant/shop/chart-data' AS u, 'GET' AS m UNION ALL
    SELECT '经营日历' AS n, 'MERCHANT_SHOP_CALENDAR' AS c, '/merchant/shop/calendar-data' AS u, 'GET' AS m UNION ALL
    SELECT '品类分布' AS n, 'MERCHANT_SHOP_DISTRIBUTION' AS c, '/merchant/shop/product-distribution' AS u, 'GET' AS m UNION ALL
    SELECT '订单发货' AS n, 'MERCHANT_ORDER_SHIP' AS c, '/orders/{orderId}/ship' AS u, 'POST' AS m UNION ALL
    SELECT '确认归还' AS n, 'MERCHANT_ORDER_CONFIRM_RETURN' AS c, '/orders/{orderId}/confirm-return' AS u, 'POST' AS m UNION ALL
    SELECT '退款列表' AS n, 'MERCHANT_REFUND_LIST' AS c, '/refunds/merchant/list' AS u, 'GET' AS m UNION ALL
    SELECT '处理退款' AS n, 'MERCHANT_REFUND_PROCESS' AS c, '/refunds/process' AS u, 'POST' AS m UNION ALL
    SELECT '查看个人资料' AS n, 'ADMIN_SELF_PROFILE_GET' AS c, '/user/profile' AS u, 'GET' AS m UNION ALL
    SELECT '修改个人资料' AS n, 'ADMIN_SELF_PROFILE_UPDATE' AS c, '/user/profile' AS u, 'PUT' AS m UNION ALL
    SELECT '修改登录密码' AS n, 'ADMIN_SELF_PASSWORD' AS c, '/user/password' AS u, 'PUT' AS m UNION ALL
    SELECT '上传头像' AS n, 'ADMIN_SELF_AVATAR' AS c, '/user/avatar' AS u, 'POST' AS m UNION ALL
    SELECT '上传文件' AS n, 'ADMIN_FILE_UPLOAD' AS c, '/files/upload' AS u, 'POST' AS m UNION ALL
    SELECT '浏览图库' AS n, 'ADMIN_FILE_PAGE' AS c, '/files/page' AS u, 'GET' AS m
) t
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `permission_code` FROM `permission`) x WHERE x.`permission_code` = t.c);

-- 买家角色（role_code = USER）
INSERT INTO `role_permission` (`role_id`, `permission_id`, `create_time`)
SELECT r.`role_id`, p.`permission_id`, NOW()
FROM `role` r JOIN `permission` p ON p.`permission_code` IN (
  'USER_PROFILE_GET', 'USER_PROFILE_UPDATE', 'USER_PASSWORD_UPDATE', 'USER_AVATAR_UPLOAD', 'USER_ADDRESS_LIST', 'USER_ADDRESS_ADD', 'USER_ADDRESS_UPDATE', 'USER_ADDRESS_DELETE', 'USER_ADDRESS_DEFAULT', 'CART_LIST', 'CART_ADD', 'CART_UPDATE', 'CART_DELETE', 'CART_CLEAR', 'CART_BATCH_ADD', 'CART_BATCH_DELETE', 'FAVORITE_LIST', 'FAVORITE_ADD', 'FAVORITE_REMOVE', 'FAVORITE_REMOVE_BY_ID', 'FAVORITE_BATCH_DELETE', 'FAVORITE_CHECK', 'ORDER_LIST', 'ORDER_DETAIL', 'ORDER_DETAIL_BY_NO', 'ORDER_CREATE_FROM_CART', 'ORDER_TEMP', 'ORDER_CHECK_PENDING', 'ORDER_PAY', 'ORDER_CANCEL', 'ORDER_CONFIRM_RECEIVE', 'ORDER_RETURN', 'REFUND_APPLY', 'REFUND_BY_ORDER', 'REFUND_CAN', 'EVAL_CREATE', 'EVAL_MINE', 'EVAL_DELETE', 'MESSAGE_LIST', 'MESSAGE_UNREAD', 'MESSAGE_READ', 'MESSAGE_READ_ALL', 'MESSAGE_DELETE', 'FILE_UPLOAD', 'FILE_PAGE'
) WHERE r.`role_code` = 'USER'
  AND NOT EXISTS (SELECT 1 FROM (SELECT `role_id`, `permission_id` FROM `role_permission`) rp
                  WHERE rp.`role_id` = r.`role_id` AND rp.`permission_id` = p.`permission_id`);

-- 商家角色（role_code = MERCHANT）：买家全部 + 商家专属
INSERT INTO `role_permission` (`role_id`, `permission_id`, `create_time`)
SELECT r.`role_id`, p.`permission_id`, NOW()
FROM `role` r JOIN `permission` p ON p.`permission_code` IN (
  'USER_PROFILE_GET', 'USER_PROFILE_UPDATE', 'USER_PASSWORD_UPDATE', 'USER_AVATAR_UPLOAD', 'USER_ADDRESS_LIST', 'USER_ADDRESS_ADD', 'USER_ADDRESS_UPDATE', 'USER_ADDRESS_DELETE', 'USER_ADDRESS_DEFAULT', 'CART_LIST', 'CART_ADD', 'CART_UPDATE', 'CART_DELETE', 'CART_CLEAR', 'CART_BATCH_ADD', 'CART_BATCH_DELETE', 'FAVORITE_LIST', 'FAVORITE_ADD', 'FAVORITE_REMOVE', 'FAVORITE_REMOVE_BY_ID', 'FAVORITE_BATCH_DELETE', 'FAVORITE_CHECK', 'ORDER_LIST', 'ORDER_DETAIL', 'ORDER_DETAIL_BY_NO', 'ORDER_CREATE_FROM_CART', 'ORDER_TEMP', 'ORDER_CHECK_PENDING', 'ORDER_PAY', 'ORDER_CANCEL', 'ORDER_CONFIRM_RECEIVE', 'ORDER_RETURN', 'REFUND_APPLY', 'REFUND_BY_ORDER', 'REFUND_CAN', 'EVAL_CREATE', 'EVAL_MINE', 'EVAL_DELETE', 'MESSAGE_LIST', 'MESSAGE_UNREAD', 'MESSAGE_READ', 'MESSAGE_READ_ALL', 'MESSAGE_DELETE', 'FILE_UPLOAD', 'FILE_PAGE',
  'MERCHANT_PRODUCT_LIST', 'MERCHANT_PRODUCT_ADD', 'MERCHANT_PRODUCT_DETAIL', 'MERCHANT_PRODUCT_UPDATE', 'MERCHANT_PRODUCT_DELETE', 'MERCHANT_PRODUCT_STATUS', 'MERCHANT_PRODUCT_IMAGES', 'MERCHANT_SKU_LIST', 'MERCHANT_SKU_ADD', 'MERCHANT_SKU_UPDATE', 'MERCHANT_SKU_DELETE', 'MERCHANT_META_CATEGORIES', 'MERCHANT_META_SUB_CATEGORIES', 'MERCHANT_META_BRANDS', 'MERCHANT_META_BRAND_TREE', 'MERCHANT_IMAGE_BIND', 'MERCHANT_INVENTORY_LIST', 'MERCHANT_INVENTORY_DETAIL', 'MERCHANT_INVENTORY_ADJUST', 'MERCHANT_INVENTORY_HISTORY', 'MERCHANT_INVENTORY_MIN_STOCK', 'MERCHANT_INVENTORY_IMPORT', 'MERCHANT_SHOP_INFO_GET', 'MERCHANT_SHOP_INFO_UPDATE', 'MERCHANT_SHOP_LOGO', 'MERCHANT_SHOP_AUTH_UPLOAD', 'MERCHANT_SHOP_AUTH_GET', 'MERCHANT_SHOP_AUTH_POST', 'MERCHANT_SHOP_SECURITY', 'MERCHANT_SHOP_PWD', 'MERCHANT_SHOP_PAY_PWD_SET', 'MERCHANT_SHOP_PAY_PWD_CHANGE', 'MERCHANT_SHOP_DASHBOARD', 'MERCHANT_SHOP_RECENT_ORDERS', 'MERCHANT_SHOP_CHART', 'MERCHANT_SHOP_CALENDAR', 'MERCHANT_SHOP_DISTRIBUTION', 'MERCHANT_ORDER_SHIP', 'MERCHANT_ORDER_CONFIRM_RETURN', 'MERCHANT_REFUND_LIST', 'MERCHANT_REFUND_PROCESS'
) WHERE r.`role_code` = 'MERCHANT'
  AND NOT EXISTS (SELECT 1 FROM (SELECT `role_id`, `permission_id` FROM `role_permission`) rp
                  WHERE rp.`role_id` = r.`role_id` AND rp.`permission_id` = p.`permission_id`);

-- 管理员角色（role_code = ADMIN）：只补个人中心与上传这些自助接口
INSERT INTO `role_permission` (`role_id`, `permission_id`, `create_time`)
SELECT r.`role_id`, p.`permission_id`, NOW()
FROM `role` r JOIN `permission` p ON p.`permission_code` IN (
  'ADMIN_SELF_PROFILE_GET', 'ADMIN_SELF_PROFILE_UPDATE', 'ADMIN_SELF_PASSWORD', 'ADMIN_SELF_AVATAR', 'ADMIN_FILE_UPLOAD', 'ADMIN_FILE_PAGE'
) WHERE r.`role_code` = 'ADMIN'
  AND NOT EXISTS (SELECT 1 FROM (SELECT `role_id`, `permission_id` FROM `role_permission`) rp
                  WHERE rp.`role_id` = r.`role_id` AND rp.`permission_id` = p.`permission_id`);

-- 超级管理员角色：给予根权限（/  *），一切路径都在覆盖范围内
INSERT INTO `role_permission` (`role_id`, `permission_id`, `create_time`)
SELECT r.`role_id`, p.`permission_id`, NOW() FROM `role` r JOIN `permission` p ON p.`permission_code` = 'SYSTEM_ROOT'
WHERE r.`role_code` = 'SUPER_ADMIN'
  AND NOT EXISTS (SELECT 1 FROM (SELECT `role_id`, `permission_id` FROM `role_permission`) rp
                  WHERE rp.`role_id` = r.`role_id` AND rp.`permission_id` = p.`permission_id`);
