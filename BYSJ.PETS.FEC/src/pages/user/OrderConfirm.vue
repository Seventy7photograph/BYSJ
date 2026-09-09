<template>
  <div class="order-confirm-page">
    <div class="page-header">
      <h1>确认订单</h1>
      <el-steps :active="1" align-center>
        <el-step title="确认订单" />
        <el-step title="支付" />
        <el-step title="完成" />
      </el-steps>
    </div>

    <div v-loading="loading" class="order-content">
      <!-- 租赁商品特有选项 -->
      <div v-if="hasRentalProducts" class="rental-options-section">
        <h3>租赁选项</h3>

        <!-- 取货方式 -->
        <div class="option-item">
          <div class="option-label">取货方式</div>
          <el-radio-group v-model="pickupMethod">
            <el-radio label="store_pickup">线下到店自取</el-radio>
            <el-radio label="delivery">快递配送</el-radio>
          </el-radio-group>
        </div>

        <!-- 租赁时间选择 -->
        <div class="option-item">
          <div class="option-label">租赁时间</div>
          <el-date-picker
            v-model="rentalDateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            :disabled-date="disabledDate"
            @change="onRentalDateChange"
            style="width: 100%;"
          />
        </div>

        <!-- 归还方式 -->
        <div class="option-item">
          <div class="option-label">归还方式</div>
          <el-radio-group v-model="returnMethod">
            <el-radio label="store_return">线下到店归还</el-radio>
            <el-radio label="delivery_return">快递归还</el-radio>
          </el-radio-group>
        </div>
      </div>

      <!-- 收货地址 - 仅当不是租赁商品或租赁商品选择快递配送时显示 -->
      <div v-if="!hasRentalProducts || pickupMethod === 'delivery'" class="address-section">
        <h3>收货地址</h3>
        <div class="address-list">
          <!-- 只显示选择的收货地址 -->
          <div v-if="selectedAddress" class="address-item active">
            <div class="address-info">
              <div class="recipient">
                <span class="name">{{ selectedAddress.recipient }}</span>
                <span class="phone">{{ selectedAddress.phone }}</span>
                <el-tag v-if="selectedAddress.isDefault" size="small" type="primary">默认</el-tag>
              </div>
              <div class="full-address">{{ selectedAddress.province }}{{ selectedAddress.city }}{{ selectedAddress.district }}{{ selectedAddress.detail }}</div>
            </div>
            <div class="address-actions">
              <el-button type="text" @click="showAddressSelectDialog = true">更多地址</el-button>
            </div>
          </div>
          <!-- 没有选择地址时显示添加地址按钮 -->
          <div v-else class="add-address" @click="showAddAddressDialog = true; resetAddressForm()">
            <el-icon><Plus /></el-icon>
            <span>添加新地址</span>
          </div>
        </div>
      </div>

      <!-- 线下店铺地址 - 仅当租赁商品选择到店自取时显示 -->
      <div v-if="hasRentalProducts && pickupMethod === 'store_pickup'" class="store-address-section">
        <h3>线下店铺地址</h3>
        <div class="store-address-item">
          <div class="store-info">
            <div class="store-name">摄影器材租赁店</div>
            <div class="store-address">广东省广州市从化区广从南路548号广州软件学院</div>
            <div class="store-phone">联系电话：18888888888</div>
          </div>
        </div>
      </div>

      <!-- 地址选择对话框 -->
      <el-dialog
        v-model="showAddressSelectDialog"
        title="选择收货地址"
        width="500px"
      >
        <div class="address-select-list">
          <div
            v-for="address in addresses"
            :key="address.addressId"
            class="address-item"
            :class="{ active: selectedAddressId === address.addressId }"
            @click="selectAddress(address.addressId)"
          >
            <div class="address-info">
              <div class="recipient">
                <span class="name">{{ address.recipient }}</span>
                <span class="phone">{{ address.phone }}</span>
                <el-tag v-if="address.isDefault" size="small" type="primary">默认</el-tag>
              </div>
              <div class="full-address">{{ address.province }}{{ address.city }}{{ address.district }}{{ address.detail }}</div>
            </div>
            <div class="address-actions">
              <el-button type="text" @click.stop="editAddress(address)">编辑</el-button>
            </div>
          </div>
          <div class="add-address" @click="showAddAddressDialog = true; showAddressSelectDialog = false; resetAddressForm()">
            <el-icon><Plus /></el-icon>
            <span>添加新地址</span>
          </div>
        </div>
        <template #footer>
          <el-button @click="showAddressSelectDialog = false">取消</el-button>
          <el-button type="primary" @click="confirmAddressSelection">确认</el-button>
        </template>
      </el-dialog>

      <!-- 商品信息 -->
      <div class="products-section">
        <h3>商品信息</h3>
        <div class="products-list">
          <div v-for="item in orderItems" :key="item.productId" class="product-item">
            <img :src="item.productImage" :alt="item.productName" class="product-image">
            <div class="product-info">
              <div class="product-name-wrapper">
                <div class="product-name">{{ item.productName }}</div>
                <el-tag v-if="item.productType === 3" type="success" size="small" class="rental-tag">
                  租赁
                </el-tag>
                <el-tag v-else-if="item.productType === 2" type="warning" size="small" class="second-hand-tag">
                  二手
                </el-tag>
                <el-tag v-else type="primary" size="small" class="new-tag">
                  全新
                </el-tag>
              </div>
              <div class="product-brand" v-if="item.brandName">品牌：{{ item.brandName }}</div>
              <div class="product-deposit" v-if="item.productType === 3 && item.deposit">押金：¥{{ item.deposit }}</div>
              <!-- <div class="product-specs" v-if="item.specifications">
                {{ formatSpecifications(item.specifications) }}
              </div> -->
            </div>
            <div class="product-price">¥{{ item.unitPrice }}</div>
            <div class="product-quantity">
              <div v-if="item.productType === 3">
                <div class="quantity-control">
                  <el-input-number
                    v-model="item.leaseTerm"
                    :min="1"
                    :max="90"
                    size="small"
                    style="width: 120px"
                    @change="onLeaseTermChange(item)"
                  />
                </div>
                <div class="quantity-label">租赁天数</div>
              </div>
              <div v-else>
                <div class="quantity-control">
                  <el-input-number
                    v-model="item.quantity"
                    :min="1"
                    :max="item.stock || 999"
                    size="small"
                    style="width: 120px"
                    @change="onQuantityChange(item)"
                  />
                </div>
                <div class="quantity-label">购买数量</div>
              </div>
            </div>
            <div class="product-total">¥{{ calculateItemTotal(item).toFixed(2) }}</div>
          </div>
        </div>
      </div>

      <!-- 订单信息 -->
      <div class="order-info-section">
        <h3>订单信息</h3>
        <div class="info-items">
          <div class="info-item" v-if="hasRentalProducts">
            <span class="label">租赁天数：</span>
            <span class="value">{{ orderItems[0].leaseTerm }}天</span>
          </div>
          <div class="info-item">
            <span class="label">商品总租金：</span>
            <span class="value">¥{{ (orderInfo.totalAmount - totalDeposit).toFixed(2) }}</span>
          </div>
          <div class="info-item" v-if="hasRentalProducts">
            <span class="label">押金总计：</span>
            <span class="value">¥{{ totalDeposit.toFixed(2) }}</span>
          </div>
          <div class="info-item">
            <span class="label">运费：</span>
            <span class="value">¥{{ orderInfo.shippingFee.toFixed(2) }}</span>
          </div>
          <div class="info-item total">
            <span class="label">应付金额：</span>
            <span class="value">¥{{ (orderInfo.totalAmount + orderInfo.shippingFee).toFixed(2) }}</span>
          </div>
        </div>
      </div>

      <!-- 支付方式 -->
      <div class="payment-section">
        <h3>支付方式</h3>
        <el-radio-group v-model="paymentMethod">
          <el-radio label="wechat">
            <div class="payment-option">
              <!-- <img src="/public/wechat-pay.png" alt="微信支付" class="payment-icon"> -->
              <span>微信支付</span>
            </div>
          </el-radio>
          <el-radio label="alipay">
            <div class="payment-option">
              <!-- <img src="/public/alipay.png" alt="支付宝" class="payment-icon"> -->
              <span>支付宝</span>
            </div>
          </el-radio>
        </el-radio-group>
      </div>

      <!-- 提交订单 -->
      <div class="submit-section">
      <div class="submit-info">
        <span class="total-amount">实付款：¥{{ (orderInfo.totalAmount + orderInfo.shippingFee).toFixed(2) }}</span>
      </div>
      <el-button
        type="primary"
        size="large"
        :loading="submitting"
        @click="submitOrder"
      >
        提交订单
      </el-button>
    </div>
    </div>

    <!-- 添加/编辑地址对话框 -->
      <el-dialog
        v-model="showAddAddressDialog"
        :title="editingAddress ? '编辑地址' : '添加地址'"
        width="500px"
      >
        <el-form :model="addressForm" label-width="80px" :rules="addressRules" ref="addressFormRef">
          <el-form-item label="收货人" prop="recipient">
            <el-input v-model="addressForm.recipient" placeholder="请输入收货人姓名" />
          </el-form-item>
          <el-form-item label="手机号" prop="phone">
            <el-input v-model="addressForm.phone" placeholder="请输入手机号" />
          </el-form-item>
          <el-form-item label="所在地区" prop="region">
            <el-cascader
              v-model="addressForm.region"
              :options="regionOptions"
              placeholder="请选择省市区"
              @change="onRegionChange"
            />
          </el-form-item>
          <el-form-item label="详细地址" prop="detail">
            <el-input
              v-model="addressForm.detail"
              type="textarea"
              placeholder="请输入详细地址"
              :rows="3"
            />
          </el-form-item>
          <el-form-item>
            <el-checkbox v-model="addressForm.isDefault">设为默认地址</el-checkbox>
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="cancelAddressEdit">取消</el-button>
          <el-button type="danger" @click="deleteAddress" v-if="editingAddress">删除</el-button>
          <el-button type="primary" @click="saveAddress">保存</el-button>
        </template>
      </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { regionData } from 'element-china-area-data'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import axios from '@/axios'
