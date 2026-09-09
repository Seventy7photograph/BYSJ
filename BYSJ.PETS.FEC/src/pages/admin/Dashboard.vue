<template>
  <div class="dashboard-content">
    <!-- 欢迎卡片 -->
    <el-card shadow="hover" class="welcome-card">
      <template #header>
        <div class="card-header">
          <span>欢迎回来，{{ currentUser?.username || '管理员' }}！</span>
        </div>
      </template>
      <div class="welcome-content">
        <div class="welcome-text">
          <p class="welcome-desc">今天是 {{ formatDate(new Date()) }}，祝您工作顺利！</p>
        </div>
      </div>
    </el-card>

    <!-- 数据概览 -->
    <div class="stats-section">
      <h3 class="section-title">平台数据概览</h3>
      <div class="stats-grid">
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="userCount"
            :precision="0"
            :value-style="{ color: '#3f8600' }"
            suffix="人"
          >
            <template #prefix>
              <el-icon><User /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">普通用户</span>
            </template>
            <template #extra>
              <el-tag type="success" size="small">+12.5%</el-tag>
              <span class="trend-period">较上月</span>
            </template>
          </el-statistic>
        </el-card>
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="merchantCount"
            :precision="0"
            :value-style="{ color: '#1890ff' }"
            suffix="人"
          >
            <template #prefix>
              <el-icon><ShoppingCart /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">商家用户</span>
            </template>
            <template #extra>
              <el-tag type="success" size="small">+8.3%</el-tag>
              <span class="trend-period">较上月</span>
            </template>
          </el-statistic>
        </el-card>
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="newProductCount"
            :precision="0"
            :value-style="{ color: '#fa8c16' }"
            suffix="件"
          >
            <template #prefix>
              <el-icon><Goods /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">全新器材</span>
            </template>
            <template #extra>
              <el-tag type="success" size="small">+15.8%</el-tag>
              <span class="trend-period">较上月</span>
            </template>
          </el-statistic>
        </el-card>
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="usedProductCount"
            :precision="0"
            :value-style="{ color: '#722ed1' }"
            suffix="件"
          >
            <template #prefix>
              <el-icon><Goods /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">二手器材</span>
            </template>
            <template #extra>
              <el-tag type="success" size="small">+12.3%</el-tag>
              <span class="trend-period">较上月</span>
            </template>
          </el-statistic>
        </el-card>
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="rentalProductCount"
            :precision="0"
            :value-style="{ color: '#1890ff' }"
            suffix="件"
          >
            <template #prefix>
              <el-icon><Goods /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">租赁器材</span>
            </template>
            <template #extra>
              <el-tag type="success" size="small">+22.1%</el-tag>
              <span class="trend-period">较上月</span>
            </template>
          </el-statistic>
        </el-card>
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="pendingProductsCount"
            :precision="0"
            :value-style="{ color: '#f56c6c' }"
            suffix="件"
          >
            <template #prefix>
              <el-icon><Document /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">待审核器材</span>
            </template>
            <template #extra>
              <el-tag type="warning" size="small">待处理</el-tag>
            </template>
          </el-statistic>
        </el-card>
        <el-card shadow="hover" class="stat-card">
          <el-statistic
            :value="categoryCount"
            :precision="0"
            :value-style="{ color: '#722ed1' }"
            suffix="个"
          >
            <template #prefix>
              <el-icon><Folder /></el-icon>
            </template>
            <template #title>
              <span class="stat-label">商品分类</span>
            </template>
          </el-statistic>
        </el-card>
      </div>
    </div>

    <!-- 最近操作 -->
    <div class="recent-operations-section">
      <div class="section-header">
        <h3 class="section-title">最近操作</h3>
        <el-button type="primary" size="small" @click="handleViewAllOperations">查看全部</el-button>
      </div>
      <el-card shadow="hover">
        <el-table :data="recentOperations" style="width: 100%" border>
          <el-table-column prop="operator" label="操作人" min-width="120" />
          <el-table-column prop="operation" label="操作类型" min-width="150" />
          <el-table-column prop="target" label="操作对象" min-width="120" />
          <el-table-column prop="result" label="操作结果" min-width="100">
            <template #default="scope">
              <el-tag :type="getResultType(scope.row.result)" size="small">{{ scope.row.result }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="operationTime" label="操作时间" min-width="160" />
        </el-table>
      </el-card>
    </div>

    <!-- 操作记录对话框 -->
    <el-dialog
      v-model="operationDialogVisible"
      title="全部操作记录"
      width="90%"
      max-width="1200px"
    >
      <div class="operation-dialog-content">
        <div class="search-bar">
          <div style="display: flex; align-items: center; gap: 10px;">
            <el-input
              v-model="searchKeyword"
              placeholder="输入操作类型或模块关键词"
              style="width: 300px"
              prefix-icon="el-icon-search"
              @keyup.enter="handleSearch"
            >
              <template #append>
                <el-button @click="handleSearch" style="margin-right: 5px">搜索</el-button>
                <el-button @click="resetSearch">重置</el-button>
              </template>
            </el-input>
            <el-button type="primary" @click="handleExport">
              <el-icon><Download /></el-icon>
              导出
            </el-button>
          </div>
        </div>
        <el-table
          :data="allOperations"
          style="width: 100%"
          border
          v-loading="loading"
        >
          <el-table-column prop="operator" label="操作人" min-width="120" />
          <el-table-column prop="operation" label="操作类型" min-width="150" />
          <el-table-column prop="target" label="操作对象" min-width="120" />
          <el-table-column prop="result" label="操作结果" min-width="100">
            <template #default="scope">
              <el-tag :type="getResultType(scope.row.result)" size="small">{{ scope.row.result }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="operationTime" label="操作时间" min-width="160" />
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
      </div>
    </el-dialog>

    <!-- 数据图表区域 -->
    <div class="charts-section">
      <h3 class="section-title">数据趋势分析</h3>
      <div class="charts-grid">
        <!-- 第一行：用户增长和订单趋势 -->
        <div class="chart-row">
          <!-- 用户增长趋势图 -->
          <el-card shadow="hover" class="chart-card">
            <div class="chart-header">
              <span class="chart-title">用户增长趋势</span>
            </div>
            <div ref="userChartRef" class="chart-container"></div>
          </el-card>
          <!-- 订单数量趋势图 -->
          <el-card shadow="hover" class="chart-card">
            <div class="chart-header">
              <span class="chart-title">订单数量趋势</span>
            </div>
            <div ref="orderChartRef" class="chart-container"></div>
          </el-card>
        </div>

        <!-- 第二行：器材分类和器材类型 -->
        <div class="chart-row">
          <!-- 摄影器材分类分布图 -->
          <el-card shadow="hover" class="chart-card">
            <div class="chart-header">
              <span class="chart-title">摄影器材分类分布</span>
            </div>
            <div ref="categoryChartRef" class="chart-container"></div>
          </el-card>
          <!-- 器材类型分布图 -->
          <el-card shadow="hover" class="chart-card">
            <div class="chart-header">
              <span class="chart-title">器材类型分布</span>
            </div>
            <div ref="productTypeChartRef" class="chart-container"></div>
          </el-card>
        </div>

        <!-- 第三行：待审核器材状态和热门器材 -->
        <div class="chart-row">
          <!-- 待审核器材状态图 -->
          <el-card shadow="hover" class="chart-card">
            <div class="chart-header">
              <span class="chart-title">待审核器材状态</span>
            </div>
            <div ref="pendingProductChartRef" class="chart-container"></div>
          </el-card>
          <!-- 热门器材排行 -->
          <el-card shadow="hover" class="chart-card">
            <div class="chart-header">
              <span class="chart-title">热门器材排行</span>
            </div>
            <div ref="hotProductChartRef" class="chart-container"></div>
          </el-card>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  User, ShoppingBag, Folder, Download
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { getAdminDashboardData } from '@/api/admin/dashboard'
import { getOperationList } from '@/api/admin/operations'

const router = useRouter()
const userStore = useUserStore()

// 响应式状态
const selectedDate = ref(new Date())

// 用户信息
const currentUser = ref({
  username: userStore.userInfo?.username || '管理员',
  role: 'admin'
})

// 数据概览
const userCount = ref(0)
const merchantCount = ref(0)
const pendingProductsCount = ref(0)
const categoryCount = ref(0)
const newProductCount = ref(0)
const usedProductCount = ref(0)
const rentalProductCount = ref(0)

// 最近操作数据
const recentOperations = ref([])

// 图表数据
const userGrowthTrend = ref({ dates: [], users: [] })
const orderTrend = ref({ dates: [], orders: [] })
const categoryDistribution = ref([])
const productTypeDistribution = ref([])
const pendingProductStatus = ref([])
const hotProducts = ref([])

// 操作记录对话框相关
const operationDialogVisible = ref(false)
const allOperations = ref([])
const loading = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const searchKeyword = ref('')

// 格式化日期
const formatDate = (date: Date) => {
  if (!date || !(date instanceof Date) || isNaN(date.getTime())) {
    return ''
  }
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'long'
  })
}

