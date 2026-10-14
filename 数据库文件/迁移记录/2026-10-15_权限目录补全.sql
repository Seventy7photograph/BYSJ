-- ============================================================================
-- 权限目录补全   2026-10-15
--
-- 背景：DynamicPermissionFilter 过去只按 user.user_type 做白名单判断，
-- permission / role_permission 两张表从未参与鉴权。修好之后（按角色授予的
-- 接口模式校验）暴露出一件事：权限目录本身不完整 —— 管理员后台在用的
-- /admin/brands 与 /admin/operations 在 permission 表里根本没有对应行。
--
-- 结论：不能为了让页面能打开就放宽校验，而要把目录补齐、把权限真正授予出去。
-- 注意：超级管理员持有根权限（permission_id = 42，url = '/'，method = '*'），
-- 一切路径都在它的覆盖范围内，因此这里只给「管理员」角色补授权。
-- ============================================================================

SET NAMES utf8mb4;

-- 1. 补齐管理员后台实际调用、但目录里缺失的接口
INSERT INTO `permission` (`permission_name`, `permission_code`, `url`, `method`, `parent_id`, `create_time`, `update_time`)
SELECT * FROM (
    SELECT '品牌管理' AS n, 'BRAND_MANAGE' AS c, '/admin/brands/**' AS u, '*' AS m, 42 AS p, NOW() AS ct, NOW() AS ut
) t
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `permission_code` FROM `permission`) x WHERE x.`permission_code` = 'BRAND_MANAGE');

INSERT INTO `permission` (`permission_name`, `permission_code`, `url`, `method`, `parent_id`, `create_time`, `update_time`)
SELECT * FROM (
    SELECT '操作日志' AS n, 'OPERATION_LOG' AS c, '/admin/operations' AS u, 'GET' AS m, 42 AS p, NOW() AS ct, NOW() AS ut
) t
WHERE NOT EXISTS (SELECT 1 FROM (SELECT `permission_code` FROM `permission`) x WHERE x.`permission_code` = 'OPERATION_LOG');

-- 2. 授予「管理员」角色（role_id = 3）
INSERT INTO `role_permission` (`role_id`, `permission_id`, `create_time`)
SELECT 3, p.`permission_id`, NOW()
FROM `permission` p
WHERE p.`permission_code` IN ('BRAND_MANAGE', 'OPERATION_LOG')
  AND NOT EXISTS (
      SELECT 1 FROM (SELECT `permission_id` FROM `role_permission` WHERE `role_id` = 3) rp
      WHERE rp.`permission_id` = p.`permission_id`
  );

-- 3. 校验：管理员角色覆盖了它实际使用的每一个接口前缀
SELECT p.`url`, p.`method`, '管理员已授权' AS 状态
FROM `permission` p
JOIN `role_permission` rp ON rp.`permission_id` = p.`permission_id` AND rp.`role_id` = 3
WHERE p.`url` LIKE '/admin%'
ORDER BY p.`url`;