import { useUserStore } from '@/stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// 订单数据
const orderInfo = ref({
  totalAmount: 0,
  shippingFee: 0
})
const orderItems = ref([])
const loading = ref(true)
const submitting = ref(false)

// 地址相关
const addresses = ref([])
const selectedAddressId = ref(null)
const selectedAddress = ref(null) // 当前选择的地址对象
const showAddAddressDialog = ref(false)
const showAddressSelectDialog = ref(false) // 地址选择对话框
const editingAddress = ref(null)
const addressFormRef = ref(null)
const addressForm = ref({
  recipient: '',
  phone: '',
  region: [],
  province: '',
  city: '',
  district: '',
  detail: '',
  isDefault: false
})

// 地址表单验证规则
const addressRules = ref({
  recipient: [
    { required: true, message: '请输入收货人姓名', trigger: 'blur' }
  ],
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ],
  region: [
    { required: true, message: '请选择省市区', trigger: 'change' }
  ],
  detail: [
    { required: true, message: '请输入详细地址', trigger: 'blur' }
  ]
})

// 使用element-china-area-data库提供的全国省市区数据
const regionOptions = ref(regionData)

// 支付方式
const paymentMethod = ref('wechat')

// 计算属性：是否包含租赁商品
const hasRentalProducts = ref(false)

