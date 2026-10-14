/* 依次跑完三个验收脚本。
 * 前提：后端在 9090、前端 dev server 在 5173（或设 BASE_URL）。
 * 用法：node scripts/verify-all.cjs */
const { spawnSync } = require('node:child_process')
const path = require('node:path')

const steps = [
  ['权限矩阵（身份 × 接口）', 'verify-permissions.cjs'],
  ['主业务闭环', 'verify-business-flow.cjs'],
  ['四角色页面渲染', 'verify-pages.cjs'],
]

let failed = 0
for (const [label, file] of steps) {
  console.log(`\n================ ${label} ================`)
  const r = spawnSync(process.execPath, [path.join(__dirname, file)], { stdio: 'inherit' })
  if (r.status !== 0) {
    failed += 1
    console.log(`---- ${label} 未通过 ----`)
  }
}

console.log(`\n================ 汇总 ================`)
console.log(failed === 0 ? '三项验收全部通过' : `${failed} 项未通过`)
process.exitCode = failed ? 1 : 0
