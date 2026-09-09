<template>
  <div class="merchant-product-edit">
    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item :to="'/merchant-dashboard'">后台首页</el-breadcrumb-item>
      <el-breadcrumb-item :to="'/merchant-dashboard/product-management'">商品管理</el-breadcrumb-item>
      <el-breadcrumb-item>编辑商品</el-breadcrumb-item>
    </el-breadcrumb>

    <h2 class="page-title">编辑商品</h2>

    <!-- 商品类型切换 -->
    <div class="product-type-selector">
      <el-segmented v-model="productType" :options="productTypeOptions" @change="handleProductTypeChange" />
    </div>

    <!-- 商品编辑表单 -->
    <el-form
      ref="productFormRef"
      :model="productForm"
      :rules="productFormRules"
      :validate-on-rule-change="false"
      label-width="120px"
      class="product-form"
    >
      <!-- 商品分类 -->
      <el-form-item label="商品分类" prop="categoryId">
        <el-tree-select
          v-model="productForm.categoryId"
          :data="categoriesTree"
          placeholder="请选择商品分类"
          :props="{ label: 'name', value: 'id', children: 'children' }"
        />
      </el-form-item>

      <!-- 品牌选择器 -->
      <el-form-item label="品牌" prop="brand">
        <el-tree-select
          v-model="productForm.brand"
          :data="brandTree"
          placeholder="请选择商品品牌"
          :props="{ label: 'name', value: 'id', children: 'children' }"
        />
      </el-form-item>

      <!-- 型号输入 -->
      <el-form-item label="型号" prop="model">
        <el-input v-model="productForm.model" placeholder="请输入商品型号" />
      </el-form-item>

      <!-- 商品描述 -->
      <el-form-item label="商品描述" prop="description">
        <el-input
          v-model="productForm.description"
          type="textarea"
          :rows="4"
          placeholder="请输入商品描述"
        />
      </el-form-item>

      <!-- 商品图片 -->
      <el-form-item label="商品图片" prop="images">
        <el-upload
          v-model:file-list="fileList"
          :action="'/api/image/upload'"
          list-type="picture-card"
          :auto-upload="true"
          :on-preview="handlePictureCardPreview"
          :on-remove="handleRemove"
          :on-success="handleUploadSuccess"
          :on-error="handleUploadError"
          :before-upload="beforeUpload"
          accept="image/jpeg,image/png"
        >
          <el-icon><Plus /></el-icon>
          <template #tip>
            <div class="el-upload__tip">
              请上传商品图片，支持 JPG、PNG 格式，单张不超过 5MB
            </div>
          </template>
        </el-upload>
        <el-dialog v-model="dialogVisible">
          <img w-full :src="dialogImageUrl" alt="Preview Image" />
        </el-dialog>
      </el-form-item>

      <!-- 原价 -->
      <el-form-item label="原价" prop="originalPrice">
        <el-input-number
          v-model="productForm.originalPrice"
          :min="0"
          :step="0.01"
          :precision="2"
          placeholder="请输入商品原价"
        />
      </el-form-item>

      <!-- 安全库存 -->
      <el-form-item label="安全库存" prop="minStock">
        <el-input-number
          v-model="productForm.minStock"
          :min="0"
          :step="1"
          placeholder="请输入安全库存"
        />
      </el-form-item>

      <!-- 全新商品表单字段 -->
      <template v-if="productType === 'new'">
        <el-form-item label="商品价格" prop="price">
          <el-input-number
            v-model="productForm.price"
            :min="0"
            :step="0.01"
            :precision="2"
            placeholder="请输入商品价格"
          />
        </el-form-item>

        <el-form-item label="商品库存" prop="stock">
          <el-input-number
            v-model="productForm.stock"
            :min="0"
            :step="1"
            placeholder="请输入商品库存"
          />
        </el-form-item>

        <el-form-item label="颜色" prop="color">
          <el-input v-model="productForm.color" placeholder="请输入商品颜色" />
        </el-form-item>
      </template>

      <!-- 二手商品表单字段 -->
      <template v-else-if="productType === 'used'">
        <el-form-item label="商品价格" prop="price">
          <el-input-number
            v-model="productForm.price"
            :min="0"
            :step="0.01"
            :precision="2"
            placeholder="请输入商品价格"
          />
        </el-form-item>

        <el-form-item label="商品库存" prop="stock">
          <el-input-number
            v-model="productForm.stock"
            :min="0"
            :step="1"
            placeholder="请输入商品库存"
          />
        </el-form-item>

        <el-form-item label="商品成色" prop="condition">
          <el-slider
            v-model="productForm.condition"
            :min="80"
            :max="100"
            :step="5"
            :marks="{ 80: '8成新', 85: '8.5成新', 90: '9成新', 95: '9.5成新', 100: '9.9成新' }"
          />
        </el-form-item>

        <el-form-item label="使用时长" prop="usageDuration">
          <el-input v-model="productForm.usageDuration" placeholder="请输入使用时长，如：1年" />
        </el-form-item>

        <el-form-item label="维修记录" prop="repairHistory">
          <el-radio-group v-model="productForm.repairHistory">
            <el-radio label="0">无维修记录</el-radio>
            <el-radio label="1">有维修记录</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="配件清单" prop="accessories">
          <el-input
            v-model="productForm.accessories"
            type="textarea"
            :rows="3"
            placeholder="请输入商品配件清单"
          />
        </el-form-item>
      </template>

      <!-- 租赁商品表单字段 -->
      <template v-else-if="productType === 'rental'">
        <el-form-item label="日租金" prop="price">
          <el-input-number
            v-model="productForm.price"
            :min="0"
            :step="0.01"
            :precision="2"
            placeholder="请输入日租金"
          />
        </el-form-item>

        <el-form-item label="起租天数" prop="minRentalDays">
          <el-input-number
            v-model="productForm.minRentalDays"
            :min="1"
            :step="1"
            placeholder="请输入起租天数"
          />
        </el-form-item>

        <el-form-item label="库存数量" prop="stock">
          <el-input-number
            v-model="productForm.stock"
            :min="0"
            :step="1"
            placeholder="请输入库存数量"
          />
        </el-form-item>
      </template>

      <!-- 提交按钮 -->
      <el-form-item>
        <el-button type="primary" @click="submitForm">保存修改</el-button>
        <el-button @click="resetForm">重置表单</el-button>
        <el-button @click="handleCancel">取消</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import axios from '@/axios'