// 计算属性：总押金金额
const totalDeposit = ref(0)

// 租赁商品特有选项
const pickupMethod = ref('delivery') // 取货方式：store_pickup-线下自取, delivery-快递配送
const returnMethod = ref('store_return') // 归还方式：store_return-线下归还, delivery_return-快递归还
const rentalDateRange = ref([]) // 租赁日期范围
const rentalDays = ref(0) // 计算的租赁天数

// 禁用日期（今天之前的日期）
const disabledDate = (time) => {
  return time.getTime() < Date.now() - 8.64e7
}

// 租赁日期范围变化处理
const onRentalDateChange = (dateRange) => {
  if (dateRange && dateRange.length === 2) {
    const startDate = dateRange[0]
    const endDate = dateRange[1]

    // 计算租赁天数
    const diffTime = endDate.getTime() - startDate.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

    // 更新租赁天数
    rentalDays.value = diffDays

    // 更新订单项目中的租赁天数
    if (orderItems.value.length > 0 && orderItems.value[0].productType === 3) {
      orderItems.value[0].leaseTerm = diffDays
      updateOrderTotal()
    }
  }
}

// 计算总押金
const calculateTotalDeposit = () => {
  let deposit = 0
  orderItems.value.forEach(item => {
    if (item.productType === 3 && item.deposit) {
      deposit += parseFloat(item.deposit)
    }
  })
  totalDeposit.value = deposit
  hasRentalProducts.value = orderItems.value.some(item => item.productType === 3)
}

