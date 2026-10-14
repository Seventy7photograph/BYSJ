# 安全策略

## 报告漏洞

发现安全问题请不要开公开 Issue，直接邮件联系维护者：`3324879861@qq.com`。
请尽量附上复现步骤、影响范围与你的判断，我会尽快回复并给出处理计划。

## 支持范围

只对 `main` 分支上的最新版本提供安全修复。

## 已实现的安全措施

| 面向 | 做法 |
| --- | --- |
| SQL 注入 | 全部使用 MyBatis 参数化查询，仓库中 `${}` 出现 0 次 |
| XSS | 前端不使用 `v-html` 与 `innerHTML`，插值由 Vue 默认转义；后端对跨角色可见的自由文本入库前剔除脚本类标记 |
| 认证 | JWT 配合 Spring Security；密码以 BCrypt(12) 存储 |
| 验证码 | 图形验证码与密码重置验证码都存 Redis 并带 TTL，重置码额外校验绑定邮箱 |
| 授权 | 两层：Spring Security 按角色粗筛，`DynamicPermissionFilter` 按 `role_permission` 授予的「方法 + 路径模式」逐条比对，无授权即拒绝 |
| 会话 | 未登录返回 401、已登录无权限返回 403；令牌过期由前端统一清理并跳转登录 |
| 上传 | 单一入口、扩展名白名单、真实解码校验、大小与像素上限、按日期分目录、统一登记图库 |
| 响应头 | CSP（不含 `unsafe-eval`）、`X-Content-Type-Options`、`X-Frame-Options`、`Referrer-Policy`、`Permissions-Policy` |
| 数据暴露 | `User.password` 标注 `@JsonIgnore`；日志不打印密码与令牌 |
| 导出 | CSV 对 `= + - @` 开头的单元格做公式注入防护 |

## 部署注意

1. `application.yml` 里的数据库口令、`jwt.secret`、`sa-token.jwt-secret-key`
   都是开发默认值，上线前必须替换，并改为从环境变量注入。
2. 建议用反向代理统一提供静态资源与 `/api`，只开放 HTTPS。
3. 上传目录不要放在 Web 应用的可执行路径下；当前实现只按扩展名与真实解码校验
   内容，未做病毒扫描。
4. Redis 建议设置密码并限制可访问来源，验证码与权限缓存都在其中。