// 获取操作结果类型
const getResultType = (result: string) => {
  const resultMap: Record<string, string> = {
    '成功': 'success',
    '通过': 'success',
    '失败': 'danger',
    '拒绝': 'warning'
  }
  return resultMap[result] || 'default'
}

// 操作管理方法
const handleViewAllOperations = () => {
  operationDialogVisible.value = true
  currentPage.value = 1
  searchKeyword.value = ''
  fetchOperations()
}

// 获取操作记录
const fetchOperations = async () => {
  loading.value = true
  try {
    const response = await getOperationList(currentPage.value, pageSize.value, searchKeyword.value)
    if (response.code === 200) {
      allOperations.value = response.data.records
      total.value = response.data.total
    }
  } catch (error) {
    console.error('获取操作记录失败:', error)
  } finally {
    loading.value = false
  }
}

// 搜索操作记录
const handleSearch = () => {
  currentPage.value = 1
  fetchOperations()
}

// 重置搜索
const resetSearch = () => {
  searchKeyword.value = ''
  currentPage.value = 1
  fetchOperations()
}

// 分页大小变化
const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  fetchOperations()
}

// 页码变化
const handleCurrentChange = (current: number) => {
  currentPage.value = current
  fetchOperations()
}

// 导出操作记录
const handleExport = () => {
  // 导出为CSV格式
  const headers = ['操作人', '操作类型', '操作对象', '操作结果', '操作时间']
  const csvContent = [
    headers.join(','),
    ...allOperations.value.map((item: any) => [
      item.operator,
      item.operation,
      item.target,
      item.result,
      item.operationTime
    ].join(','))
  ].join('\n')

  // 添加BOM字符以解决中文乱码问题
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.setAttribute('href', url)
  link.setAttribute('download', `操作记录_${new Date().toISOString().split('T')[0]}.csv`)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

// 图表容器Refs
const userChartRef = ref<HTMLElement | null>(null)
const orderChartRef = ref<HTMLElement | null>(null)
const categoryChartRef = ref<HTMLElement | null>(null)
const productTypeChartRef = ref<HTMLElement | null>(null)
const pendingProductChartRef = ref<HTMLElement | null>(null)
const hotProductChartRef = ref<HTMLElement | null>(null)

// 初始化用户增长图表
const initUserChart = () => {
  if (userChartRef.value) {
    const chart = echarts.init(userChartRef.value)
    const option = {
      title: {
        text: '用户增长趋势',
        left: 'center',
        textStyle: {
          fontSize: 16,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'axis'
      },
      xAxis: {
        type: 'category',
        data: userGrowthTrend.value.dates,
        axisLabel: {
          rotate: 45
        }
      },
      yAxis: {
        type: 'value',
        name: '用户数'
      },
      series: [
        {
          data: userGrowthTrend.value.users,
          type: 'line',
          smooth: true,
          itemStyle: {
            color: '#3f8600'
          },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(63, 136, 255, 0.5)' },
              { offset: 1, color: 'rgba(63, 136, 255, 0.1)' }
            ])
          }
        }
      ]
    }
    chart.setOption(option)
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化订单趋势图表
const initOrderChart = () => {
  if (orderChartRef.value) {
    const chart = echarts.init(orderChartRef.value)
    const option = {
      title: {
        text: '订单数量趋势',
        left: 'center',
        textStyle: {
          fontSize: 16,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'axis'
      },
      xAxis: {
        type: 'category',
        data: orderTrend.value.dates,
        axisLabel: {
          rotate: 45
        }
      },
      yAxis: {
        type: 'value',
        name: '订单数'
      },
      series: [
        {
          data: orderTrend.value.orders,
          type: 'line',
          smooth: true,
          itemStyle: {
            color: '#409EFF'
          },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(64, 158, 255, 0.5)' },
              { offset: 1, color: 'rgba(64, 158, 255, 0.1)' }
            ])
          }
        }
      ]
    }
    chart.setOption(option)
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化摄影器材分类分布图
const initCategoryChart = () => {
  if (categoryChartRef.value) {
    const chart = echarts.init(categoryChartRef.value)
    const option = {
      tooltip: {
        trigger: 'item'
      },
      legend: {
        orient: 'vertical',
        left: 'left'
      },
      series: [
        {
          name: '摄影器材分类',
          type: 'pie',
          radius: '50%',
          data: categoryDistribution.value,
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          }
        }
      ]
    }
    chart.setOption(option)
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化器材类型分布图
const initProductTypeChart = () => {
  if (productTypeChartRef.value) {
    const chart = echarts.init(productTypeChartRef.value)
    const option = {
      tooltip: {
        trigger: 'item'
      },
      legend: {
        orient: 'vertical',
        left: 'left'
      },
      series: [
        {
          name: '器材类型',
          type: 'pie',
          radius: '50%',
          data: productTypeDistribution.value,
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          }
        }
      ]
    }
    chart.setOption(option)
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化待审核器材状态图
const initPendingProductChart = () => {
  if (pendingProductChartRef.value) {
    const chart = echarts.init(pendingProductChartRef.value)
    const option = {
      tooltip: {
        trigger: 'item'
      },
      legend: {
        orient: 'vertical',
        left: 'left'
      },
      series: [
        {
          name: '待审核器材状态',
          type: 'pie',
          radius: '50%',
          data: pendingProductStatus.value,
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)'
            }
          }
        }
      ]
    }
    chart.setOption(option)
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化热门器材排行图
const initHotProductChart = () => {
  if (hotProductChartRef.value) {
    const chart = echarts.init(hotProductChartRef.value)
    const option = {
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow'
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'value',
        boundaryGap: [0, 0.01]
      },
      yAxis: {
        type: 'category',
        data: hotProducts.value.map((item: any) => item.name)
      },
      series: [
        {
          name: '销量',
          type: 'bar',
          data: hotProducts.value.map((item: any) => item.value),
          itemStyle: {
            color: '#409EFF'
          }
        }
      ]
    }
    chart.setOption(option)
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 获取仪表盘数据
const fetchDashboardData = async () => {
  try {
    const response = await getAdminDashboardData()
    if (response.code === 200) {
      const data = response.data
      // 更新数据概览
      userCount.value = data.userCount || 0
      merchantCount.value = data.merchantCount || 0
      pendingProductsCount.value = data.pendingProductsCount || 0
      categoryCount.value = data.categoryCount || 0
      newProductCount.value = data.newProductCount || 0
      usedProductCount.value = data.usedProductCount || 0
      rentalProductCount.value = data.rentalProductCount || 0

      // 更新最近操作
      recentOperations.value = data.recentOperations || []

      // 更新图表数据
      userGrowthTrend.value = data.userGrowthTrend || { dates: [], users: [] }
      orderTrend.value = data.orderTrend || { dates: [], orders: [] }
      categoryDistribution.value = data.categoryDistribution || []
      productTypeDistribution.value = data.productTypeDistribution || []
      pendingProductStatus.value = data.pendingProductStatus || []
      hotProducts.value = data.hotProducts || []

      // 初始化图表
      setTimeout(() => {
        initUserChart()
        initOrderChart()
        initCategoryChart()
        initProductTypeChart()
        initPendingProductChart()
        initHotProductChart()
      }, 100)
    }
  } catch (error) {
    console.error('获取仪表盘数据失败:', error)
  }
}

// 页面加载时初始化数据
onMounted(() => {
  fetchDashboardData()
})
</script>

<style scoped>
.dashboard-content {
  padding: 20px;
  background-color: #f0f2f5;
  min-height: 100vh;
}

/* 欢迎卡片 */
.welcome-card {
  margin-bottom: 24px;
}

.welcome-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 30px;
}

.welcome-text {
  flex: 1;
}

.welcome-desc {
  margin: 0;
  color: #606266;
  font-size: 16px;
  font-weight: 500;
  text-align: center;
}

/* 数据概览 */
.stats-section {
  margin-bottom: 24px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 16px 0;
  color: #304156;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
}

.stat-card {
  display: flex;
  align-items: center;
  padding: 20px;
  transition: transform 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
}

.stat-icon {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  margin-right: 20px;
}

.stat-info {
  flex: 1;
}

.stat-number {
  font-size: 28px;
  font-weight: bold;
  color: #304156;
  margin: 0;
}

.stat-label {
  font-size: 14px;
  color: #606266;
  margin: 4px 0 0;
}

.stat-trend {
  text-align: right;
}

.trend-up {
  color: #67C23A;
  font-weight: bold;
  margin-right: 5px;
}

.trend-down {
  color: #F56C6C;
  font-weight: bold;
  margin-right: 5px;
}

.trend-period {
  font-size: 12px;
  color: #909399;
}

/* 最近操作 */
.recent-operations-section {
  margin-bottom: 24px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

/* 数据图表区域 */
.charts-section {
  margin-bottom: 24px;
}

.charts-grid {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.chart-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.chart-header {
  padding: 12px 0;
  border-bottom: 1px solid #eee;
  margin-bottom: 12px;
}

.chart-title {
  font-size: 16px;
  font-weight: 600;
  color: #304156;
}

.chart-card {
  padding: 20px;
  height: 450px;
}

.chart-container {
  width: 100%;
  height: 410px;
}

/* 操作记录对话框 */
.operation-dialog-content {
  padding: 20px 0;
}

.search-bar {
  margin-bottom: 20px;
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>