// 获取订单信息
const fetchOrderInfo = async () => {
  try {
    loading.value = true
    // 同时检查路径参数和查询参数中的orderId
    // 从支付页面返回修改时，orderId作为查询参数传递
    const orderId = route.params.orderId || route.query.orderId
    const productIdsStr = route.query.productIds
    const leaseTerm = route.query.leaseTerm // 获取租赁天数
    const startDate = route.query.startDate // 获取开始日期
    const endDate = route.query.endDate // 获取结束日期

    if (orderId) {
      // 从订单列表或支付页面返回，获取已创建的订单信息
      const res = await axios.get(`/orders/${orderId}`)

      // 适配后端返回的数据结构
      orderInfo.value = {
        totalAmount: res.data.order.totalAmount || 0,
        shippingFee: res.data.order.shippingFee || 0
      }
      orderItems.value = res.data.orderItems || []
    } else if (productIdsStr) {
      // 从购物车进入，获取临时订单信息
      const productIds = productIdsStr.split(',').map(id => parseInt(id))
      const quantity = route.query.quantity ? parseInt(route.query.quantity) : 1 // 获取数量参数
      const res = await axios.post('/orders/temp', {
        productIds: productIds,
        quantity: quantity, // 传递数量参数
        leaseTerm: leaseTerm ? parseInt(leaseTerm) : 1 // 传递租赁天数，默认为1天
      })

      orderInfo.value = {
        totalAmount: res.data.totalAmount || 0,
        shippingFee: res.data.shippingFee || 0
      }
      orderItems.value = res.data.orderItems || []
    }

    // 获取地址列表
    const addressRes = await axios.get('/user/addresses')
    addresses.value = addressRes.data || []
    // 设置默认选中的地址
    const defaultAddress = addresses.value.find(addr => addr.isDefault)
    if (defaultAddress) {
      selectedAddressId.value = defaultAddress.addressId
      selectedAddress.value = defaultAddress
    } else if (addresses.value.length > 0) {
      // 如果没有默认地址，选择第一个地址
      selectedAddressId.value = addresses.value[0].addressId
      selectedAddress.value = addresses.value[0]
    } else {
      selectedAddressId.value = null
      selectedAddress.value = null
    }

    // 计算总押金和判断是否包含租赁商品
    calculateTotalDeposit()

    // 同步租赁日期范围
    if (startDate && endDate) {
      rentalDateRange.value = [new Date(startDate), new Date(endDate)]
    }
  } catch (error) {
    console.error('获取订单信息失败:', error)
    ElMessage.error('获取订单信息失败')
  } finally {
    loading.value = false
  }
}

// 选择地址
const selectAddress = (addressId) => {
  selectedAddressId.value = addressId
  // 更新选中的地址对象
  selectedAddress.value = addresses.value.find(addr => addr.addressId === addressId) || null
}

// 确认地址选择
const confirmAddressSelection = () => {
  showAddressSelectDialog.value = false
}

// 编辑地址
const editAddress = (address) => {
  editingAddress.value = address
  // 设置表单值，包括省市区拆分
  addressForm.value = {
    ...address,
    region: [address.province, address.city, address.district],
    isDefault: address.isDefault === 1
  }
  showAddAddressDialog.value = true
}

// 地区选择变化
const onRegionChange = (value) => {
  if (value && value.length === 3) {
    addressForm.value.province = value[0]
    addressForm.value.city = value[1]
    addressForm.value.district = value[2]
  }
}

// 取消地址编辑
const cancelAddressEdit = () => {
  ElMessageBox.confirm('取消编辑会丢失当前输入内容，确定取消吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    showAddAddressDialog.value = false
    resetAddressForm()
  }).catch(() => {
    // 用户取消取消操作
  })
}

