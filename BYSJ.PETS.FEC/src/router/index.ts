import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import SysLogin from '../pages/user/SysLogin.vue'
import Index from '../pages/user/Index.vue'
import NotFound from '../pages/user/404.vue'
import Register from '../pages/user/Register.vue'
import ForgotPassword from '../pages/user/ForgotPassword.vue'
import Header from '@/Navigation/Header.vue'
import Shop from '../pages/user/Shop.vue'
import SecondHand from '../pages/user/Second-hand.vue'
import { useUserStore } from '@/stores/user'
import Footer from '@/Navigation/Footer.vue'
import RightSticky from '@/Navigation/RightSticky.vue'
import MessageDrawer from '@/components/MessageDrawer.vue'
import { ElMessage } from 'element-plus'
import ProductDetail from '../pages/user/ProductDetail.vue'
import SecondHandDetail from '../pages/user/SecondHandDetail.vue'
import OrderConfirm from '../pages/user/OrderConfirm.vue'
import Payment from '../pages/user/Payment.vue'
import OrderDetail from '../pages/user/OrderDetail.vue'
import Rental from '../pages/user/Rental.vue'
import RentalDetail from '../pages/user/RentalDetail.vue'


// 默认路由（显式声明类型）
const routes: RouteRecordRaw[] = [
  {
    path: "/",
    redirect: "/index", // 修改为直接跳转到首页
    meta: { title: "首页" }
  },
  {
    path: "/login",
    name: "Login",
    component: SysLogin,
    meta: { title: "欢迎登录摄影交易系统" }
  },
  {
    path: "/register",
    name: "Register",
    component: Register,
    meta: { title: "成为大家庭的一员" }
  },
  {
    path: "/forgot-password",
    name: "ForgotPassword",
    component: ForgotPassword,
    meta: { title: "忘记密码" }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: NotFound,
    meta: { title: "页面不存在" }
  },
  // 重定向路由，解决直接访问/product-management导致的404问题
  {
    path: '/product-management',
    redirect: '/merchant-dashboard/product-management',
    meta: { title: "商品管理" }
  },
  // 商家后台路由
  {
    path: "/merchant-dashboard",
    name: "MerchantDashboard",
    component: () => import('../components/merchant/MerchantLayout.vue'),
    meta: {
      title: "商家后台首页",
      requiresAuth: true // 商家后台需要登录
    },
    children: [
      {
        path: "",
        name: "MerchantHome",
        component: () => import('../pages/merchant/MerchantHome.vue'),
        meta: {
          title: "商家后台首页",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "product-add",
        name: "ProductAdd",
        component: () => import('../pages/merchant/ProductAdd.vue'),
        meta: {
          title: "商品发布",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "product-edit/:id",
        name: "ProductEdit",
        component: () => import('../pages/merchant/ProductEdit.vue'),
        meta: {
          title: "编辑商品",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "product-management",
        name: "ProductManagement",
        component: () => import('../pages/merchant/ProductManagement.vue'),
        meta: {
          title: "商品管理",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "inventory-management",
        name: "InventoryManagement",
        component: () => import('../pages/merchant/InventoryManagement.vue'),
        meta: {
          title: "库存管理",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "order-management",
        name: "OrderManagement",
        component: () => import('../pages/merchant/OrderManagement.vue'),
        meta: {
          title: "订单管理",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "order-detail/:orderId",
        name: "MerchantOrderDetail",
        component: () => import('../pages/merchant/OrderDetail.vue'),
        meta: {
          title: "订单详情",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "shop-management",
        name: "ShopManagement",
        component: () => import('../pages/merchant/ShopManagement.vue'),
        meta: {
          title: "店铺管理",
          requiresAuth: true // 商家后台需要登录
        }
      },
      {
        path: "profile",
        name: "MerchantProfile",
        component: () => import('../pages/merchant/MerchantProfile.vue'),
        meta: {
          title: "个人中心",
          requiresAuth: true // 商家后台需要登录
        }
      },
    ]
  },
  // 管理员后台路由
  {
    path: "/admin-dashboard",
    name: "AdminDashboard",
    component: () => import('../components/AdminLayout.vue'),
    meta: {
      title: "管理员后台首页",
      requiresAuth: true // 管理员后台需要登录
    },
    children: [
      {
        path: "",
        name: "AdminHome",
        component: () => import('../pages/admin/Dashboard.vue'),
        meta: {
          title: "管理员后台首页",
          requiresAuth: true // 管理员后台需要登录
        }
      },
      {
        path: "user-management",
        name: "UserManagement",
        component: () => import('../pages/admin/UserManagement.vue'),
        meta: {
          title: "普通用户管理",
          requiresAuth: true // 普通用户管理需要登录
        }
      },
      {
        path: "merchant-management",
        name: "MerchantManagement",
        component: () => import('../pages/admin/MerchantManagement.vue'),
        meta: {
          title: "商家账户管理",
          requiresAuth: true // 商家账户管理需要登录
        }
      },
      {
        path: "merchant-audit",
        name: "MerchantAudit",
        component: () => import('../pages/admin/MerchantAudit.vue'),
        meta: {
          title: "商家认证审核",
          requiresAuth: true // 商家认证审核需要登录
        }
      },
      {
        path: "product-audit",
        name: "ProductAudit",
        component: () => import('../pages/admin/ProductAudit.vue'),
        meta: {
          title: "商品审核",
          requiresAuth: true // 商品审核需要登录
        }
      },
      {
        path: "category-management",
        name: "CategoryManagement",
        component: () => import('../pages/admin/CategoryManagement.vue'),
        meta: {
          title: "商品分类管理",
          requiresAuth: true // 商品分类管理需要登录
        }
      },
      {
        path: "brand-management",
        name: "BrandManagement",
        component: () => import('../pages/admin/BrandManagement.vue'),
        meta: {
          title: "商品品牌管理",
          requiresAuth: true // 商品品牌管理需要登录
        }
      },
      {
        path: "notice-publish",
        name: "NoticePublish",
        component: () => import('../pages/admin/NoticePublish.vue'),
        meta: {
          title: "公告发布",
          requiresAuth: true // 公告发布需要登录
        }
      },
      {
        path: "profile",
        name: "AdminProfile",
        component: () => import('../pages/admin/AdminProfile.vue'),
        meta: {
          title: "个人中心",
          requiresAuth: true // 管理员后台需要登录
        }
      }
    ]
  },
  // 超级管理员后台路由 - 包含管理员的所有功能
  {
    path: "/super-admin-dashboard",
    name: "SuperAdminDashboard",
    component: () => import('../components/SuperAdminLayout.vue'),
    meta: {
      title: "超级管理员后台首页",
      requiresAuth: true // 超级管理员后台需要登录
    },
    children: [
      {
        path: "",
        name: "SuperAdminHome",
        component: () => import('../pages/super-admin/Dashboard.vue'),
        meta: {
          title: "超级管理员后台首页",
          requiresAuth: true // 超级管理员后台需要登录
        }
      },
      {
        path: "admin-management",
        name: "AdminManagement",
        component: () => import('../pages/super-admin/AdminManagement.vue'),
        meta: {
          title: "管理员管理",
          requiresAuth: true // 管理员管理需要登录
        }
      },
      {
        path: "permission-list",
        name: "PermissionList",
        component: () => import('../pages/super-admin/PermissionList.vue'),
        meta: {
          title: "权限列表",
          requiresAuth: true // 权限列表需要登录
        }
      },
      {
        path: "dynamic-permission",
        name: "DynamicPermission",
        component: () => import('../pages/super-admin/DynamicPermission.vue'),
        meta: {
          title: "动态权限分配",
          requiresAuth: true // 动态权限分配需要登录
        }
      },
      // 复制管理员后台的所有子路由，让超级管理员可以访问
      {
        path: "user-management",
        name: "SuperUserManagement",
        component: () => import('../pages/admin/UserManagement.vue'),
        meta: {
          title: "普通用户管理",
          requiresAuth: true // 普通用户管理需要登录
        }
      },
      {
        path: "merchant-management",
        name: "SuperMerchantManagement",
        component: () => import('../pages/admin/MerchantManagement.vue'),
        meta: {
          title: "商家账户管理",
          requiresAuth: true // 商家账户管理需要登录
        }
      },
      {
        path: "merchant-audit",
        name: "SuperMerchantAudit",
        component: () => import('../pages/admin/MerchantAudit.vue'),
        meta: {
          title: "商家认证审核",
          requiresAuth: true // 商家认证审核需要登录
        }
      },
      {
        path: "product-audit",
        name: "SuperProductAudit",
        component: () => import('../pages/admin/ProductAudit.vue'),
        meta: {
          title: "商品审核",
          requiresAuth: true // 商品审核需要登录
        }
      },
      {
        path: "category-management",
        name: "SuperCategoryManagement",
        component: () => import('../pages/admin/CategoryManagement.vue'),
        meta: {
          title: "商品分类管理",
          requiresAuth: true // 商品分类管理需要登录
        }
      },
      {
        path: "brand-management",
        name: "SuperBrandManagement",
        component: () => import('../pages/admin/BrandManagement.vue'),
        meta: {
          title: "商品品牌管理",
          requiresAuth: true // 商品品牌管理需要登录
        }
      },
      {
        path: "notice-publish",
        name: "SuperNoticePublish",
        component: () => import('../pages/admin/NoticePublish.vue'),
        meta: {
          title: "公告发布",
          requiresAuth: true // 公告发布需要登录
        }
      },
      {
        path: "profile",
        name: "SuperAdminProfile",
        component: () => import('../pages/super-admin/SuperAdminProfile.vue'),
        meta: {
          title: "个人中心",
          requiresAuth: true // 超级管理员后台需要登录
        }
      }
    ]
  },
  {
    path:'/',
    name:'Header',
    component: Header,
    meta: { title: "导航栏" },
    children:[
      {
        path: "/index",
        name: "Index",
        component: Index,
        meta: {
          title: "首页",
          requiresAuth: false // 首页无需登录
        }
      },
      {
        path: "/shop",
        name: "Shop",
        component: Shop,
        meta: {
          title: "器材商城",
          requiresAuth: false // 器材商城无需登录
        }
      },
      {
        path: "/product/:id",
        name: "ProductDetail",
        component: ProductDetail,
        meta: {
          title: "商品详情",
          requiresAuth: false // 商品详情无需登录
        }
      },
      {
        path: "/order/confirm/:orderId?",
        name: "OrderConfirm",
        component: OrderConfirm,
        meta: {
          title: "确认订单",
          requiresAuth: true
        }
      },
      {
        path: "/order/payment/:paymentId",
        name: "Payment",
        component: Payment,
        meta: {
          title: "支付订单",
          requiresAuth: true
        }
      },
      {
        path: "/second-hand",
        name: "SecondHand",
        component: SecondHand,
        meta: {
          title: "二手交易",
          requiresAuth: false // 二手交易无需登录
        }
      },
      {
        path: "/second-hand/detail/:id",
        name: "SecondHandDetail",
        component: SecondHandDetail,
        meta: {
          title: "二手商品详情",
          requiresAuth: false // 二手商品详情无需登录
        }
      },
      {
        path: "/rental",
        name: "Rental",
        component: Rental,
        meta: {
          title: "租赁市场",
          requiresAuth: false // 租赁市场无需登录
        }
      },
      {
        path: "/rental/detail/:id",
        name: "RentalDetail",
        component: RentalDetail,
        meta: {
          title: "租赁商品详情",
          requiresAuth: false // 租赁商品详情无需登录
        }
      },
      {
        path: "/community",
        name: "Community",
        component: () => import('../pages/user/Community.vue'),
        meta: {
          title: "社区订阅",
          requiresAuth: false // 社区订阅无需登录
        }
      },
      // 需要登录的页面
      {
        path: "/cart",
        name: "Cart",
        component: () => import('../pages/user/Cart.vue'),
        meta: {
          title: "购物车",
          requiresAuth: true // 购物车需要登录
        }
      },
      {
        path: "/favorites",
        name: "Favorites",
        component: () => import('../pages/user/Favorites.vue'),
        meta: {
          title: "我的收藏",
          requiresAuth: true // 收藏需要登录
        }
      },
      {
        path: "/messages",
        name: "Messages",
        component: MessageDrawer,
        meta: {
          title: "消息中心",
          requiresAuth: true // 消息需要登录
        }
      },
      {
        path: "/orders",
        name: "Orders",
        component: () => import('../pages/user/MyOrders.vue'),
        meta: {
          title: "我的订单",
          requiresAuth: true // 订单需要登录
        }
      },
      {
        path: "/order/detail/:orderId",
        name: "OrderDetail",
        component: OrderDetail,
        meta: {
          title: "订单详情",
          requiresAuth: true // 订单详情需要登录
        }
      },
      {
        path: "/address",
        name: "Address",
        component: () => import('../pages/user/Address.vue'),
        meta: {
          title: "地址管理",
          requiresAuth: true // 地址管理需要登录
        }
      },
      {
        path: "/profile",
        name: "Profile",
        component: () => import('../pages/user/Profile.vue'),
        meta: {
          title: "个人中心",
          requiresAuth: true // 个人中心需要登录
        }
      },
      {
        path: "/footer",
        name: "Footer",
        component: Footer,
        meta: {
          title: "页脚"
        }
      },
      {
        path: "/rightsticky",
        name: "RightSticky",
        component: RightSticky,
        meta: {
          title: "右 sticky 导航栏"
        }
      },

    ]
  }
]

const asyncRoutes = [{
  path: "/index",
  name: "Index",
  component: Index,
  meta: {
    title: "首页",
    requiresAuth: true // 标记需要登录权限（可选，增强语义）
  }
}];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  // 添加scrollBehavior配置，解决页面跳转时的滚动位置问题
  scrollBehavior() {
    // 每次导航都滚动到页面顶部
    return { top: 0 }
  }
})

// 路由守卫：动态设置标题 + 基础权限控制（可选）
router.beforeEach((to) => {
  const userStore = useUserStore()

  // 设置页面标题
  if (to.meta.title) {
    document.title = to.meta.title as string
  }

  // 权限控制：需要登录但未登录时跳转到登录页
  if (to.meta.requiresAuth && !userStore.isLoggedIn) {
    ElMessage.warning('请先登录后再访问')
    return '/login'
  }

  // 如果已经登录但访问登录/注册页，跳转到首页
  if ((to.path === '/login' || to.path === '/register') && userStore.isLoggedIn) {
    return '/index'
  }
})
// 动态添加路由的方法
export function addRoutes(menus: any){
    // 是否有新的路由
    let hasNewRoutes = false
    const findAndAddRoutesByMenus = (arr: any[]) =>{
        arr.forEach(e=>{
            const item = asyncRoutes.find(o=>o.path == e.frontpath)
            if(item && !router.hasRoute(item.path)){
                router.addRoute("admin",item)
                hasNewRoutes = true
            }
            if(e.child && e.child.length > 0){
                findAndAddRoutesByMenus(e.child)
            }
        })
    }

    findAndAddRoutesByMenus(menus)

    return hasNewRoutes
}

export default router