const router = useRouter()
const route = useRoute()

// 商品ID
const productId = ref(route.params.id as string)

// 商品类型
const productType = ref('new')
const productTypeOptions = [
  { label: '全新商品', value: 'new' },
  { label: '二手商品', value: 'used' },
  { label: '租赁商品', value: 'rental' }
]

// 商品分类和品牌数据
const categoriesTree = ref<any[]>([])
const brandTree = ref<any[]>([])

// 商品表单
const productForm = reactive({
  productId: '',
  categoryId: '',
  brand: 0,
  model: '',
  description: '',
  images: [],
  imageIds: [],
  originalPrice: 0,
  price: 0,
  stock: 0,
  minStock: 10,
  // 全新商品字段
  color: '',
  // 二手商品字段
  condition: 90,
  usageDuration: '',
  repairHistory: '0',
  accessories: '',
  // 租赁商品字段
  minRentalDays: 1
})

// 表单验证规则
const productFormRules = {
  categoryId: [
    { required: true, message: '请选择商品分类', trigger: 'change' }
  ],
  brand: [
    { required: true, message: '请选择商品品牌', trigger: 'change' }
  ],
  model: [
    { required: true, message: '请输入商品型号', trigger: 'blur' }
  ],
  description: [
    { required: true, message: '请输入商品描述', trigger: 'blur' },
    { min: 10, max: 1000, message: '商品描述长度在 10 到 1000 个字符', trigger: 'blur' }
  ],
  originalPrice: [
    { required: true, message: '请输入商品原价', trigger: 'blur' },
    { type: 'number', min: 0.01, message: '商品原价必须大于 0', trigger: 'blur' }
  ],
  price: [
    { required: true, message: '请输入商品价格/日租金', trigger: 'blur' },
    { type: 'number', min: 0.01, message: '价格必须大于 0', trigger: 'blur' }
  ],
  stock: [
    { required: true, message: '请输入商品库存', trigger: 'blur' },
    { type: 'number', min: 0, message: '商品库存必须大于等于 0', trigger: 'blur' }
  ],
  minStock: [
    { required: true, message: '请输入安全库存', trigger: 'blur' },
    { type: 'number', min: 0, message: '安全库存必须大于等于 0', trigger: 'blur' }
  ]
}