// 重置地址表单
const resetAddressForm = () => {
  addressForm.value = {
    recipient: '',
    phone: '',
    region: [],
    province: '',
    city: '',
    district: '',
    detail: '',
    isDefault: false
  }
  editingAddress.value = null
  if (addressFormRef.value) {
    addressFormRef.value.resetFields()
  }
}

// 删除地址
const deleteAddress = () => {
  if (!editingAddress.value) return

  ElMessageBox.confirm('确定要删除该地址吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'danger'
  }).then(() => {
    axios.delete(`/user/addresses/${editingAddress.value.addressId}`)
      .then(() => {
        ElMessage.success('地址删除成功')
        showAddAddressDialog.value = false
        // 重新获取地址列表
        fetchOrderInfo()
        resetAddressForm()
      })
      .catch(error => {
        console.error('删除地址失败:', error)
        ElMessage.error('删除地址失败')
      })
  }).catch(() => {
    // 用户取消删除操作
  })
}

// 保存地址
const saveAddress = async () => {
  try {
    // 表单验证
    await addressFormRef.value.validate()

    // 准备提交数据
    const submitData = {
      recipient: addressForm.value.recipient,
      phone: addressForm.value.phone,
      province: addressForm.value.province,
      city: addressForm.value.city,
      district: addressForm.value.district,
      detail: addressForm.value.detail,
      isDefault: addressForm.value.isDefault ? 1 : 0
    }

    if (editingAddress.value) {
      // 更新地址
      await axios.put(`/user/addresses`, {
        ...submitData,
        addressId: editingAddress.value.addressId
      })
      ElMessage.success('地址更新成功')
    } else {
      // 添加新地址
      await axios.post('/user/addresses', submitData)
      ElMessage.success('地址添加成功')
    }

    showAddAddressDialog.value = false

    // 重新获取地址列表
    const res = await axios.get('/user/addresses')
    addresses.value = res.data || []

    // 重新设置选中的地址
    if (editingAddress.value) {
      // 如果是编辑地址，保持当前选中
      selectedAddress.value = addresses.value.find(addr => addr.addressId === editingAddress.value.addressId) || null
    } else {
      // 如果是添加新地址，选中新地址
      const newAddress = addresses.value.find(addr =>
        addr.recipient === addressForm.value.recipient && addr.phone === addressForm.value.phone
      )
      if (newAddress) {
        selectedAddressId.value = newAddress.addressId
        selectedAddress.value = newAddress
      }
    }

    // 重置表单
    resetAddressForm()
  } catch (error) {
    console.error('保存地址失败:', error)
    if (error.name === 'Error' && error.message === 'Request failed with status code 403') {
      ElMessage.error('保存地址失败：无权访问')
    } else if (error.name === 'ValidationError') {
      // 表单验证错误已由element-plus处理
    } else {
      ElMessage.error('保存地址失败')
    }
  }
}

// 格式化规格参数
const formatSpecifications = (specs) => {
  return Object.entries(specs)
    .map(([key, value]) => `${key}: ${value}`)
    .join(' | ')
};

// 减少购买数量
const decreaseQuantity = (item) => {
  if (item.quantity > 1) {
    item.quantity--;
    updateOrderTotal();
  }
};

// 增加购买数量
const increaseQuantity = (item) => {
  if (item.quantity < (item.stock || 999)) {
    item.quantity++;
    updateOrderTotal();
  }
};

// 减少租赁天数
const decreaseLeaseTerm = (item) => {
  if (item.leaseTerm > 1) {
    item.leaseTerm--;
    updateOrderTotal();
  }
};

// 增加租赁天数
const increaseLeaseTerm = (item) => {
  if (item.leaseTerm < 90) {
    item.leaseTerm++;
    updateOrderTotal();
  }
};

// 购买数量变化时的处理
const onQuantityChange = (item) => {
  if (item.quantity < 1) {
    item.quantity = 1;
  } else if (item.quantity > (item.stock || 999)) {
    item.quantity = item.stock || 999;
  }
  updateOrderTotal();
};

// 租赁天数变化时的处理
const onLeaseTermChange = (item) => {
  if (item.leaseTerm < 1) {
    item.leaseTerm = 1;
  } else if (item.leaseTerm > 90) {
    item.leaseTerm = 90;
  }
  updateOrderTotal();
};

