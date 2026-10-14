// 用户API索引文件，统一导出所有用户相关API

import * as auth from './auth'
import * as shop from './shop'
import * as order from './order'
import * as cart from './cart'
import * as favorite from './favorite'
import * as address from './address'
import evaluation from './evaluation'

export {
  auth,
  // 商品查询统一走 shop（/shop/products、/shop/categories 等），
  // 原来的 product.ts 与它重复且路径已失效，已删除。
  shop,
  order,
  cart,
  favorite,
  address,
  evaluation
}
