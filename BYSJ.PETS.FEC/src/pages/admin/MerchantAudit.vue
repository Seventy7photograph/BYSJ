<template>
  <div class="merchant-audit">
    <h2>商家认证审核</h2>
    <el-card shadow="hover" class="filter-card">
      <div class="filter-form">
        <el-form :inline="true" :model="searchForm" class="demo-form-inline">
          <el-form-item label="用户名">
            <el-input v-model="searchForm.username" placeholder="请输入用户名" clearable />
          </el-form-item>
          <el-form-item label="店铺名称">
            <el-input v-model="searchForm.shopName" placeholder="请输入店铺名称" clearable />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="resetForm">重置</el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-card>
    <el-card shadow="hover" class="table-card">
      <el-table
        :data="auditList"
        v-loading="loading"
        style="width: 100%"
        stripe
      >
        <el-table-column prop="userId" label="商家ID" width="100" />
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="shopName" label="店铺名称" />
        <el-table-column prop="shopStatus" label="店铺状态" width="120">
          <template #default="scope">
            <el-tag :type="getStatusTagType(scope.row.shopStatus)">
              {{ getShopStatusText(scope.row.shopStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号" />
        <el-table-column label="认证材料" width="150">
          <template #default="scope">
            <el-button type="primary" size="small" @click="viewAuthMaterials(scope.row)">
              查看
            </el-button>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="申请时间" width="200" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button
              v-if="scope.row.shopStatus === 2"
              type="success"
              size="small"
              @click="handleApprove(scope.row)"
            >
              审核通过
            </el-button>
            <el-button
              v-if="scope.row.shopStatus === 2"
              type="danger"
              size="small"
              @click="handleReject(scope.row)"
            >
              审核驳回
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="total"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 审核驳回对话框 -->
    <el-dialog
      v-model="rejectDialogVisible"
      title="审核驳回"
      width="500px"
    >
      <el-form :model="rejectForm" label-position="top">
        <el-form-item label="驳回原因" required>
          <el-input
            v-model="rejectForm.rejectReason"
            type="textarea"
            :rows="4"
            placeholder="请输入审核驳回原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="rejectDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmReject">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 认证材料查看对话框 -->
    <el-dialog
      v-model="materialsDialogVisible"
      title="认证材料"
      width="800px"
    >
      <div class="materials-content">
        <div class="material-item">
            <h3>营业执照</h3>
            <div class="material-image">
              <el-image
                v-if="currentMaterials.businessLicense"
                :src="currentMaterials.businessLicense"
                alt="营业执照"
                class="license-image"
                fit="contain"
                :preview-src-list="[currentMaterials.businessLicense]"
              />
              <div v-else class="no-license">无营业执照图片</div>
            </div>
          </div>
          <div class="material-item">
            <h3>法人身份证正面</h3>
            <div class="material-image">
              <el-image
                v-if="currentMaterials.legalIdFront"
                :src="currentMaterials.legalIdFront"
                alt="法人身份证正面"
                class="license-image"
                fit="contain"
                :preview-src-list="[currentMaterials.legalIdFront]"
              />
              <div v-else class="no-license">无身份证正面图片</div>
            </div>
          </div>
          <div class="material-item">
            <h3>法人身份证反面</h3>
            <div class="material-image">
              <el-image
                v-if="currentMaterials.legalIdBack"
                :src="currentMaterials.legalIdBack"
                alt="法人身份证反面"
                class="license-image"
                fit="contain"
                :preview-src-list="[currentMaterials.legalIdBack]"
              />
              <div v-else class="no-license">无身份证反面图片</div>
            </div>
          </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import axios from '@/axios'
import { ElMessage } from 'element-plus'

// 页面状态
const loading = ref(false)
const auditList = ref<any[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

// 搜索表单
const searchForm = reactive({
  username: '',
  shopName: ''
})

// 审核驳回对话框
const rejectDialogVisible = ref(false)
const rejectForm = reactive({
  rejectReason: ''
})
const currentAuditItem = ref<any>(null)

// 认证材料查看对话框
const materialsDialogVisible = ref(false)
const currentMaterials = ref({
  businessLicense: '',
  legalIdFront: '',
  legalIdBack: ''
})

// 加载待审核商家列表
const loadAuditList = async () => {
  loading.value = true
  try {
    const response = await axios.get('/admin/merchants/audit', {
      params: {
        page: currentPage.value,
        pageSize: pageSize.value,
        username: searchForm.username,
        shopName: searchForm.shopName
      }
    })
    auditList.value = response.data.records || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载待审核商家列表失败:', error)
    ElMessage.error('加载待审核商家列表失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取待审核商家列表
onMounted(() => {
  loadAuditList()
})

// 查询
const handleSearch = () => {
  currentPage.value = 1
  loadAuditList()
}

// 重置表单
const resetForm = () => {
  searchForm.username = ''
  searchForm.shopName = ''
  handleSearch()
}

// 审核通过
const handleApprove = async (row: any) => {
  try {
    await axios.put(`/admin/merchants/${row.userId}/audit`, {
      auditStatus: 1
    })
    ElMessage.success('审核通过')
    loadAuditList()
  } catch (error) {
    console.error('审核通过失败:', error)
    ElMessage.error('审核通过失败')
  }
}

// 审核驳回
const handleReject = (row: any) => {
  currentAuditItem.value = row
  rejectForm.rejectReason = ''
  rejectDialogVisible.value = true
}

// 确认驳回
const confirmReject = async () => {
  if (!rejectForm.rejectReason) {
    ElMessage.warning('请输入驳回原因')
    return
  }
  try {
    await axios.put(`/admin/merchants/${currentAuditItem.value.userId}/audit`, {
      auditStatus: 2,
      rejectReason: rejectForm.rejectReason
    })
    ElMessage.success('审核驳回成功')
    rejectDialogVisible.value = false
    loadAuditList()
  } catch (error) {
    console.error('审核驳回失败:', error)
    ElMessage.error('审核驳回失败')
  }
}

// 查看认证材料
const viewAuthMaterials = (row: any) => {
  currentMaterials.value = {
    businessLicense: row.businessLicense || '',
    legalIdFront: row.legalIdFront || '',
    legalIdBack: row.legalIdBack || ''
  }
  materialsDialogVisible.value = true
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  loadAuditList()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  loadAuditList()
}

// 辅助函数：获取店铺状态文本
const getShopStatusText = (status: number) => {
  switch (status) {
    case 0: return '关闭'
    case 1: return '正常'
    case 2: return '审核中'
    default: return '未知'
  }
}

// 辅助函数：获取店铺状态标签类型
const getStatusTagType = (status: number) => {
  switch (status) {
    case 0: return 'danger'
    case 1: return 'success'
    case 2: return 'warning'
    default: return 'info'
  }
}
</script>

<style scoped>
.merchant-audit {
  padding: 0;
}

.merchant-audit h2 {
  margin-bottom: 20px;
  color: #304156;
  font-size: 24px;
}

.filter-card {
  margin-bottom: 20px;
}

.filter-form {
  display: flex;
  justify-content: flex-start;
  align-items: center;
}

.table-card {
  margin-bottom: 20px;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.materials-content {
  padding: 20px;
}

.material-item {
  margin-bottom: 30px;
}

.material-item h3 {
  margin-bottom: 10px;
  color: #304156;
  font-size: 16px;
}

.material-image {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 20px;
  min-height: 300px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  background-color: #fafafa;
}

.license-image {
  max-width: 100%;
  max-height: 500px;
  object-fit: contain;
}

.no-license {
  color: #909399;
  font-size: 16px;
}
</style>