// 计算商品总价
const calculateItemTotal = (item) => {
  if (item.productType === 3) {
    // 租赁商品：单价 * 租赁天数
    return item.unitPrice * item.leaseTerm;
  } else {
    // 普通商品：单价 * 数量
    return item.unitPrice * item.quantity;
  }
};

// 更新订单总价
const updateOrderTotal = () => {
  let total = 0;
  orderItems.value.forEach(item => {
    total += calculateItemTotal(item);
  });
  orderInfo.value.totalAmount = total;
  calculateTotalDeposit();
};

// 提交订单
const submitOrder = async () => {
  if (!selectedAddressId.value) {
    ElMessage.warning('请选择收货地址')
    return
  }

  try {
    submitting.value = true
    // 注意：当用户从支付页面返回修改时，我们需要创建新订单，而不是直接跳转到原订单的支付页面
    // 因为用户可能已经修改了订单信息
    const orderId = route.query.orderId
    let productIdsStr = route.query.productIds

    // 从orderItems中提取productIds和leaseTerm（当用户从支付页面返回修改时，orderItems中包含了商品信息）
    let productIds
    let leaseTerm = 1 // 默认租赁天数为1天
    let quantity = 1 // 默认购买数量为1

    // 尝试从订单项目中获取租赁天数和购买数量
    if (orderItems.value.length > 0) {
      // 对于租赁商品，使用订单项目中的租赁天数
      if (orderItems.value[0].productType === 3 && orderItems.value[0].leaseTerm) {
        leaseTerm = orderItems.value[0].leaseTerm
      }
      // 对于普通商品，使用订单项目中的购买数量
      if (orderItems.value[0].productType !== 3 && orderItems.value[0].quantity) {
        quantity = orderItems.value[0].quantity
      }
    }

    if (orderItems.value.length > 0) {
      // 从orderItems中提取productIds
      productIds = orderItems.value.map(item => item.productId)
      productIdsStr = productIds.join(',')
    } else if (productIdsStr) {
      // 从购物车进入，获取productIds
      productIds = productIdsStr.split(',').map(id => parseInt(id))
    } else {
      // 无法获取商品信息，提示用户
      ElMessage.error('无法获取商品信息，请返回重新选择商品')
      submitting.value = false
      return
    }

    let finalOrderId

    // 无论是否有orderId，都需要重新创建订单，因为用户可能已经修改了订单信息
    // 但是，我们需要检查是否有未付款的订单，避免重复创建
    // 1. 检查是否已有未付款的订单
    const checkRes = await axios.post('/orders/check-pending', {
      productIds: productIds
    })

      if (checkRes.data.hasPendingOrder) {
        // 已有未付款的订单
        if (checkRes.data.orderInfoMatches) {
          // 订单信息一致，提示用户继续支付
          ElMessageBox.confirm('您已有一个未付款的订单，是否继续支付？', '提示', {
            confirmButtonText: '继续支付',
            cancelButtonText: '取消',
            type: 'warning'
          }).then(() => {
            // 跳转到已存在的订单支付页面
            router.push({
              path: `/order/payment/${checkRes.data.orderId}`,
              query: { paymentMethod: paymentMethod.value }
            })
          }).catch(() => {
            // 用户取消操作
          })
          return
        } else {
          // 订单信息不一致，提示用户取消旧订单并创建新订单
          ElMessageBox.confirm('您已有一个未付款的订单，但订单信息已变更，是否取消旧订单并创建新订单？', '提示', {
            confirmButtonText: '确认',
            cancelButtonText: '取消',
            type: 'warning'
          }).then(async () => {
            // 取消旧订单 - 使用正确的POST方法和路径
            await axios.post(`/orders/${checkRes.data.orderId}/cancel`)
            // 创建新订单
            const createRes = await axios.post('/orders/create-from-cart', {
              productIds: productIds,
              addressId: selectedAddressId.value,
              quantity: quantity, // 传递数量参数
              leaseTerm: leaseTerm // 传递租赁天数
            })
            finalOrderId = createRes.data.orderId
            // 跳转到新订单的支付页面
            router.push({
              path: `/order/payment/${finalOrderId}`,
              query: { paymentMethod: paymentMethod.value }
            })
          }).catch(() => {
            // 用户取消操作
          })
          return
        }
      } else {
        // 没有未付款的订单，直接创建新订单
        // 1. 创建订单
        const createRes = await axios.post('/orders/create-from-cart', {
          productIds: productIds,
          addressId: selectedAddressId.value,
          quantity: quantity, // 传递数量参数
          leaseTerm: leaseTerm // 传递租赁天数
        })

        finalOrderId = createRes.data.orderId

        // 2. 跳转到支付页面，携带支付方式参数
        router.push({
          path: `/order/payment/${finalOrderId}`,
          query: { paymentMethod: paymentMethod.value }
        })
      }
  } catch (error) {
    console.error('提交订单失败:', error)
    ElMessage.error('提交订单失败')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  fetchOrderInfo()
})
</script>

