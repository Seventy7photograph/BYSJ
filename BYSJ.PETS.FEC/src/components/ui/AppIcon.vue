<script setup lang="ts">
import { computed } from 'vue'
import {
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  ArrowUp,
  Bell,
  Box,
  Calendar,
  Camera,
  ChatDotRound,
  Check,
  CircleCheck,
  CircleClose,
  Clock,
  Close,
  Coin,
  CopyDocument,
  CreditCard,
  DataLine,
  Delete,
  Discount,
  Document,
  Download,
  Edit,
  Filter,
  Goods,
  Grid,
  Headset,
  Hide,
  HomeFilled,
  InfoFilled,
  Key,
  Link,
  List,
  Loading,
  Location,
  Lock,
  Menu,
  Minus,
  Money,
  MoreFilled,
  Picture,
  Plus,
  Postcard,
  PriceTag,
  Refresh,
  Search,
  Sell,
  Setting,
  Shop,
  ShoppingCart,
  Sort,
  Star,
  Suitcase,
  SwitchButton,
  Tickets,
  Timer,
  Top,
  TrendCharts,
  Upload,
  User,
  Van,
  View,
  Wallet,
  Warning,
} from '@element-plus/icons-vue'

/**
 * 唯一的图标入口。
 *
 * 原代码在每个页面各自 import Element 图标，同一个概念在不同页面用不同图标，
 * 尺寸和描边也各写各的。这里收敛成一份登记表：一个名字一个含义、一个线宽，
 * 换图标只需要改这一处。
 */
const REGISTRY = {
  search: Search,
  cart: ShoppingCart,
  star: Star,
  bell: Bell,
  menu: Menu,
  close: Close,
  'chevron-down': ArrowDown,
  'chevron-up': ArrowUp,
  'chevron-left': ArrowLeft,
  'chevron-right': ArrowRight,
  'arrow-up': Top,
  user: User,
  order: Tickets,
  document: Document,
  location: Location,
  plus: Plus,
  minus: Minus,
  edit: Edit,
  trash: Delete,
  check: Check,
  'check-circle': CircleCheck,
  'close-circle': CircleClose,
  warning: Warning,
  info: InfoFilled,
  ship: Van,
  box: Box,
  money: Money,
  coin: Coin,
  wallet: Wallet,
  card: CreditCard,
  discount: Discount,
  chart: TrendCharts,
  data: DataLine,
  setting: Setting,
  shop: Shop,
  goods: Goods,
  sell: Sell,
  list: List,
  grid: Grid,
  clock: Clock,
  timer: Timer,
  calendar: Calendar,
  refresh: Refresh,
  upload: Upload,
  download: Download,
  filter: Filter,
  sort: Sort,
  more: MoreFilled,
  view: View,
  hide: Hide,
  message: ChatDotRound,
  service: Headset,
  camera: Camera,
  picture: Picture,
  tag: PriceTag,
  id: Postcard,
  lock: Lock,
  key: Key,
  logout: SwitchButton,
  home: HomeFilled,
  luggage: Suitcase,
  link: Link,
  copy: CopyDocument,
  loading: Loading,
} as const

export type IconName = keyof typeof REGISTRY

const props = withDefaults(
  defineProps<{
    name: IconName
    /** 视觉尺寸（px）。等比缩放，线宽随字号走，保持全站一致。 */
    size?: number | string
    /** 与相邻文字一起进入无障碍树时置 false。 */
    label?: string
  }>(),
  { size: 16, label: '' },
)

const glyph = computed(() => REGISTRY[props.name])
const px = computed(() => (typeof props.size === 'number' ? `${props.size}px` : props.size))
</script>

<template>
  <el-icon class="app-icon" :size="px" :aria-hidden="label ? undefined : 'true'" :aria-label="label || undefined">
    <component :is="glyph" />
  </el-icon>
</template>

<style scoped>
.app-icon {
  vertical-align: -0.15em;
  flex-shrink: 0;
}
</style>
