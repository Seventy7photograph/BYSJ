<template>
  <div class="filter-content">
    <div class="filter-body">
      <!-- 价格区间 -->
      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">价格区间</h4>
        </div>
        <div class="section-content price-range">
          <el-radio-group v-model="localFilterParams.priceRange">
            <el-radio-button v-for="range in priceRanges" :key="range.value" :label="range.value">
              {{ range.label }}
            </el-radio-button>
          </el-radio-group>
          <div class="custom-price">
            <el-input-number
              v-model="localFilterParams.priceMin"
              :min="0"
              :step="100"
              placeholder="最低价"
            />
            <span class="price-separator">-</span>
            <el-input-number
              v-model="localFilterParams.priceMax"
              :min="0"
              :step="100"
              placeholder="最高价"
            />
          </div>
        </div>
      </div>

      <!-- 相机相关筛选 -->
      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">拍摄场景</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('scene')"
          >
            {{ localFilterParams.expandedSections.scene ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.scene" class="section-content">
          <el-checkbox-group v-model="localFilterParams.scenes">
            <el-checkbox-button v-for="scene in cameraScenes" :key="scene" :label="scene">
              {{ scene }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">视频能力</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('video')"
          >
            {{ localFilterParams.expandedSections.video ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.video" class="section-content">
          <el-checkbox-group v-model="localFilterParams.videoAbilities">
            <el-checkbox-button v-for="ability in videoAbilities" :key="ability" :label="ability">
              {{ ability }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">防抖类型</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('stabilization')"
          >
            {{ localFilterParams.expandedSections.stabilization ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.stabilization" class="section-content">
          <el-checkbox-group v-model="localFilterParams.stabilizations">
            <el-checkbox-button v-for="stabilization in stabilizations" :key="stabilization" :label="stabilization">
              {{ stabilization }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">拍摄位置</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('position')"
          >
            {{ localFilterParams.expandedSections.position ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.position" class="section-content">
          <el-checkbox-group v-model="localFilterParams.positions">
            <el-checkbox-button v-for="position in positions" :key="position" :label="position">
              {{ position }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">传感器类型</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('sensor')"
          >
            {{ localFilterParams.expandedSections.sensor ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.sensor" class="section-content">
          <el-checkbox-group v-model="localFilterParams.sensors">
            <el-checkbox-button v-for="sensor in sensors" :key="sensor" :label="sensor">
              {{ sensor }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">系列</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('series')"
          >
            {{ localFilterParams.expandedSections.series ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.series" class="section-content">
          <el-checkbox-group v-model="localFilterParams.series">
            <el-checkbox-button v-for="series in cameraSeries" :key="series" :label="series">
              {{ series }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <!-- 镜头相关筛选 -->
      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">镜头类型</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('lensType')"
          >
            {{ localFilterParams.expandedSections.lensType ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.lensType" class="section-content">
          <el-checkbox-group v-model="localFilterParams.lensTypes">
            <el-checkbox-button v-for="type in lensTypes" :key="type" :label="type">
              {{ type }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">焦距</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('focalLength')"
          >
            {{ localFilterParams.expandedSections.focalLength ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.focalLength" class="section-content">
          <el-checkbox-group v-model="localFilterParams.focalLengths">
            <el-checkbox-button v-for="length in focalLengths" :key="length" :label="length">
              {{ length }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">光圈</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('aperture')"
          >
            {{ localFilterParams.expandedSections.aperture ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.aperture" class="section-content">
          <el-checkbox-group v-model="localFilterParams.apertures">
            <el-checkbox-button v-for="aperture in apertures" :key="aperture" :label="aperture">
              {{ aperture }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <!-- 无人机相关筛选 -->
      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">续航时间</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('flightTime')"
          >
            {{ localFilterParams.expandedSections.flightTime ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.flightTime" class="section-content">
          <el-checkbox-group v-model="localFilterParams.flightTimes">
            <el-checkbox-button v-for="time in flightTimes" :key="time" :label="time">
              {{ time }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>

      <div class="filter-section">
        <div class="section-header">
          <h4 class="filter-section-title">相机像素</h4>
          <el-button
            type="text"
            size="small"
            @click="toggleSection('cameraPixel')"
          >
            {{ localFilterParams.expandedSections.cameraPixel ? '收起' : '展开' }}
          </el-button>
        </div>

        <div v-if="localFilterParams.expandedSections.cameraPixel" class="section-content">
          <el-checkbox-group v-model="localFilterParams.cameraPixels">
            <el-checkbox-button v-for="pixel in cameraPixels" :key="pixel" :label="pixel">
              {{ pixel }}
            </el-checkbox-button>
          </el-checkbox-group>
        </div>
      </div>
    </div>

    <div class="filter-footer">
      <el-button type="default" @click="$emit('reset')" style="margin-right: 80px;">重置</el-button>
      <el-button type="primary" @click="$emit('confirm')">确认</el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

// 定义属性
const props = defineProps({
  filterParams: {
    type: Object,
    default: () => ({})
  }
});

// 定义事件
const emit = defineEmits(['update:filterParams', 'reset', 'confirm']);

// 本地筛选参数
const localFilterParams = ref({
  priceMin: null,
  priceMax: null,
  priceRange: null,
  scenes: [],
  videoAbilities: [],
  stabilizations: [],
  positions: [],
  sensors: [],
  series: [],
  lensTypes: [],
  focalLengths: [],
  apertures: [],
  flightTimes: [],
  cameraPixels: [],
  expandedSections: {
    scene: true,
    video: true,
    stabilization: true,
    position: true,
    sensor: true,
    series: true,
    lensType: true,
    focalLength: true,
    aperture: true,
    flightTime: true,
    cameraPixel: true
  }
});

// 监听父组件传递的筛选参数变化
watch(() => props.filterParams, (newParams) => {
  // 深度合并expandedSections，保留子组件中已有的属性
  localFilterParams.value = {
    ...localFilterParams.value,
    ...newParams,
    expandedSections: {
      ...localFilterParams.value.expandedSections,
      ...newParams.expandedSections
    }
  };
}, { deep: true, immediate: true });

// 监听本地筛选参数变化，实时通知父组件
watch(localFilterParams, (newParams) => {
  emit('update:filterParams', newParams);
}, { deep: true });

// 价格区间
const priceRanges = ref([
  { label: "50-450", value: "50-450" },
  { label: "450-3159", value: "450-3159" },
  { label: "3159-52980", value: "3159-52980" }
]);

// 相机相关数据
const cameraScenes = ref([
  "人物摄影", "风光摄影", "静物摄影",
  "全景拍摄", "运动抓拍", "美颜摄影"
]);

const videoAbilities = ref([
  "4K 60P", "4K 120P", "4K 30P",
  "1080P 30P", "4K 240P", "6K 60P"
]);

const stabilizations = ref([
  "电子防抖", "不防抖", "多重防抖",
  "六轴防抖", "双重防抖", "光学防抖"
]);

const positions = ref([
  "地面拍摄", "空中拍摄", "水下拍摄",
  "全景拍摄", "运动拍摄", "延时拍摄"
]);

const sensors = ref([
  "全画幅", "APS-C", "M43",
  "1英寸", "中画幅", "其他"
]);

const cameraSeries = ref([
  "EOS R系列", "EOS M系列", "EOS KISS系列",
  "EOS 系列", "PowerShot系列", "其他"
]);

// 镜头相关数据
const lensTypes = ref([
  "广角镜头", "标准镜头", "长焦镜头",
  "定焦镜头", "变焦镜头", "微距镜头"
]);

const focalLengths = ref([
  "超广角", "广角", "标准",
  "中焦", "长焦", "超长焦"
]);

const apertures = ref([
  "f/1.2", "f/1.4", "f/1.8",
  "f/2.8", "f/4", "f/5.6"
]);

// 无人机相关数据
const flightTimes = ref([
  "15分钟以下", "15-25分钟", "25-35分钟",
  "35-45分钟", "45分钟以上"
]);

const cameraPixels = ref([
  "1200万以下", "1200-2400万", "2400-4800万",
  "4800万-1亿", "1亿以上"
]);

// 切换展开/收起
const toggleSection = (section) => {
  localFilterParams.value.expandedSections[section] = !localFilterParams.value.expandedSections[section];
};

// 价格验证逻辑：确保最高价不低于最低价
const validatePriceRange = () => {
  const { priceMin, priceMax } = localFilterParams.value;

  // 如果两者都有值，确保最高价不低于最低价
  if (priceMin !== null && priceMax !== null && priceMax < priceMin) {
    // 可以选择两种处理方式：
    // 1. 将最高价调整为与最低价+100
    localFilterParams.value.priceMax = priceMin+100;
    // 2. 清空最高价
    // localFilterParams.value.priceMax = null;
  }
};

// 监听价格输入变化
watch(() => [localFilterParams.value.priceMin, localFilterParams.value.priceMax], () => {
  // 如果手动输入了价格，清除价格区间选择
  if (localFilterParams.value.priceMin !== null || localFilterParams.value.priceMax !== null) {
    localFilterParams.value.priceRange = null;
  }

  // 验证价格范围
  validatePriceRange();
}, { immediate: true });

// 监听价格区间变化
watch(() => localFilterParams.value.priceRange, (newRange) => {
  // 如果选择了价格区间，清除手动输入的价格
  if (newRange) {
    localFilterParams.value.priceMin = null;
    localFilterParams.value.priceMax = null;
  }
});

</script>

<style scoped>
.filter-content {
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 10px;
}

.filter-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 10px;
  margin-bottom: 20px;
}

.filter-title {
  margin: 0;
  font-size: 18px;
  font-weight: bold;
}

.filter-body {
  flex: 1;
  overflow-y: auto;
  padding: 0 10px;
}

.filter-section {
  margin-bottom: 20px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  overflow: hidden;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 15px;
  background-color: #f5f7fa;
  border-bottom: 1px solid #ebeef5;
}

.filter-section-title {
  margin: 0;
  font-size: 16px;
  font-weight: 500;
}

.section-content {
  padding: 15px;
}

.price-range {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.custom-price {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
}

.price-separator {
  color: #909399;
}

.filter-footer {
  display: flex;
  justify-content: center;
  padding: 15px;
  border-top: 1px solid #ebeef5;
  margin-top: 20px;
}

/* 自定义滚动条样式 */
.filter-body::-webkit-scrollbar {
  width: 6px;
}

.filter-body::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.filter-body::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.filter-body::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style>