<style scoped>
.order-confirm-page {
  max-width: 1000px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
  text-align: center;
}

.page-header h1 {
  margin-bottom: 20px;
  color: #333;
}

.order-content {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
}

.rental-options-section,
.address-section,
.store-address-section,
.products-section,
.order-info-section,
.payment-section {
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e0e0e0;
}

h3 {
  margin-bottom: 15px;
  color: #333;
  font-size: 16px;
}

.address-list {
  display: grid;
  gap: 15px;
}

.address-item {
  display: flex;
  align-items: center;
  padding: 15px;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s;
}

.address-item.active {
  border-color: #409EFF;
  background: #f0f9ff;
}

.address-item:hover {
  border-color: #409EFF;
}

.address-info {
  flex: 1;
}

.recipient {
  margin-bottom: 8px;
}

.recipient .name {
  font-weight: bold;
  margin-right: 10px;
}

.recipient .phone {
  color: #666;
  margin-right: 10px;
}

.full-address {
  color: #666;
  line-height: 1.4;
}

.add-address {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  border: 2px dashed #e0e0e0;
  border-radius: 4px;
  cursor: pointer;
  color: #666;
  transition: all 0.3s;
}

.add-address:hover {
  border-color: #409EFF;
  color: #409EFF;
}

.products-list {
  border: 1px solid #e0e0e0;
  border-radius: 4px;
}

.product-item {
  display: flex;
  align-items: center;
  padding: 15px;
  border-bottom: 1px solid #e0e0e0;
}

.product-item:last-child {
  border-bottom: none;
}

.product-image {
  width: 60px;
  height: 60px;
  object-fit: contain;
  margin-right: 15px;
}

.product-info {
  flex: 1;
}

.product-name-wrapper {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
}

.product-name {
  font-weight: 500;
  margin-right: 8px;
}

.second-hand-tag {
  margin-left: 8px;
}

.product-specs {
  font-size: 12px;
  color: #666;
}

.product-price,
.product-quantity,
.product-total {
  width: 120px;
  text-align: center;
  padding: 0 10px;
}

.product-price {
  color: #666;
}

.product-total {
  color: #ff4d4f;
  font-weight: bold;
  font-size: 16px;
}

.quantity-control {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 5px;
}

.quantity-label {
  font-size: 12px;
  color: #666;
  text-align: center;
}

.info-items {
  max-width: 300px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  padding: 8px 0;
}

.info-item.total {
  border-top: 1px solid #e0e0e0;
  font-size: 18px;
  font-weight: bold;
  color: #ff4d4f;
}

.payment-option {
  display: flex;
  align-items: center;
  gap: 10px;
}

.payment-icon {
  width: 24px;
  height: 24px;
}

.submit-section {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 20px;
  padding-top: 20px;
}

.total-amount {
  font-size: 20px;
  color: #ff4d4f;
  font-weight: bold;
}

@media (max-width: 768px) {
  .order-content {
    padding: 20px;
  }

  .product-item {
    flex-wrap: wrap;
  }

  .product-info {
    order: 2;
    width: 100%;
    margin-top: 10px;
  }

  .product-price, .product-quantity, .product-total {
    order: 1;
    width: auto;
    margin: 0 10px;
  }

  .submit-section {
    flex-direction: column;
    gap: 15px;
  }
}
</style>
