import axios from '@/axios'

/**
 * 文件上传的唯一入口。
 *
 * 重构前项目里有三条互不相干的写盘路径：
 *   1. FileUploadUtil  → /image/upload  写到 file.upload.path，返回 /images/xxx
 *   2. UserController  → /user/avatar   直接 transferTo 到 public/head，返回 /head/xxx
 *   3. ShopServiceImpl → /merchant/shop/upload-*  写到 public/auth，返回 /auth/xxx
 * 后两条绕开了 sys_image 登记表，读的时候又靠 public/ 目录碰巧能命中，
 * 换台机器或重新构建就全是死链。
 *
 * 现在统一走 /files/upload：后端落到单一存储根目录，登记进 sys_image，
 * 返回可直接使用的 URL（/uploads/yyyy/MM/xxx.ext），由后端静态映射提供。
 */

export type BizType = 'product' | 'avatar' | 'shop_logo' | 'shop_auth' | 'evaluation' | 'notice'

export interface UploadedFile {
  id: number
  url: string
  name: string
  size: number
  width: number | null
  height: number | null
}

/** 单文件上限，与后端 file.storage.max-size-mb 保持一致。 */
export const MAX_UPLOAD_MB = 10
export const ACCEPTED_IMAGE_TYPES = 'image/jpeg,image/png,image/webp,image/gif'

/**
 * 上传一张图片。失败时抛出带可读原因的错误，调用方直接展示 message。
 */
export async function uploadFile(file: File, bizType: BizType = 'product'): Promise<UploadedFile> {
  if (file.size > MAX_UPLOAD_MB * 1024 * 1024) {
    throw new Error(`单张图片不能超过 ${MAX_UPLOAD_MB}MB`)
  }
  if (file.type && !file.type.startsWith('image/')) {
    throw new Error('只能上传图片文件')
  }

  const form = new FormData()
  form.append('file', file)
  form.append('bizType', bizType)

  const res = await axios.post('/files/upload', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 60000,
  })
  const data = res?.data ?? res
  if (!data?.url) throw new Error('上传失败：服务端未返回文件地址')
  return data as UploadedFile
}

/** 批量上传，串行执行以保持与用户选择一致的顺序。 */
export async function uploadFiles(files: File[], bizType: BizType = 'product'): Promise<UploadedFile[]> {
  const out: UploadedFile[] = []
  for (const file of files) {
    out.push(await uploadFile(file, bizType))
  }
  return out
}
