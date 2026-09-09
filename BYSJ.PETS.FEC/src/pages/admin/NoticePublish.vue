<template>
  <div class="notice-publish">
    <h2>公告发布</h2>
    <el-card shadow="hover" class="action-card">
      <div class="action-buttons">
        <el-button type="primary" @click="handleAdd">发布新公告</el-button>
        <el-button type="success" @click="handleRefresh">刷新公告</el-button>
      </div>
    </el-card>
    <el-card shadow="hover" class="table-card">
      <el-table
        :data="noticeList"
        v-loading="loading"
        style="width: 100%"
        stripe
      >
        <el-table-column prop="noticeId" label="公告ID" width="100" />
        <el-table-column prop="content" label="公告内容" min-width="300" />
        <el-table-column prop="noticeType" label="公告类型" width="120">
          <template #default="scope">
            <el-tag :type="getNoticeTypeTagType(scope.row.noticeType)">
              {{ getNoticeTypeText(scope.row.noticeType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="发布时间" width="200" />
        <el-table-column prop="isRead" label="是否已读" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.isRead === 1 ? 'success' : 'info'">
              {{ scope.row.isRead === 1 ? '已读' : '未读' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="noticeStatus" label="公告状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.noticeStatus === 0 ? 'success' : 'warning'">
              {{ scope.row.noticeStatus === 0 ? '正常' : '已过期' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="scope">
            <el-button
              type="warning"
              size="small"
              @click="handleEdit(scope.row)"
            >
              编辑
            </el-button>
            <el-button
              type="danger"
              size="small"
              @click="handleDelete(scope.row)"
            >
              删除
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

    <!-- 公告编辑抽屉 -->
    <el-drawer
      v-model="drawerVisible"
      title="编辑公告"
      direction="rtl"
      :size="500"
    >
      <el-form :model="form" label-position="top" :rules="formRules" ref="formRef">
        <el-form-item label="公告内容" prop="content">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="6"
            placeholder="请输入公告内容"
          />
        </el-form-item>
        <el-form-item label="公告类型" prop="noticeType">
          <el-select v-model="form.noticeType" placeholder="请选择公告类型">
            <el-option label="通用通知" :value="0" />
            <el-option label="库存预警通知" :value="1" />
            <el-option label="退款通知" :value="2" />
            <el-option label="账号封禁/冻结通知" :value="3" />
            <el-option label="差评提醒通知" :value="4" />
            <el-option label="租赁到期提醒" :value="5" />
          </el-select>
        </el-form-item>
        <el-form-item label="接收用户ID" prop="userId">
          <el-input
            v-model="form.userId"
            placeholder="请输入接收用户ID，为空则发送给所有用户"
            type="number"
          />
        </el-form-item>
        <el-form-item label="有效期" prop="expireTime">
          <el-date-picker
            v-model="form.expireTime"
            type="datetime"
            placeholder="请选择有效期"
            style="width: 100%"
          />
        </el-form-item>
        <div class="drawer-footer">
          <el-button @click="drawerVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">保存</el-button>
        </div>
      </el-form>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import axios from '@/axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance } from 'element-plus'

// 页面状态
const loading = ref(false)
const noticeList = ref<any[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const drawerVisible = ref(false)
const formRef = ref<FormInstance>()

// 表单数据
const form = reactive({
  noticeId: 0,
  content: '',
  noticeType: null,
  userId: null,
  expireTime: ''
})

// 表单验证规则
const formRules = {
  content: [
    { min: 0, max: 500, message: '公告内容长度在 0 到 500 个字符', trigger: 'blur' }
  ],
  noticeType: []
}

// 加载公告列表
const loadNotices = async () => {
  loading.value = true
  try {
    const response = await axios.get('/admin/notices', {
      params: {
        pageNum: currentPage.value,
        pageSize: pageSize.value,
        sortField: 'notice_id',
        sortOrder: 'desc'
      }
    })
    noticeList.value = response.data.records || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载公告列表失败:', error)
    ElMessage.error('加载公告列表失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取公告列表
onMounted(() => {
  loadNotices()
})

// 发布新公告
const handleAdd = () => {
  resetForm()
  drawerVisible.value = true
}

// 编辑公告
const handleEdit = (row: any) => {
  form.noticeId = row.noticeId
  form.content = row.content
  form.noticeType = row.noticeType
  form.userId = row.userId
  form.expireTime = row.expireTime
  drawerVisible.value = true
}

// 删除公告
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      '确认删除该公告吗？删除后无法恢复！',
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await axios.delete(`/admin/notices/${row.noticeId}`)
    ElMessage.success('公告删除成功')
    loadNotices()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除公告失败:', error)
      ElMessage.error('删除公告失败')
    }
  }
}

// 保存公告
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (form.noticeId) {
          // 更新公告
          await axios.put(`/admin/notices/${form.noticeId}`, form)
          ElMessage.success('公告更新成功')
        } else {
          // 添加公告
          await axios.post('/admin/notices', form)
          ElMessage.success('公告发布成功')
        }
        drawerVisible.value = false
        loadNotices()
      } catch (error) {
        console.error('保存公告失败:', error)
        ElMessage.error('保存公告失败')
      }
    }
  })
}

// 重置表单
const resetForm = () => {
  form.noticeId = 0
  form.content = ''
  form.noticeType = 0
  form.userId = null
  form.expireTime = ''
  if (formRef.value) {
    formRef.value.resetFields()
  }
}

// 刷新公告
const handleRefresh = () => {
  loadNotices()
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  loadNotices()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  loadNotices()
}

// 辅助函数：获取公告类型文本
const getNoticeTypeText = (type: number) => {
  switch (type) {
    case 0: return '通用通知'
    case 1: return '库存预警通知'
    case 2: return '退款通知'
    case 3: return '账号封禁/冻结通知'
    case 4: return '差评提醒通知'
    case 5: return '租赁到期提醒'
    default: return '未知'
  }
}

// 辅助函数：获取公告类型标签类型
const getNoticeTypeTagType = (type: number) => {
  switch (type) {
    case 0: return 'info'
    case 1: return 'warning'
    case 2: return 'success'
    case 3: return 'danger'
    case 4: return 'warning'
    case 5: return 'info'
    default: return 'info'
  }
}
</script>

<style scoped>
.notice-publish {
  padding: 0;
}

.notice-publish h2 {
  margin-bottom: 20px;
  color: #304156;
  font-size: 24px;
}

.action-card {
  margin-bottom: 20px;
}

.action-buttons {
  display: flex;
  gap: 10px;
}

.table-card {
  margin-bottom: 20px;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  gap: 10px;
}
</style>
