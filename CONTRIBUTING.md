# 贡献指南

感谢愿意花时间改进这个项目。下面是几条约定，目的是让改动容易 review、也容易回退。

## 开发环境

搭建步骤见 [README.md](README.md)。最小要求：JDK 17+、Maven 3.9+、Node.js 20+、
MySQL 8 与 Redis。

## 分支与提交

- 分支从 `main` 切出，命名用 `feat/xxx`、`fix/xxx`、`docs/xxx`、`refactor/xxx`。
- 提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)：

  ```
  <type>(<scope>): <简述>

  <为什么这么改，以及这样改会产生什么影响>
  ```

  常用 type：`feat`、`fix`、`refactor`、`perf`、`docs`、`style`、`test`、
  `build`、`ci`、`chore`。scope 用模块名，例如 `shop`、`order`、`inventory`、
  `auth`、`admin`。
- 一个提交只做一件事，重构与功能改动不要混在同一个提交里。
- 破坏性改动在 type 后加 `!`，并在正文写清迁移办法。

## 代码约定

### 前端

- 颜色、间距、圆角、动效一律取自 `src/styles/tokens.css` 的变量，不写死数值。
- 状态文案与色调统一走 `src/constants/domain.ts`，不要在新页面里再抄一份映射表。
- 金额、日期、库存、图片地址统一走 `src/utils/format.ts`。
- 图标统一走 `src/components/ui/AppIcon.vue` 的登记表。
- 页面必须有加载态、空态、错误态；危险操作要有二次确认与按钮 loading。
- 提交前跑 `npm run build`（含 `vue-tsc` 类型检查）与 `npm run lint`。

### 后端

- SQL 写在 `mapper/xml/` 下，参数一律用 `#{}`，不要用 `${}` 拼接。
- 涉及多表写入的方法加 `@Transactional(rollbackFor = Exception.class)`。
- 库存这类会被并发修改的字段，用带条件的原子更新（`WHERE stock >= ?`），
  不要"查出来再写回去"。
- 拿不到登录身份时明确失败，不要兜底成某个默认用户 ID。
- 不要用 `System.out.println` 调试，用 `@Slf4j` 的 `log`。

### 数据库

- 结构变更写成 `数据库文件/迁移记录/` 下的独立脚本，文件名为
  `YYYY-MM-DD_简述.sql`，并在 `数据库文件/README.md` 的表格里补一行。
- 脚本要可重复执行（用 `IF NOT EXISTS` / `WHERE NOT EXISTS` 之类），
  并且在空库上按顺序验证过。

## 提交前自检

```bash
cd BYSJ.PETS.BEC && mvn -o compile
cd BYSJ.PETS.FEC && npm run build
node scripts/verify-all.cjs      # 需要后端与前端已启动
```

## 拉取请求

PR 描述里写清三件事：改了什么、为什么、怎么验证的。
涉及界面的改动请附桌面与移动端截图。
