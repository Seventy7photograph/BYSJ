import axios from '@/axios'

// 评价相关API
const evaluation = {
  // 提交评价
  submitEvaluation: async (data: {
    orderId: number
    productId: number
    score: number
    qualityScore: number
    serviceScore: number
    logisticsScore?: number
    content: string
    imgUrls?: string[]
  }) => {
    const response = await axios.post('/evaluations', data)
    return response.data
  },

  // 获取商品评价列表
  getProductEvaluations: async (productId: number, params?: {
    page?: number
    pageSize?: number
  }) => {
    const response = await axios.get(`/evaluations/product/${productId}`, { params })
    return response.data
  },

  // 获取用户评价列表
  getUserEvaluations: async (params?: {
    page?: number
    pageSize?: number
  }) => {
    const response = await axios.get('/evaluations/user', { params })
    return response.data
  },

  // 删除评价
  deleteEvaluation: async (evaluationId: number) => {
    const response = await axios.delete(`/evaluations/${evaluationId}`)
    return response.data
  }
}

export default evaluation