// 表单引用
const productFormRef = ref()

// 文件上传相关
interface UploadFile {
  uid: string;
  name: string;
  url: string;
  status?: string;
}

const fileList = ref<UploadFile[]>([])
const dialogVisible = ref(false)
const dialogImageUrl = ref('')

// 处理图片预览
const handlePictureCardPreview = (uploadFile: UploadFile) => {
  dialogImageUrl.value = uploadFile.url
  dialogVisible.value = true
}

// 处理图片删除
const handleRemove = (uploadFile: UploadFile) => {
  const index = fileList.value.findIndex(file => file.uid === uploadFile.uid)
  if (index > -1) {
    fileList.value.splice(index, 1)
    // 从imageIds中移除对应的ID
    // 处理不同的响应结构
    let imageIdToRemove: number | undefined
    if (uploadFile.response && uploadFile.response.data && uploadFile.response.data.id) {
      imageIdToRemove = uploadFile.response.data.id
    } else if (uploadFile.response && uploadFile.response.id) {
      imageIdToRemove = uploadFile.response.id
    }

    if (imageIdToRemove !== undefined) {
      const imageIdIndex = productForm.imageIds.indexOf(imageIdToRemove)
      if (imageIdIndex > -1) {
        productForm.imageIds.splice(imageIdIndex, 1)
      }
    } else {
      // 如果没有响应信息，根据索引删除（作为备选方案）
      productForm.imageIds.splice(index, 1)
    }

    console.log('删除图片后，当前imageIds:', productForm.imageIds)
  }
}

// 处理图片上传成功
const handleUploadSuccess = (response: any, uploadFile: any) => {
  console.log('图片上传响应:', response)
  // 调整响应结构，适配后端返回格式
  const actualResponse = response.data ? response.data : response
  if (actualResponse && actualResponse.id) {
    console.log('SysImage对象:', actualResponse)
    console.log('id:', actualResponse.id)
    console.log('storagePath:', actualResponse.storagePath)

    const imageId = actualResponse.id
    const storagePath = actualResponse.storagePath

    if (imageId == null) {
      ElMessage.error('图片上传失败：imageId 为 null')
      return
    }

    // 设置上传文件的URL，用于预览
    uploadFile.url = storagePath
    // 添加到imageIds数组
    productForm.imageIds.push(imageId)
    console.log('当前imageIds:', productForm.imageIds)
  } else {
    ElMessage.error('图片上传失败')
  }
}

// 处理图片上传错误
const handleUploadError = (error: any) => {
  console.error('图片上传错误:', error)
  ElMessage.error('图片上传失败')
}

// 上传前校验
const beforeUpload = (file: any) => {
  const isJPG = file.type === 'image/jpeg'
  const isPNG = file.type === 'image/png'
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isJPG && !isPNG) {
    ElMessage.error('上传图片只能是 JPG/PNG 格式!')
    return false
  }
  if (!isLt5M) {
    ElMessage.error('上传图片大小不能超过 5MB!')
    return false
  }
  return true
}

