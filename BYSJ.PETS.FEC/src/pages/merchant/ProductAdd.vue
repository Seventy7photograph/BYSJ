<template>
  <div class="merchant-product-add">
    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item :to="'/merchant-dashboard'">后台首页</el-breadcrumb-item>
      <el-breadcrumb-item :to="'/merchant-dashboard/product-management'">商品管理</el-breadcrumb-item>
      <el-breadcrumb-item>
        {{ productType === 'new' ? '发布全新商品' : productType === 'used' ? '发布二手商品' : '发布租赁商品' }}
      </el-breadcrumb-item>
    </el-breadcrumb>

    <h2 class="page-title">商品发布</h2>

    <!-- 商品类型切换 -->
    <div class="product-type-selector">
      <el-segmented v-model="productType" :options="productTypeOptions" @change="handleProductTypeChange" />
    </div>

    <!-- 商品发布表单 -->
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

      <!-- 品牌选择器（独立的form-item，修复嵌套问题） -->
      <el-form-item label="品牌" prop="brand">
        <el-tree-select
          v-model="productForm.brand"
          :data="brandTree"
          placeholder="请选择商品品牌"
          :props="{ label: 'name', value: 'id', children: 'children' }"
        />
      </el-form-item>

      <!-- 型号输入（所有商品类型都需要） -->
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

        <el-form-item label="押金" prop="deposit">
          <el-input-number
            v-model="productForm.deposit"
            :min="0"
            :step="0.01"
            :precision="2"
            placeholder="请输入押金金额"
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

      <!-- SKU管理 -->
      <el-form-item label="SKU管理">
        <el-button type="primary" @click="addSku" size="small">添加SKU</el-button>
        <el-table v-if="productForm.skus && productForm.skus.length > 0" :data="productForm.skus" border style="margin-top: 10px;">
          <el-table-column prop="attribute" label="属性" width="150">
            <template #default="scope">
              <el-input v-model="scope.row.attribute" placeholder="如：颜色" />
            </template>
          </el-table-column>
          <el-table-column prop="value" label="属性值" width="150">
            <template #default="scope">
              <el-input v-model="scope.row.value" placeholder="如：黑色" />
            </template>
          </el-table-column>
          <el-table-column prop="price" label="价格" width="120">
            <template #default="scope">
              <el-input-number v-model="scope.row.price" :min="0" :step="0.01" :precision="2" />
            </template>
          </el-table-column>
          <el-table-column prop="stock" label="库存" width="120">
            <template #default="scope">
              <el-input-number v-model="scope.row.stock" :min="0" :step="1" />
            </template>
          </el-table-column>
          <el-table-column label="操作" width="100">
            <template #default="scope">
              <el-button type="danger" size="small" @click="removeSku(scope.$index)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div v-else class="no-sku-tip">暂无SKU，点击添加SKU按钮开始添加</div>
      </el-form-item>

      <!-- 提交按钮 -->
      <el-form-item>
        <el-button type="primary" @click="submitForm">发布商品</el-button>
        <el-button @click="resetForm">重置表单</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, watch, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import axios from '@/axios'

const router = useRouter()
const route = useRoute()

// 商品类型
const productType = ref(route.query.type as string || 'new')
const productTypeOptions = [
  { label: '全新商品', value: 'new' },
  { label: '二手商品', value: 'used' },
  { label: '租赁商品', value: 'rental' }
]

// 商品分类和品牌数据
const categoriesTree = ref<any[]>([]) // 树形分类数据
const brandTree = ref<any[]>([]) // 树形品牌数据
const categoryValue = ref<any[]>([]) // 分类选中值
const brandValue = ref<any[]>([]) // 品牌选中值

// 添加调试监听，查看categoriesTree的变化
watch(categoriesTree, (newValue) => {
  console.log('categoriesTree变化:', newValue)
  console.log('categoriesTree长度:', newValue.length)
}, { deep: true })

// 定义类型接口
interface UploadFile {
  uid: string;
  name: string;
  url: string;
  status?: string;
}

interface ProductSku {
  attribute: string;
  value: string;
  price: number;
  stock: number;
}

interface ProductForm {
  categoryId: string;
  brand: number | null;
  model: string;
  description: string;
  images: string[];
  imageIds: number[]; // 存储图片ID
  originalPrice: number;
  price: number;
  stock: number;
  minStock: number;
  skus: ProductSku[];
  // 全新商品字段
  color: string;
  // 二手商品字段
  condition: number;
  usageDuration: string;
  repairHistory: string;
  accessories: string;
  // 租赁商品字段
  deposit: number;
  minRentalDays: number;
}

