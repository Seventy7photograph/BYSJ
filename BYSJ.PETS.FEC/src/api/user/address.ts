import axios from '@/axios'

/**
 * 收货地址接口，对齐 UserAddressController：
 *   GET    /user/addresses              列表
 *   POST   /user/addresses              新增
 *   PUT    /user/addresses              更新（按 body 里的 addressId）
 *   DELETE /user/addresses/{addressId}  删除
 *   PUT    /user/addresses/{id}/default 设为默认
 *
 * 原来的 getAddressDetail 走 GET /user/addresses/{addressId}，后端并没有这个
 * 映射（只有上面五个），调用必然 404；地址本身字段很少，编辑直接从列表里取，
 * 所以这个函数删掉，不再保留一个打不通的入口。
 */

export interface AddressItem {
  addressId: number
  userId?: number
  recipient: string
  phone: string
  province: string
  city: string
  district: string
  detail: string
  /** 数据库里是 0/1 的整数，不是布尔值 */
  isDefault: number
}

export interface AddressPayload {
  addressId?: number
  recipient: string
  phone: string
  province: string
  city: string
  district: string
  detail: string
  isDefault: number
}

/** 拆掉 Result 外壳。 */
function unwrap(res: any): any {
  return res?.data ?? res
}

/** 地址列表。后端已按「默认地址优先、新地址在前」排序。 */
export async function getAddressList(): Promise<AddressItem[]> {
  const res = await axios.get('/user/addresses')
  const data = unwrap(res)
  return Array.isArray(data) ? (data as AddressItem[]) : []
}

/** 新增地址。 */
export async function addAddress(payload: AddressPayload): Promise<AddressItem> {
  const res = await axios.post('/user/addresses', payload)
  return unwrap(res)
}

/** 更新地址。 */
export async function updateAddress(payload: AddressPayload): Promise<AddressItem> {
  const res = await axios.put('/user/addresses', payload)
  return unwrap(res)
}

/** 删除地址。 */
export async function deleteAddress(addressId: number) {
  const res = await axios.delete(`/user/addresses/${addressId}`)
  return unwrap(res)
}

/** 设为默认地址。 */
export async function setDefaultAddress(addressId: number) {
  const res = await axios.put(`/user/addresses/${addressId}/default`)
  return unwrap(res)
}
