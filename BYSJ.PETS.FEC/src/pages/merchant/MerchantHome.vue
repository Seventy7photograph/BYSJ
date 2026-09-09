<template>
    <!-- 商家后台首页内容 -->
    <div class="dashboard-content">
      <!-- 欢迎卡片 -->
      <el-card shadow="hover" class="welcome-card">
        <template #header>
          <div class="card-header">
            <span>欢迎回来，{{ currentUser?.username || '商家用户' }}！</span>
          </div>
        </template>
        <div class="welcome-content">
          <div class="welcome-text">
            <p class="welcome-desc">今天是 {{ formatDate(new Date()) }}，祝您日进斗金！</p>
          </div>
        </div>
      </el-card>



      <!-- 数据概览 -->
      <div class="stats-section">
        <h3 class="section-title">店铺数据概览</h3>
        <div class="stats-grid">
          <el-card shadow="hover" class="stat-card">
            <el-statistic
              :value="totalOrders"
              :precision="0"
              :value-style="{ color: '#3f8600' }"
              suffix="单"
            >
              <template #prefix>
                <el-icon><ShoppingCart /></el-icon>
              </template>
              <template #title>
                <span class="stat-label">总订单数</span>
              </template>
              <template #extra>
                <el-tag :type="orderTrend >= 0 ? 'success' : 'danger'" size="small">{{ orderTrend >= 0 ? '+' : '' }}{{ orderTrend }}%</el-tag>
                <span class="trend-period">较上月</span>
              </template>
            </el-statistic>
          </el-card>

          <el-card shadow="hover" class="stat-card">
            <el-statistic
              :value="totalRevenue"
              :precision="2"
              :value-style="{ color: '#1890ff' }"
              prefix="¥"
              suffix="元"
            >
              <template #prefix>
                <el-icon><Ticket /></el-icon>¥
              </template>
              <template #title>
                <span class="stat-label">总成交额</span>
              </template>
              <template #extra>
                <el-tag :type="revenueTrend >= 0 ? 'success' : 'danger'" size="small">{{ revenueTrend >= 0 ? '+' : '' }}{{ revenueTrend }}%</el-tag>
                <span class="trend-period">较上月</span>
              </template>
            </el-statistic>
          </el-card>

          <el-card shadow="hover" class="stat-card">
            <el-statistic
              :value="totalProducts"
              :precision="0"
              :value-style="{ color: '#722ed1' }"
              suffix="件"
            >
              <template #prefix>
                <el-icon><Goods /></el-icon>
              </template>
              <template #title>
                <span class="stat-label">上架商品数</span>
              </template>
              <template #extra>
                <el-tag :type="productTrend >= 0 ? 'success' : 'danger'" size="small">{{ productTrend >= 0 ? '+' : '' }}{{ productTrend }}%</el-tag>
                <span class="trend-period">较上月</span>
              </template>
            </el-statistic>
          </el-card>

          <el-card shadow="hover" class="stat-card">
            <el-statistic
              :value="totalVisitors"
              :precision="0"
              :value-style="{ color: '#fa8c16' }"
              suffix="人"
            >
              <template #prefix>
                <el-icon><User /></el-icon>
              </template>
              <template #title>
                <span class="stat-label">店铺访客数</span>
              </template>
              <template #extra>
                <el-tag :type="visitorTrend >= 0 ? 'success' : 'danger'" size="small">{{ visitorTrend >= 0 ? '+' : '' }}{{ visitorTrend }}%</el-tag>
                <span class="trend-period">较上月</span>
              </template>
            </el-statistic>
          </el-card>
        </div>
      </div>

      <!-- 最近订单 -->
      <div class="recent-orders-section">
        <div class="section-header">
          <h3 class="section-title">最近订单</h3>
          <el-button type="primary" size="small" @click="handleViewAllOrders">查看全部</el-button>
        </div>
        <el-card shadow="hover">
          <el-table :data="recentOrders" style="width: 100%" border>
            <el-table-column prop="orderNo" label="订单号" min-width="180" />
            <el-table-column prop="customerName" label="客户" min-width="120" />
            <el-table-column prop="orderAmount" label="金额" min-width="100" :formatter="formatCurrency" />
            <el-table-column prop="orderStatus" label="状态" min-width="120">
              <template #default="scope">
                <el-tag :type="getStatusType(scope.row.orderStatus)">{{ getStatusText(scope.row.orderStatus) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createTime" label="下单时间" min-width="160" />
            <el-table-column label="操作" min-width="120" fixed="right">
              <template #default="scope">
                <el-button type="primary" size="small" @click="handleViewOrderDetail(scope.row.orderNo)">查看详情</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </div>

      <!-- 数据图表区域 -->
      <div class="charts-section">
        <h3 class="section-title">数据趋势分析</h3>
        <div class="charts-grid">
          <!-- 成交额趋势图 -->
          <el-card shadow="hover" class="chart-card">
            <div ref="revenueChartRef" class="chart-container"></div>
          </el-card>

          <!-- 订单数量趋势图 -->
          <el-card shadow="hover" class="chart-card">
            <div ref="orderChartRef" class="chart-container"></div>
          </el-card>

          <!-- 每日销售数据图表 -->
          <el-card shadow="hover" class="chart-card">
            <div ref="salesChartRef" class="chart-container"></div>
          </el-card>

          <!-- 新增商品销售分布图表 -->
          <el-card shadow="hover" class="chart-card">
            <div ref="productChartRef" class="chart-container"></div>
          </el-card>
        </div>
      </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  ShoppingCart, Ticket, Goods, User
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { getDashboardData, getRecentOrders, getChartData, getCalendarSalesData, getProductDistributionData } from '@/api/merchant/shop'

const router = useRouter()
const userStore = useUserStore()

// 响应式状态
const selectedDate = ref(new Date())
const calendarKey = ref(0)
const calendarSalesData = ref<Record<string, { orders: number; revenue: number }>>({})

// 用户信息
const currentUser = ref({
  username: userStore.userInfo?.username || '商家用户',
  role: 'merchant'
})

// 数据概览
const totalOrders = ref(0)
const totalRevenue = ref(0)
const totalProducts = ref(0)
const totalVisitors = ref(0)
const orderTrend = ref(0)
const revenueTrend = ref(0)
const productTrend = ref(0)
const visitorTrend = ref(0)

// 最近订单数据
const recentOrders = ref<any[]>([])

// 图表数据
const chartData = ref({
  dates: [] as string[],
  orders: [] as number[],
  revenue: [] as number[]
})

// 器材销售分布数据
const productDistributionData = ref<Array<{ name: string; value: number }>>([])



// 格式化金额
const formatCurrency = (row: any, column: any, cellValue: number) => {
  return `¥${cellValue.toFixed(2)}`
}

// 获取状态文本
const getStatusText = (status: number) => {
  const statusMap: Record<number, string> = {
    0: '待付款',
    1: '已付款',
    2: '已发货',
    3: '已完成',
    4: '已取消',
    5: '退款处理中',
    6: '退款成功',
    7: '退款失败',
    8: '租赁中',
    9: '归还中'
  }
  return statusMap[status] || '未知状态'
}

// 获取状态类型
const getStatusType = (status: number) => {
  const statusMap: Record<number, string> = {
    0: 'warning',
    1: 'info',
    2: 'success',
    3: 'success',
    4: 'danger',
    5: 'primary',
    6: 'success',
    7: 'danger',
    8: 'primary',
    9: 'info'
  }
  return statusMap[status] || 'default'
}

// 订单管理方法
const handleViewAllOrders = () => {
  router.push('/merchant-dashboard/order-management')
}

const handleViewOrderDetail = (orderNo: string) => {
  router.push(`/merchant-dashboard/order-detail/${orderNo}`)
}

// 图表容器Refs
const orderChartRef = ref<HTMLElement | null>(null)
const revenueChartRef = ref<HTMLElement | null>(null)
const salesChartRef = ref<HTMLElement | null>(null)
const productChartRef = ref<HTMLElement | null>(null)

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



// 日历单元格内容渲染函数
const cellContent = (date: Date | undefined) => {
  // 确保日期是有效的
  if (!date || !(date instanceof Date) || isNaN(date.getTime())) {
    return `<div class="calendar-cell"><span class="cell-day"></span></div>`
  }

  // 使用本地日期格式，确保与后端返回的日期格式一致
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const dateStr = `${year}-${month}-${day}`

  const salesData = calendarSalesData.value[dateStr]
  console.log('Checking date:', dateStr, 'Sales data:', salesData)

  if (salesData) {
    return `
      <div class="calendar-cell" title="订单数: ${salesData.orders}单\n成交额: ¥${salesData.revenue.toFixed(2)}">
        <span class="cell-day">${date.getDate()}</span>
        <span class="cell-orders">${salesData.orders}单</span>
        <span class="cell-revenue">¥${salesData.revenue.toFixed(0)}</span>
      </div>
    `
  } else {
    return `
      <div class="calendar-cell">
        <span class="cell-day">${date.getDate()}</span>
      </div>
    `
  }
}

// 初始化订单图表
const initOrderChart = () => {
  if (orderChartRef.value) {
    const chart = echarts.init(orderChartRef.value)
    const option = {
      title: {
        text: '日订单数量趋势',
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
        data: chartData.value.dates,
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
          data: chartData.value.orders,
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

    // 监听窗口大小变化
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化成交额图表
const initRevenueChart = () => {
  if (revenueChartRef.value) {
    const chart = echarts.init(revenueChartRef.value)
    const option = {
      title: {
        text: '日成交额趋势',
        left: 'center',
        textStyle: {
          fontSize: 16,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'axis',
        formatter: (params: any) => {
          const data = params[0]
          return `${data.name}<br/>成交额: ¥${data.value.toFixed(2)}`
        }
      },
      xAxis: {
        type: 'category',
        data: chartData.value.dates,
        axisLabel: {
          rotate: 45
        }
      },
      yAxis: {
        type: 'value',
        name: '成交额(元)',
        axisLabel: {
          formatter: (value: number) => {
            return `¥${value.toLocaleString()}`
          }
        }
      },
      series: [
        {
          data: chartData.value.revenue,
          type: 'bar',
          itemStyle: {
            color: '#67C23A',
            borderRadius: [4, 4, 0, 0]
          }
        }
      ]
    }
    chart.setOption(option)

    // 监听窗口大小变化
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 初始化销售数据图表
const initSalesChart = () => {
  if (salesChartRef.value) {
    const chart = echarts.init(salesChartRef.value)

    // 处理销售数据，转换为图表所需格式
    const salesData = Object.entries(calendarSalesData.value)
      .map(([date, data]) => ({
        date,
        orders: data.orders,
        revenue: data.revenue
      }))
      .sort((a, b) => a.date.localeCompare(b.date))

    const dates = salesData.map(item => item.date)
    const orders = salesData.map(item => item.orders)
    const revenue = salesData.map(item => item.revenue)

    const option = {
      title: {
        text: '历史销售数据',
        left: 'center',
        textStyle: {
          fontSize: 16,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'cross'
        }
      },
      legend: {
        data: ['订单数', '成交额'],
        top: 30
      },
      xAxis: {
        type: 'category',
        data: dates,
        axisLabel: {
          rotate: 45
        }
      },
      yAxis: [
        {
          type: 'value',
          name: '订单数',
          position: 'left',
          axisLabel: {
            formatter: '{value}单'
          }
        },
        {
          type: 'value',
          name: '成交额',
          position: 'right',
          axisLabel: {
            formatter: '¥{value}'
          }
        }
      ],
      series: [
        {
          name: '订单数',
          type: 'bar',
          data: orders,
          itemStyle: {
            color: '#409EFF'
          }
        },
        {
          name: '成交额',
          type: 'line',
          yAxisIndex: 1,
          data: revenue,
          smooth: true,
          itemStyle: {
            color: '#67C23A'
          },
          lineStyle: {
            width: 2
          }
        }
      ]
    }
    chart.setOption(option)

    // 监听窗口大小变化
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 获取器材销售分布数据
const fetchProductDistributionData = async () => {
  try {
    const data = await getProductDistributionData()
    console.log('Raw product distribution data:', data)

    if (data && Array.isArray(data)) {
      productDistributionData.value = data
    } else if (data && data.data && Array.isArray(data.data)) {
      productDistributionData.value = data.data
    } else {
      // 如果没有真实数据，使用模拟数据
      productDistributionData.value = [
        { name: '全新器材', value: 50 },
        { name: '二手器材', value: 30 },
        { name: '租赁器材', value: 20 }
      ]
    }
    console.log('Product distribution data:', productDistributionData.value)
    // 数据更新后初始化图表
    setTimeout(() => {
      initProductChart()
    }, 100)
  } catch (error) {
    console.error('获取器材销售分布数据失败:', error)
    // 出错时使用模拟数据
    productDistributionData.value = [
      { name: '全新器材', value: 50 },
      { name: '二手器材', value: 30 },
      { name: '租赁器材', value: 20 }
    ]
    setTimeout(() => {
      initProductChart()
    }, 100)
  }
}

// 初始化商品销售分布图表
const initProductChart = () => {
  if (productChartRef.value) {
    const chart = echarts.init(productChartRef.value)

    const productData = productDistributionData.value

    const option = {
      title: {
        text: '器材销售分布',
        left: 'center',
        textStyle: {
          fontSize: 16,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'item',
        formatter: '{b}: {c}% ({d}%)'
      },
      legend: {
        orient: 'vertical',
        left: 'left',
        top: 'center'
      },
      series: [
        {
          name: '销售占比',
          type: 'pie',
          radius: ['40%', '70%'],
          avoidLabelOverlap: false,
          itemStyle: {
            borderRadius: 10,
            borderColor: '#fff',
            borderWidth: 2
          },
          label: {
            show: false,
            position: 'center'
          },
          emphasis: {
            label: {
              show: true,
              fontSize: '18',
              fontWeight: 'bold'
            }
          },
          labelLine: {
            show: false
          },
          data: productData,
          color: ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399']
        }
      ]
    }
    chart.setOption(option)

    // 监听窗口大小变化
    window.addEventListener('resize', () => {
      chart.resize()
    })
  }
}

// 获取dashboard数据
const fetchDashboardData = async () => {
  try {
    const data = await getDashboardData()
    totalOrders.value = data.totalOrders || 0
    totalRevenue.value = data.totalRevenue || 0
    totalProducts.value = data.totalProducts || 0
    totalVisitors.value = data.totalVisitors || 0
    orderTrend.value = data.orderTrend || 0
    revenueTrend.value = data.revenueTrend || 0
    productTrend.value = data.productTrend || 0
    visitorTrend.value = data.visitorTrend || 0
  } catch (error) {
    console.error('获取dashboard数据失败:', error)
  }
}

// 获取最近订单
const fetchRecentOrders = async () => {
  try {
    const data = await getRecentOrders()
    recentOrders.value = data.orders || []
  } catch (error) {
    console.error('获取最近订单失败:', error)
  }
}

// 获取图表数据
const fetchChartData = async () => {
  try {
    const data = await getChartData()
    chartData.value = {
      dates: data.dates || [],
      orders: data.orders || [],
      revenue: data.revenue || []
    }
    // 重新初始化图表
    setTimeout(() => {
      initRevenueChart()
      initOrderChart()
    }, 100)
  } catch (error) {
    console.error('获取图表数据失败:', error)
  }
}

// 获取日历销售数据
const fetchCalendarSalesData = async () => {
  try {
    const data = await getCalendarSalesData()
    console.log('Raw calendar data:', data)

    // 确保data是一个对象
    if (data && typeof data === 'object') {
      // 使用Object.assign来更新数据，确保Vue能够检测到变化
      Object.assign(calendarSalesData.value, data)
      console.log('Calendar sales data:', calendarSalesData.value)
      // 数据更新后初始化销售图表
      setTimeout(() => {
        initSalesChart()
      }, 100)
    } else {
      calendarSalesData.value = {}
      console.log('Calendar sales data is empty')
      // 空数据也需要初始化图表
      setTimeout(() => {
        initSalesChart()
      }, 100)
    }
  } catch (error) {
    console.error('获取日历销售数据失败:', error)
  }
}

// 页面加载时初始化数据
onMounted(async () => {
  // 并行获取所有数据
  await Promise.all([
    fetchDashboardData(),
    fetchRecentOrders(),
    fetchChartData(),
    fetchCalendarSalesData(),
    fetchProductDistributionData()
  ])
  console.log('商家后台首页加载完成')
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
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.welcome-desc {
  margin: 0;
  color: #606266;
  font-size: 16px;
  font-weight: 500;
  text-align: center;
}

.welcome-image {
  width: 150px;
  height: 150px;
  border-radius: 50%;
  object-fit: cover;
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

.orders-icon {
  background-color: #ecf5ff;
  color: #409EFF;
}

.revenue-icon {
  background-color: #f0f9eb;
  color: #67C23A;
}

.products-icon {
  background-color: #fdf6ec;
  color: #E6A23C;
}

.visitors-icon {
  background-color: #fef0f0;
  color: #F56C6C;
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
  margin: 4px 0 0 0;
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

/* 快捷操作 */
.quick-actions-section {
  margin-bottom: 24px;
}

.quick-actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
}

.action-card {
  cursor: pointer;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  padding: 24px;
}

.action-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 20px rgba(0, 0, 0, 0.1);
}

.action-icon {
  width: 60px;
  height: 60px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  margin-bottom: 16px;
}

.add-product {
  background-color: #ecf5ff;
  color: #409EFF;
}

.view-orders {
  background-color: #f0f9eb;
  color: #67C23A;
}

.manage-inventory {
  background-color: #fdf6ec;
  color: #E6A23C;
}

.shop-settings {
  background-color: #fef0f0;
  color: #F56C6C;
}

.action-title {
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 8px 0;
  color: #304156;
}

.action-desc {
  font-size: 14px;
  color: #606266;
  margin: 0;
}

/* 最近订单 */
.recent-orders-section {
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
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr 1fr;
  gap: 20px;
}

.chart-card {
  padding: 20px;
  height: 315px;
}

.chart-container {
  width: 100%;
  height: 275px;
}
</style>