// 商品表单
const productForm = reactive<ProductForm>({
  categoryId: '',
  brand: null,
  model: '',
  description: '',
  images: [],
  imageIds: [], // 存储图片ID
  originalPrice: 0,
  price: 0,
  stock: 0,
  minStock: 10,
  skus: [],
  // 全新商品字段
  color: '',
  // 二手商品字段
  condition: 90,
  usageDuration: '',
  repairHistory: '0',
  accessories: '',
  // 租赁商品字段
  deposit: 0,
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
const fileList = ref<UploadFile[]>([])
const dialogVisible = ref(false)
const dialogImageUrl = ref('')

// 处理图片预览
const handlePictureCardPreview = (uploadFile: UploadFile) => {
  dialogImageUrl.value = uploadFile.url
  dialogVisible.value = true
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
      ElMessage.error('图片上传失败：imageId为空')
      return
    }

    uploadFile.url = storagePath
    // 确保images数组和imageIds数组同步
    productForm.images.push(storagePath)
    productForm.imageIds.push(imageId)
    console.log('当前imageIds数组:', productForm.imageIds)
    console.log('当前images数组:', productForm.images)
  } else {
    ElMessage.error('图片上传失败：' + (actualResponse?.msg || '未知错误'))
  }
}

// 处理图片上传失败
const handleUploadError = (error: any) => {
  console.error('图片上传失败:', error)
  ElMessage.error('图片上传失败')
}

// 上传前验证
const beforeUpload = (file: File) => {
  const isJPG = file.type === 'image/jpeg' || file.type === 'image/png'
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isJPG) {
    ElMessage.error('只能上传JPG/PNG格式的图片')
  }
  if (!isLt5M) {
    ElMessage.error('图片大小不能超过5MB')
  }

  return isJPG && isLt5M
}

// 处理图片删除
const handleRemove = (uploadFile: UploadFile) => {
  const index = fileList.value.findIndex(file => file.uid === uploadFile.uid)
  if (index > -1) {
    fileList.value.splice(index, 1)
  }
  // 同时从productForm.images数组中移除该图片URL
  if (uploadFile.url) {
    const imageIndex = productForm.images.indexOf(uploadFile.url)
    if (imageIndex > -1) {
      productForm.images.splice(imageIndex, 1)
    }
  }
}

// 处理商品类型变化
const handleProductTypeChange = () => {
  // 重置表单，只保留公共字段
  const commonFields = {
    categoryId: productForm.categoryId,
    model: productForm.model,
    description: productForm.description,
    originalPrice: productForm.originalPrice,
    minStock: productForm.minStock
  }

  // 重置表单
  Object.assign(productForm, {
    ...commonFields,
    price: 0,
    stock: 0,
    brand: null,
    images: [],
    skus: [],
    // 全新商品字段
    color: '',
    // 二手商品字段
    condition: 90,
    usageDuration: '',
    repairHistory: '0',
    accessories: '',
    // 租赁商品字段
    deposit: 0,
    minRentalDays: 1
  })

  // 重置文件列表
  fileList.value = []
}

// ========== 修复TS报错：补充缺失的handleCategoryChange函数 ==========
const handleCategoryChange = (value: any) => {
  console.log('分类选择变化:', value)
  if (value) {
    productForm.categoryId = value.toString()
    console.log('选中的分类ID:', productForm.categoryId)
  }
}

// ========== 修复TS报错：补充缺失的handleBrandChange函数 ==========
const handleBrandChange = (value: any) => {
  console.log('品牌选择变化:', value)
  if (value) {
    productForm.brand = value
    console.log('选中的品牌ID:', productForm.brand)
  }
}

// 添加SKU
const addSku = () => {
  productForm.skus.push({
    attribute: '',
    value: '',
    price: 0,
    stock: 0
  } as ProductSku)
}

// 删除SKU
const removeSku = (index: number) => {
  productForm.skus.splice(index, 1)
}

// 提交表单
const submitForm = () => {
  if (!productFormRef.value) return

  productFormRef.value.validate((valid: boolean) => {
    if (valid) {
      // 检查是否有图片未上传完成
      const hasUploadingImages = fileList.value.some(file => file.status === 'uploading')
      if (hasUploadingImages) {
        ElMessage.warning('还有图片正在上传中，请等待上传完成后再提交')
        return false
      }

      // 检查是否上传了图片
      if (productForm.images.length === 0) {
        ElMessage.warning('请至少上传一张商品图片')
        return false
      }

      // 构建商品数据
      // 根据商品类型映射到数据库中的product_type
      let productTypeDb = 0
      if (productType.value === 'new') {
        productTypeDb = 1
      } else if (productType.value === 'used') {
        productTypeDb = 2
      } else if (productType.value === 'rental') {
        productTypeDb = 3
      }

      // 验证必填字段
      if (!productForm.categoryId) {
        ElMessage.error('请选择商品分类')
        return false
      }
      if (productForm.brand === null || productForm.brand === 0) {
        ElMessage.error('请选择商品品牌')
        return false
      }

      const productData = {
        model: productForm.model,
        brand: productForm.brand,
        categoryId: productForm.categoryId,
        productType: productTypeDb,
        condition: productForm.condition,
        originalPrice: productForm.originalPrice,
        price: productForm.price,
        stock: productForm.stock,
        minStock: productForm.minStock,
        minRentalDays: productForm.minRentalDays,
        deposit: productForm.deposit,
        isOnShelf: 1,
        quality: productForm.condition.toString(),
        description: productForm.description,
        imageIds: productForm.imageIds
      }

      console.log('提交的商品数据:', productData)

      // 提交商品数据到服务器
      axios.post('/merchant/product', productData)
        .then(response => {
          ElMessage.success('商品发布成功')
          router.push('/merchant-dashboard/product-management')
        })
        .catch(error => {
          ElMessage.error('商品发布失败：' + error.message)
        })
    } else {
      ElMessage.warning('请完整填写表单信息')
      return false
    }
  })
}