// 处理商品类型变化
const handleProductTypeChange = () => {
  // 保留公共字段
  const commonFields = {
    productId: productForm.productId,
    categoryId: productForm.categoryId,
    brand: productForm.brand,
    model: productForm.model,
    description: productForm.description,
    images: productForm.images,
    imageIds: productForm.imageIds,
    originalPrice: productForm.originalPrice,
    minStock: productForm.minStock
  }

  // 重置其他字段
  Object.assign(productForm, {
    ...commonFields,
    price: 0,
    stock: 0,
    // 全新商品字段
    color: '',
    // 二手商品字段
    condition: 90,
    usageDuration: '',
    repairHistory: '0',
    accessories: '',
    // 租赁商品字段
    minRentalDays: 1
  })
}

// 加载分类树
const loadCategories = async () => {
  try {
    const response = await axios.get('/merchant/product/categories')
    console.log('分类API响应:', response)

    if (response && response.code === 200) {
      let categoryData = response.data

      if (categoryData && typeof categoryData === 'object') {
        if (categoryData.categoryTree) {
          categoryData = categoryData.categoryTree
        } else if (categoryData.categories) {
          categoryData = categoryData.categories
        }
      }

      if (Array.isArray(categoryData) && categoryData.length > 0) {
        await nextTick()
        categoriesTree.value = categoryData
        console.log('categoriesTree最终值:', categoriesTree.value)
      } else {
        console.error('分类数据为空或不是数组:', categoryData)
        categoriesTree.value = []
      }
    } else {
      console.error('分类API返回错误:', response)
      categoriesTree.value = []
    }
  } catch (error) {
    console.error('加载分类树失败:', error)
    ElMessage.error('加载分类树失败：' + (error as Error).message)
    categoriesTree.value = []
  }
}

// 加载品牌树
const loadBrandTree = async () => {
  try {
    const response = await axios.get('/merchant/product/brand-tree')
    console.log('品牌API响应:', response)

    if (response && response.code === 200) {
      let brandData = response.data

      if (brandData && typeof brandData === 'object') {
        if (brandData.brandTree) {
          brandData = brandData.brandTree
        } else if (Array.isArray(brandData)) {
          brandData = brandData
        }
      }

      if (Array.isArray(brandData) && brandData.length > 0) {
        await nextTick()
        brandTree.value = brandData
        console.log('brandTree最终值:', brandTree.value)
      } else {
        console.error('品牌数据为空或不是数组:', brandData)
        brandTree.value = []
      }
    } else {
      console.error('品牌API返回错误:', response)
      brandTree.value = []
    }
  } catch (error) {
    console.error('加载品牌树失败:', error)
    ElMessage.error('加载品牌树失败：' + (error as Error).message)
    brandTree.value = []
  }
}

// 加载商品详情
const loadProductDetail = async () => {
  try {
    const response = await axios.get(`/merchant/product/${productId.value}`)
    console.log('商品详情响应:', response)

    if (response && response.code === 200 && response.data) {
      const productData = response.data

      console.log('商品详情数据:', productData)

      // 填充表单数据
      productForm.productId = productData.productId || ''
      productForm.categoryId = productData.categoryId || ''
      productForm.brand = productData.brand || 0
      productForm.model = productData.model || ''
      productForm.description = productData.description || ''
      productForm.originalPrice = productData.originalPrice || 0
      productForm.price = productData.price || 0
      productForm.stock = productData.stock || 0
      productForm.minStock = productData.minStock || 10

      // 根据商品类型设置productType
      if (productData.productType === 1) {
        productType.value = 'new'
        productForm.color = productData.color || ''
      } else if (productData.productType === 2) {
        productType.value = 'used'
        productForm.condition = productData.condition || 90
        productForm.usageDuration = productData.usageDuration || ''
        productForm.repairHistory = productData.repairHistory || '0'
        productForm.accessories = productData.accessories || ''
      } else if (productData.productType === 3) {
        productType.value = 'rental'
        productForm.minRentalDays = productData.minRentalDays || 1
        productForm.deposit = productData.deposit || 0
      }

      console.log('表单数据:', productForm)
      console.log('商品类型:', productType.value)

      // 加载商品图片
      await loadProductImages()
    } else {
      ElMessage.error('获取商品详情失败')
    }
  } catch (error) {
    console.error('加载商品详情失败:', error)
    ElMessage.error('加载商品详情失败：' + (error as Error).message)
  }
}

