// 管理员 API 索引文件，统一导出所有管理员相关 API。
//
// 约定：除 operations.ts 里明确标注为旧签名的 getOperationList 之外，
// 所有函数都返回 data 载荷本身（不是 { code, msg, data } 整包），
// 失败一律向上抛，错误提示由 @/axios 的拦截器统一处理。

export * from './http'
export * from './user'
export * from './merchant'
export * from './product'
export * from './category'
export * from './brand'
export * from './notice'
export * from './dashboard'
export * from './operations'