// 重置表单
const resetForm = () => {
  if (!productFormRef.value) return
  productFormRef.value.resetFields()
  fileList.value = []
  productForm.skus = []
}

// 加载商品分类数据
const loadCategories = async () => {
  try {
    console.log('开始加载商品分类数据...')
    // 1. 先清空旧数据，避免缓存干扰
    categoriesTree.value = []

    const response = await axios.get('/merchant/product/categories')
    console.log('分类API响应:', response)

    if (response && response.code === 200 && response.data) {
      const categoryData = response.data
      console.log('分类数据:', categoryData)

      if (categoryData.categoryTree && Array.isArray(categoryData.categoryTree)) {
        console.log('原始分类树:', categoryData.categoryTree)

        const cleanEmptyChildren = (item: any) => {
          const result = {
            name: item.name,
            value: item.value,
            id: item.id
          }
          if (item.children && Array.isArray(item.children) && item.children.length > 0) {
            result.children = item.children.map(cleanEmptyChildren)
          }
          return result
        }

        const cleanedData = categoryData.categoryTree.map(cleanEmptyChildren)
        await nextTick()
        categoriesTree.value = cleanedData
        console.log('categoriesTree最终值:', categoriesTree.value)
        console.log('categoriesTree长度:', categoriesTree.value.length)
      } else {
        console.error('categoryTree不存在或不是数组:', categoryData)
        categoriesTree.value = []
      }
    } else {
      console.error('分类API返回错误:', response)
      categoriesTree.value = []
    }
  } catch (error) {
    console.error('加载商品分类失败:', error)
    ElMessage.error('加载商品分类失败：' + (error as Error).message)
    categoriesTree.value = []
  }
}

// 加载品牌树形结构
const loadBrandTree = async () => {
  try {
    console.log('开始加载品牌树数据...')
    // 1. 先清空旧数据
    brandTree.value = []

    const response = await axios.get('/merchant/product/brand-tree')
    console.log('品牌API响应:', response)

    if (response && response.code === 200 && response.data) {
      const brandResponseData = response.data
      console.log('品牌原始数据:', brandResponseData)

      let brandData: any[] = []
      if (brandResponseData.brandTree && Array.isArray(brandResponseData.brandTree)) {
        brandData = brandResponseData.brandTree
      } else if (Array.isArray(brandResponseData)) {
        brandData = brandResponseData
      }

      console.log('品牌树数据:', brandData)
      console.log('品牌数据长度:', brandData.length)

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

// 页面加载时初始化
onMounted(async () => {
  try {
    await Promise.all([
      loadCategories(),
      loadBrandTree()
    ])
    console.log('分类和品牌数据加载完成')
    console.log('最终categoriesTree:', categoriesTree.value)
    console.log('最终brandTree:', brandTree.value)
  } catch (error) {
    console.error('加载数据时出错:', error)
  }
})
</script>

<style scoped>
.merchant-product-add {
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

/* 特别优化二手商品表单字段间距 */
.product-form .el-form-item:nth-of-type(10), /* 商品成色 */
.product-form .el-form-item:nth-of-type(11), /* 使用时长 */
.product-form .el-form-item:nth-of-type(12), /* 维修记录 */
.product-form .el-form-item:nth-of-type(13)  /* 配件清单 */
{
  margin-bottom: 25px;
}

/* 优化滑块组件的上下间距 */
.product-form .el-slider {
  margin-top: 10px;
  margin-bottom: 10px;
}

/* 优化文本域组件的上下间距 */
.product-form .el-textarea {
  margin-top: 5px;
}

.no-sku-tip {
  color: #909399;
  text-align: center;
  padding: 20px;
  background-color: #f5f7fa;
  border-radius: 4px;
  margin-top: 10px;
}
</style>