// 加载商品图片
const loadProductImages = async () => {
  try {
    const response = await axios.get(`/merchant/product/${productId.value}/images`)
    console.log('商品图片响应:', response)

    if (response && response.code === 200 && response.data) {
      const images = response.data

      // 填充图片列表
      fileList.value = images.map((img: any) => ({
        uid: img.id || img.imageId,
        name: img.storagePath || img.imagePath,
        url: img.storagePath || img.imagePath,
        response: { data: img }
      }))

      // 填充imageIds
      productForm.imageIds = images.map((img: any) => img.id || img.imageId)
      console.log('商品图片:', fileList.value)
      console.log('图片IDs:', productForm.imageIds)
    }
  } catch (error) {
    console.error('加载商品图片失败:', error)
  }
}

// 提交表单
const submitForm = () => {
  if (!productFormRef.value) return

  productFormRef.value.validate((valid: boolean) => {
    if (valid) {
      // 根据商品类型映射到数据库中的product_type
      let productTypeValue = 1
      if (productType.value === 'new') {
        productTypeValue = 1
      } else if (productType.value === 'used') {
        productTypeValue = 2
      } else if (productType.value === 'rental') {
        productTypeValue = 3
      }

      // 构建商品数据
      const productData = {
        categoryId: productForm.categoryId,
        brand: productForm.brand,
        model: productForm.model,
        description: productForm.description,
        imageIds: productForm.imageIds,
        originalPrice: productForm.originalPrice,
        price: productForm.price,
        stock: productForm.stock,
        minStock: productForm.minStock,
        productType: productTypeValue,
        // 全新商品字段
        color: productForm.color,
        // 二手商品字段
        condition: productForm.condition,
        usageDuration: productForm.usageDuration,
        repairHistory: productForm.repairHistory,
        accessories: productForm.accessories,
        // 租赁商品字段
        minRentalDays: productForm.minRentalDays,
        deposit: productForm.deposit
      }

      console.log('提交的商品数据:', productData)

      // 提交商品数据到服务器
      axios.put(`/merchant/product/${productId.value}`, productData)
        .then(response => {
          if (response && response.code === 200) {
            ElMessage.success('商品修改成功')
            router.push('/merchant-dashboard/product-management')
          } else {
            ElMessage.error(response?.msg || '商品修改失败')
          }
        })
        .catch(error => {
          console.error('商品修改失败:', error)
          ElMessage.error('商品修改失败：' + (error as Error).message)
        })
    } else {
      ElMessage.warning('请完整填写表单信息')
      return false
    }
  })
}

// 重置表单
const resetForm = () => {
  productFormRef.value?.resetFields()
}

// 取消编辑
const handleCancel = () => {
  router.push('/merchant-dashboard/product-management')
}

// 页面加载时初始化
onMounted(async () => {
  try {
    await Promise.all([
      loadCategories(),
      loadBrandTree()
    ])
    await loadProductDetail()
  } catch (error) {
    console.error('初始化失败:', error)
  }
})
</script>

<style scoped>
.merchant-product-edit {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #333;
}

.product-type-selector {
  margin-bottom: 30px;
  padding: 20px;
  background-color: #f5f7fa;
  border-radius: 8px;
}

.product-form {
  background-color: #fff;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

/* 优化表单字段间距 */
.product-form .el-form-item {
  margin-bottom: 20px;
}

.breadcrumb {
  margin-bottom: 20px;
}

.el-upload__tip {
  font-size: 12px;
  color: #606266;
  margin-top: 8px;
}
</style>
