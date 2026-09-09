<template>
  <!-- 轮播图 -->
  <div class="carousel-container">
  <el-carousel :interval="4000" type="card" height="400px">
    <el-carousel-item v-for="item in carouselImages" :key="item.id">
      <div class="carousel-image-container">
        <img :src="item.src" :alt="item.alt" class="carousel-image" />
      </div>
    </el-carousel-item>
  </el-carousel>
  </div>
  <!-- 分割线 -->
<el-divider />
<h2 class="section-title">
  热门全新
  <img src="../../../public/new.png" alt="全新" class="title-icon" style="width: 30px; margin-right: 5px;"/>
</h2>
  <!-- 商城选项卡(标签页) -->
<div class="tabs-container">
    <el-tabs v-model="activeTab1" type="card" :closable="false">
      <el-button type="primary" @click="goShop" style="float: right;">前往商城 ></el-button>
      <el-tab-pane label="热门商品" name="hot">
        <div class="products-container">
          <!-- 热门商品列表 -->
          <div class="product-item" v-for="product in hotProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="相机" name="xiangji">
        <div class="products-container">
          <!-- 相机商品列表 -->
          <div class="product-item" v-for="product in cameraProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="镜头" name="jingtou">
        <div class="products-container">
          <!-- 镜头商品列表 -->
          <div class="product-item" v-for="product in lensProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="运动相机" name="yundongxiangji">
        <div class="products-container">
          <!-- 运动相机商品列表 -->
          <div class="product-item" v-for="product in yundongXiangjiProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="无人机" name="wurenji">
        <div class="products-container">
          <!-- 无人机商品列表 -->
          <div class="product-item" v-for="product in wurenjiProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </div>
  <el-divider />

   <!-- 二手选项卡(标签页) -->
    <h2 class="section-title">
  二手器材
  <img src="../../../public/二手市场.png" alt="二手" class="title-icon" style="width: 25px; margin-right: 5px;"/>
</h2>
<div class="tabs-container">
    <el-tabs v-model="activeTab2" type="card" :closable="false">
      <el-button type="primary" @click="goSecondHand" style="float: right;">前往二手交易 ></el-button>
      <el-tab-pane label="热门二手" name="hot">
        <div class="products-container">
          <!-- 热门二手商品列表 -->
          <div class="product-item" v-for="product in hotSecondProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="相机" name="xiangji">
        <div class="products-container">
          <!-- 二手相机商品列表 -->
          <div class="product-item" v-for="product in secondCameraProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="镜头" name="jingtou">
        <div class="products-container">
          <!-- 二手镜头商品列表 -->
          <div class="product-item" v-for="product in secondLensProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="运动相机" name="yundongxiangji">
        <div class="products-container">
          <!-- 二手运动相机商品列表 -->
          <div class="product-item" v-for="product in secondYundongXiangjiProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="无人机" name="wurenji">
        <div class="products-container">
          <!-- 二手无人机商品列表 -->
          <div class="product-item" v-for="product in secondWurenjiProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </div>
  <el-divider />

   <!-- 租赁选项卡(标签页) -->
    <h2 class="section-title">
  租赁器材
  <img src="../../../public/设备租赁.png" alt="租赁" class="title-icon" style="width: 30px; margin-right: 5px;"/>
</h2>
<div class="tabs-container">
    <el-tabs v-model="activeTab3" type="card" :closable="false">
      <el-button type="primary" @click="goRent" style="float: right;">前往租赁 ></el-button>
      <el-tab-pane label="热门租赁" name="hot">
        <div class="products-container">
          <!-- 热门租赁商品列表 -->
          <div class="product-item" v-for="product in hotRentalProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="相机" name="xiangji">
        <div class="products-container">
          <!-- 租赁相机商品列表 -->
          <div class="product-item" v-for="product in rentalCameraProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="镜头" name="jingtou">
        <div class="products-container">
          <!-- 租赁镜头商品列表 -->
          <div class="product-item" v-for="product in rentalLensProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="运动相机" name="yundongxiangji">
        <div class="products-container">
          <!-- 租赁运动相机商品列表 -->
          <div class="product-item" v-for="product in rentalYundongXiangjiProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="无人机" name="wurenji">
        <div class="products-container">
          <!-- 租赁无人机商品列表 -->
          <div class="product-item" v-for="product in rentalWurenjiProducts" :key="product.id">
            <div class="product-image">
              <img :src="product.image" :alt="product.name">
            </div>
            <div class="product-info">
              <div class="product-name">{{ product.name }}</div>
              <div class="product-price">{{ product.price }}</div>
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </div>
  <el-divider />


</template>

<script lang="ts" setup name="Index">
import { ref } from 'vue'
import router from '@/router'
import type { TabsPaneContext } from 'element-plus'

// 轮播图数据
const carouselImages = [
  {
    id: 1,
    src: '/Nikon/宣传/ZR.png',
    alt: '尼康 ZR 微单相机'
  },
  {
    id: 2,
    src: '/Nikon/宣传/ZF.png',
    alt: '尼康 ZF 复古微单'
  },
  {
    id: 3,
    src: '/Nikon/宣传/Z52.png',
    alt: '尼康 Z5 II 全画幅微单'
  },
  {
    id: 4,
    src: '/Nikon/宣传/Z63.png',
    alt: '尼康 Z6 III 专业微单'
  },
  {
    id: 5,
    src: '/Nikon/宣传/Z9.png',
    alt: '尼康 Z9 旗舰微单'
  },
  {
    id: 6,
    src: '/Nikon/宣传/Z8.png',
    alt: '尼康 Z8 高端微单'
  }
]

// 激活的标签页
const activeTab1 = ref('hot');
const activeTab2 = ref('hot');
const activeTab3 = ref('hot');

// 商城 - 热门商品
const hotProducts = ref([
  { id: 1, name: '索尼 A7M4 全画幅微单相机', price: '¥16,999', image: 'public/Sony/camera/A7M4/image.png' },
  { id: 2, name: '佳能 RF 24-70mm F2.8 L IS USM 镜头', price: '¥15,999', image: 'public/Canon/lens/RF 24-70mm F2.8 L IS USM/image.png' },
  { id: 3, name: '尼克尔 Z 70-200mm F2.8 VR S 镜头', price: '¥17,999', image: 'public/Nikon/lens/尼克尔 Z 70-200mm f2.8 VR S/image.png' },
  { id: 4, name: 'DJI Mavic 4 Pro 无人机', price: '¥13,888', image: 'public/Dji/Drone/Mavic/Mavic 4 Pro/image.png' },
  { id: 5, name: 'GoPro HERO12 Black 运动相机', price: '¥3,498', image: 'public/GoPro/HERO Black/HERO12 Black/image.png' },
  { id: 6, name: '索尼 FE 85mm F1.4 GM II人像镜头', price: '¥10,999', image: 'public/Sony/lens/FE 85mm F1.4 GM II/image.png' },
  { id: 7, name: '富士 X-T5 微单相机', price: '¥12,790', image: 'public/Fujifilm/camera/X-T5/image.png' },
  { id: 8, name: '佳能 EOS R5 Mark II 全画幅微单', price: '¥30,599', image: 'public/Canon/camera/EOS R5 Mark II/image.png' },
  { id: 9, name: '尼克尔 Z 24-70mm F4 S 标准变焦镜头', price: '¥6,299', image: 'public/Nikon/lens/尼克尔 Z 24-70mm F4 S/image.png' },
  { id: 10, name: 'DJI Osmo Action 6 运动相机', price: '¥2,999', image: 'public/Dji/Action/Osmo Action 6/image.png' },
  { id: 11, name: '索尼 A7C II 全画幅微单相机', price: '¥11,499', image: 'public/Sony/camera/A7C II/image.png' },
  { id: 12, name: '腾龙 28-75mm F2.8 Di III VXD G2 镜头', price: '¥6,299', image: 'public/Tamron/lens/28-75mm F2.8 Di III VXD G2/image.png' },
  { id: 13, name: '大疆 Mini 4 Pro 无人机', price: '¥4,788', image: 'public/Dji/Drone/Mini/Mini 4 Pro/image.png' },
  { id: 14, name: '适马 85mm F1.4 DG DN Art 镜头', price: '¥6,999', image: 'public/Sigma/lens/85mm F1.4 DG DN Art/image.png' },
]);

// 商城 - 相机
const cameraProducts = ref([
  { id: 15, name: '索尼 A7R V 全画幅微单', price: '¥25,999', image: 'public/Sony/camera/A7R V/image.png' },
  { id: 16, name: '佳能 EOS R6 Mark II 微单相机', price: '¥16,499', image: 'public/Canon/camera/EOS R6 Mark II/image.png' },
  { id: 17, name: '尼康 ZR 紧凑型电影摄影机', price: '¥13,999', image: 'public/Nikon/camera/ZR/image.png' },
  { id: 18, name: '富士 X-S20 微单相机', price: '¥8,990', image: 'public/Fujifilm/camera/X-S20/image.png' },
  { id: 19, name: '松下 S5 II 全画幅微单', price: '¥11,998', image: 'public/Panasonic/camera/S5 II/image.png' },
  { id: 20, name: '索尼 A6700 APS-C 微单', price: '¥8,999', image: 'public/Sony/camera/A6700/image.png' },
  { id: 21, name: '佳能 EOS R10 微单相机', price: '¥5,399', image: 'public/Canon/camera/EOS R10/image.png' },
  { id: 22, name: '尼康 Z63 全画幅微单', price: '¥4,799', image: 'public/Nikon/camera/Z 63/image.png' },
  { id: 23, name: '富士 X-H2S 高速微单', price: '¥16,790', image: 'public/Fujifilm/camera/X-H2S/image.png' },
  { id: 24, name: '松下 GH6 视频微单', price: '¥12,998', image: 'public/Panasonic/camera/GH6/image.png' },
  { id: 25, name: '索尼 ZV-E1 视频微单', price: '¥12,499', image: 'public/Sony/camera/ZV-E1/image.png' },
  { id: 26, name: '佳能 EOS R7 微单相机', price: '¥9,399', image: 'public/Canon/camera/EOS R7/image.png' },
  { id: 27, name: '尼康 Z5 II 全画幅微单', price: '¥18,999', image: 'public/Nikon/camera/Z 52/image.png' },
  { id: 28, name: '徕卡 Q2 全画幅相机', price: '¥42,999', image: 'public/Leica/camera/Q/Q2/image.png' },
]);

// 商城 - 镜头
const lensProducts = ref([
  { id: 29, name: '索尼 FE 24-70mm F2.8 GM II 镜头', price: '¥17,999', image: 'public/Sony/lens/FE 24-70mm F2.8 GM II/image.png' },
  { id: 30, name: '佳能 RF 70-200mm F2.8 L IS USM 镜头', price: '¥16,999', image: 'public/Canon/lens/RF 70-200mm F2.8 L IS USM/image.png' },
  { id: 31, name: '尼克尔 Z 24-120mm F4 S 镜头', price: '¥8,299', image: 'public/Nikon/lens/尼克尔 Z 24-120mm F4 S/image.png' },
  { id: 32, name: '适马 24-70mm F2.8 DG DN Art 镜头', price: '¥7,299', image: 'public/Sigma/lens/24-70mm F2.8 DG DN Art/image.png' },
  { id: 33, name: '腾龙 70-180mm F2.8 Di III VXD 镜头', price: '¥6,999', image: 'public/Tamron/lens/70-180mm F2.8 Di III VXD/image.png' },
  { id: 34, name: '索尼 FE 16-35mm F2.8 GM II 广角镜头', price: '¥15,999', image: 'public/Sony/lens/FE 16-35mm F2.8 GM II/image.png' },
  { id: 35, name: '佳能 RF 50mm F1.2 L USM 定焦镜头', price: '¥12,999', image: 'public/Canon/lens/RF 50mm F1.2 L USM/image.png' },
  { id: 36, name: '尼克尔 Z 50mm F1.8 S 标准定焦', price: '¥3,299', image: 'public/Nikon/lens/尼克尔 Z 50mm F1.8 S/image.png' },
  { id: 37, name: '适马 35mm F1.4 DG DN Art 镜头', price: '¥5,299', image: 'public/Sigma/lens/35mm F1.4 DG DN Art/image.png' },
  { id: 38, name: '腾龙 17-28mm F2.8 Di III RXD 广角镜头', price: '¥4,299', image: 'public/Tamron/lens/17-28mm F2.8 Di III RXD/image.png' },
  { id: 39, name: '索尼 FE 100-400mm F4.5-5.6 GM OSS 长焦', price: '¥15,999', image: 'public/Sony/lens/FE 100-400mm F4.5-5.6 GM OSS/image.png' },
  { id: 40, name: '佳能 RF 100-500mm F4.5-7.1 L IS USM 长焦', price: '¥13,999', image: 'public/Canon/lens/RF 100-500mm F4.5-7.1 L IS USM/image.png' },
  { id: 41, name: '尼克尔 Z 105mm F2.8 VR S 微距镜头', price: '¥8,999', image: 'public/Nikon/lens/尼克尔 Z 105mm F2.8 VR S 微距/image.png' },
  { id: 42, name: '适马 100-400mm F5-6.3 DG DN OS 长焦', price: '¥6,499', image: 'public/Sigma/lens/100-400mm F5-6.3 DG DN OS/image.png' },
]);

// 商城 - 运动相机
const yundongXiangjiProducts = ref([
  { id: 43, name: 'GoPro HERO12 Black 运动相机', price: '¥3,498', image: 'public/GoPro/HERO Black/HERO12 Black/image.png' },
  { id: 44, name: 'DJI Osmo Action 4 运动相机', price: '¥2,999', image: 'public/Dji/Action/Osmo Action 4/image.png' },
  { id: 45, name: 'GoPro HERO11 Black 运动相机', price: '¥2,998', image: 'public/GoPro/HERO Black/HERO11 Black/image.png' },
  { id: 46, name: 'Insta360 X3 全景运动相机', price: '¥3,498', image: 'public/Insta360/X/X3/image.png' },
  { id: 47, name: 'GoPro HERO10 Black 运动相机', price: '¥2,498', image: 'public/GoPro/HERO Black/HERO10 Black/image.png' },
  { id: 48, name: 'DJI Osmo Action 3 运动相机', price: '¥2,299', image: 'public/Dji/Action/Osmo Action 3/image.png' },
  { id: 49, name: 'Insta360 X5 运动相机', price: '¥2,798', image: 'public/Insta360/X/X5/image.png' },
  { id: 50, name: 'GoPro MAX 全景运动相机', price: '¥3,298', image: 'public/GoPro/MAX 360/MAX/image.png' },
  { id: 51, name: 'Action 6 运动相机', price: '¥2,799', image: 'public/Dji/Action/Osmo Action 6/image.png' },
  { id: 52, name: 'AKASO V50X 4K运动相机', price: '¥899', image: 'public/Akaso/V50X/image.png' },
  { id: 53, name: 'Insta360 GO 3S 拇指相机', price: '¥2,298', image: 'public/Insta360/GO/GO 3S/image.png' },
  { id: 54, name: 'DJI Pocket 2 口袋相机', price: '¥2,499', image: 'public/Dji/Pocket/Pocket 2/image.png' },
  { id: 55, name: 'GoPro HERO9 Black 运动相机', price: '¥2,198', image: 'public/GoPro/HERO Black/HERO9 Black/image.jpg' },
  { id: 56, name: 'Insta360 Ace Pro 2 全景相机', price: '¥2,998', image: 'public/Insta360/Ace Pro/Ace Pro 2/image.png' },
]);

// 商城 - 无人机
const wurenjiProducts = ref([
  { id: 57, name: 'DJI Mavic 3 Pro 无人机', price: '¥17,888', image: 'public/Dji/Drone/Mavic/Mavic 3 Pro/image.png' },
  { id: 58, name: 'DJI Air 3 无人机', price: '¥7,988', image: 'public/Dji/Drone/Air/Air 3/image.png' },
  { id: 59, name: 'DJI Mini 3 无人机', price: '¥4,788', image: 'public/Dji/Drone/Mini/Mini 3/image.png' },
  { id: 60, name: 'DJI Mavic 3无人机', price: '¥10,888', image: 'public/Dji/Drone/Mavic/Mavic 3/image.png' },
  { id: 61, name: 'DJI Mini 4 Pro 无人机', price: '¥5,788', image: 'public/Dji/Drone/Mini/Mini 4 Pro/image.png' },
  { id: 62, name: 'DJI Neo 无人机', price: '¥6,988', image: 'public/Dji/Drone/Neo/Neo/image.png' },
  { id: 63, name: 'DJI Avata 2无人机', price: '¥7,999', image: 'public/Dji/Drone/Avata/Avata2/image.png' },
  { id: 64, name: 'Autel EVO 2 无人机', price: '¥6,499', image: 'public/Autel/EVO 2/image.png' },
  { id: 65, name: 'DJI Mini 4K 无人机', price: '¥8,999', image: 'public/Dji/Drone/Mini/Mini 4K/image.png' },
  { id: 66, name: 'Parrot Anafi USA 无人机', price: '¥19,999', image: 'public/Parrot/Anafi USA/image.png' },
  { id: 67, name: 'DJI Mini 2 SE 无人机', price: '¥2,388', image: 'public/Dji/Drone/Mini/Mini 2 SE/image.png' },
  { id: 68, name: 'Autel EVO Lite 无人机', price: '¥3,699', image: 'public/Autel/EVO Lite/image.png' },
  { id: 69, name: 'DJI Inspire 3 专业无人机', price: '¥79,999', image: 'public/Dji/Drone/Inspire/Inspire 3/image.png' },
  { id: 70, name: 'Skydio X10 无人机', price: '¥12,999', image: 'public/Skydio/X10/image.png' },
]);

// 二手 - 热门二手
const hotSecondProducts = ref([
  { id: 1, name: '索尼 A7M3 全画幅微单（95新）', price: '¥9,999', image: 'public/Sony/camera/A7M3/image.png' },
  { id: 2, name: '佳能 EF 24-70mm F2.8 L II USM（9成新）', price: '¥6,999', image: 'public/Canon/lens/EF 24-70mm F2.8 L II USM/image.png' },
  { id: 3, name: '尼康 D850 单反相机（92新）', price: '¥11,999', image: 'public/Nikon/camera/D850/image.png' },
  { id: 4, name: 'DJI Mavic 3无人机（9成新）', price: '¥6,888', image: 'public/Dji/Drone/Mavic/Mavic 3/image.png' },
  { id: 5, name: 'GoPro HERO10 Black（95新）', price: '¥1,899', image: 'public/GoPro/HERO Black/HERO10 Black/image.png' },
  { id: 6, name: '索尼 FE 85mm F1.8 镜头（9成新）', price: '¥2,299', image: 'public/Sony/lens/FE 85mm F1.8/image.png' },
  { id: 7, name: '富士 X-T4 微单相机（93新）', price: '¥7,999', image: 'public/Fujifilm/camera/X-T4/image.png' },
  { id: 8, name: '佳能 EOS R 全画幅微单（9成新）', price: '¥8,499', image: 'public/Canon/camera/EOS R/image.png' },
  { id: 9, name: '尼克尔 Z 50mm F1.8 S 镜头（95新）', price: '¥2,699', image: 'public/Nikon/lens/尼克尔 Z 50mm F1.8 S/image.png' },
  { id: 10, name: 'DJI Osmo Action 2（9成新）', price: '¥1,699', image: 'public/Dji/Action/Osmo Action 2/image.png' },
  { id: 11, name: '索尼 A6400 微单相机（94新）', price: '¥4,599', image: 'public/Sony/camera/A6400/image.png' },
  { id: 12, name: '腾龙 28-75mm F2.8 Di III VXD G2 镜头（9成新）', price: '¥3,299', image: 'public/Tamron/lens/28-75mm F2.8 Di III VXD G2/image.png' },
  { id: 13, name: 'DJI Mini 2 SE无人机（95新）', price: '¥2,499', image: 'public/Dji/Drone/Mini/Mini 2 SE/image.png' },
  { id: 14, name: '适马 35mm F1.4 DG DN Art镜头（9成新）', price: '¥3,499', image: 'public/Sigma/lens/35mm F1.4 DG DN Art/image.png' },
]);

// 二手 - 相机
const secondCameraProducts = ref([
  { id: 15, name: '索尼 A7R III 全画幅微单（92新）', price: '¥12,999', image: 'public/Sony/camera/A7R III/image.png' },
  { id: 16, name: '佳能 EOS R6 微单相机（93新）', price: '¥11,499', image: 'public/Canon/camera/EOS R6/image.png' },
  { id: 17, name: '尼康 Z6 全画幅微单（9成新）', price: '¥7,999', image: 'public/Nikon/camera/Z 6/image.png' },
  { id: 18, name: '富士 X-T3 微单相机（94新）', price: '¥5,999', image: 'public/Fujifilm/camera/X-T3/image.png' },
  { id: 19, name: '松下 S1R 全画幅微单（9成新）', price: '¥9,999', image: 'public/Panasonic/camera/S1R/image.png' },
  { id: 20, name: '索尼 A6600 微单相机（95新）', price: '¥5,499', image: 'public/Sony/camera/A6600/image.png' },
  { id: 21, name: '佳能 EOS 5D Mark IV 单反（9成新）', price: '¥10,999', image: 'public/Canon/camera/EOS 5D Mark IV/image.png' },
  { id: 22, name: '尼康 D780 单反相机（93新）', price: '¥8,499', image: 'public/Nikon/camera/D780/image.png' },
  { id: 23, name: '富士 X-Pro3 复古微单（92新）', price: '¥8,999', image: 'public/Fujifilm/camera/X-Pro3/image.png' },
  { id: 24, name: '松下 GH5 视频微单（9成新）', price: '¥5,999', image: 'public/Panasonic/camera/GH5/image.png' },
  { id: 25, name: '索尼 A7C 全画幅微单（95新）', price: '¥9,499', image: 'public/Sony/camera/A7C/image.png' },
  { id: 26, name: '佳能 EOS R5 微单相机（9成新）', price: '¥20,999', image: 'public/Canon/camera/EOS R5/image.png' },
  { id: 27, name: '尼康 Z7 全画幅微单（92新）', price: '¥13,999', image: 'public/Nikon/camera/Z 7/image.png' },
  { id: 28, name: '徕卡 M11-P 旁轴相机（9成新）', price: '¥39,999', image: 'public/Leica/camera/M/M11-P/image.png' },
]);

// 二手 - 镜头
const secondLensProducts = ref([
  { id: 29, name: '索尼 FE 24-70mm F2.8 GM 镜头（9成新）', price: '¥9,999', image: 'public/Sony/lens/FE 24-70mm F2.8 GM/image.png' },
  { id: 30, name: '佳能 RF 70-200mm F2.8 L IS USM（92新）', price: '¥12,999', image: 'public/Canon/lens/RF 70-200mm F2.8 L IS USM/image.png' },
  { id: 31, name: '尼克尔 Z 24-70mm F4 S 镜头（95新）', price: '¥4,299', image: 'public/Nikon/lens/尼克尔 Z 24-70mm F4 S/image.png' },
  { id: 32, name: '适马 24-70mm F2.8 DG HSM Art（9成新）', price: '¥4,299', image: 'public/Sigma/lens/24-70mm F2.8 DG HSM Art/image.png' },
  { id: 33, name: '腾龙 70-200mm F2.8 Di VC USD G2（92新）', price: '¥5,499', image: 'public/Tamron/lens/70-200mm F2.8 Di VC USD G2/image.png' },
  { id: 34, name: '索尼 FE PZ 16-35mm F4 G（9成新）', price: '¥4,299', image: 'public/Sony/lens/FE PZ 16-35mm F4 G/image.png' },
  { id: 35, name: '佳能 EF 50mm F1.2 L USM（9成新）', price: '¥6,999', image: 'public/Canon/lens/EF 50mm F1.2 L USM/image.png' },
  { id: 36, name: '尼克尔 AF-S 50mm F1.4 G（95新）', price: '¥1,699', image: 'public/Nikon/lens/尼克尔 Z 50mm F1.8 S/image.png' },
  { id: 37, name: '适马 35mm F1.4 DG HSM Art（9成新）', price: '¥3,299', image: 'public/Sigma/lens/35mm F1.4 DG HSM Art/image.png' },
  { id: 38, name: '腾龙 15-30mm F2.8 Di VC USD G2（92新）', price: '¥2,299', image: 'public/Tamron/lens/15-30mm F2.8 Di VC USD G2/image.png' },
  { id: 39, name: '索尼 FE 70-200mm F4 G OSS（9成新）', price: '¥5,499', image: 'public/Sony/lens/FE 70-200mm F4 G OSS/image.png' },
  { id: 40, name: '佳能 EF 70-200mm F4 L IS USM（9成新）', price: '¥4,299', image: 'public/Canon/lens/EF 70-200mm F4 L IS USM/image.png' },
  { id: 41, name: '尼克尔 AF-S 105mm F2.8G ED VR（95新）', price: '¥3,299', image: 'public/Nikon/lens/尼克尔 Z 105mm F2.8 VR S 微距/image.png' },
  { id: 42, name: '适马 150-600mm F5-6.3 DG OS HSM（9成新）', price: '¥4,999', image: 'public/Sigma/lens/150-600mm F5-6.3 DG OS HSM/image.png' },
]);

// 二手 - 运动相机
const secondYundongXiangjiProducts = ref([
  { id: 43, name: 'GoPro HERO11 Black（9成新）', price: '¥2,499', image: 'public/GoPro/HERO Black/HERO11 Black/image.png' },
  { id: 44, name: 'DJI Osmo Action 3（95新）', price: '¥1,899', image: 'public/Dji/Action/Osmo Action 3/image.png' },
  { id: 45, name: 'GoPro HERO9 Black（9成新）', price: '¥1,699', image: 'public/GoPro/HERO Black/HERO9 Black/image.jpg' },
  { id: 46, name: 'Insta360 Ace Pro & Ace（92新）', price: '¥2,699', image: 'public/Insta360/Ace Pro/Ace Pro & Ace/image.png' },
  { id: 47, name: 'GoPro HERO8 Black（9成新）', price: '¥1,299', image: 'public/GoPro/HERO Black/HERO8 Black/image.jpg' },
  { id: 48, name: 'DJI Osmo Pocket 3（98新）', price: '¥2,999', image: 'public/Dji/Pocket/Osmo Pocket 3/image.png' },
  { id: 49, name: 'Insta360 X4（9成新）', price: '¥2,199', image: 'public/Insta360/X/X4/image.png' },
  { id: 50, name: 'GoPro MAX（92新）', price: '¥2,499', image: 'public/GoPro/MAX 360/MAX/image.png' },
  { id: 51, name: 'DJI Osmo Action 2（9成新）', price: '¥2,199', image: 'public/Dji/Action/Osmo Action 2/image.png' },
  { id: 52, name: 'Insta360 GO 3（9成新）', price: '¥1,499', image: 'public/Insta360/GO/GO 3/image.png' },
  { id: 53, name: 'DJI Pocket 2（92新）', price: '¥1,899', image: 'public/Dji/Pocket/Pocket 2/image.png' },
  { id: 54, name: 'GoPro HERO10 Black（95成新）', price: '¥999', image: 'public/GoPro/HERO Black/HERO10 Black/image.png' },
  { id: 55, name: 'Insta360 GO Ultra（9成新）', price: '¥2,299', image: 'public/Insta360/GO/GO Ultra/image.png' },
  { id: 56, name: 'AKASO V50X（95新）', price: '¥699', image: 'public/AKASO/V50X/image.png' },
]);

// 二手 - 无人机
const secondWurenjiProducts = ref([
  { id: 57, name: 'DJI Mavic 3（92新）', price: '¥10,888', image: 'public/Dji/Drone/Mavic/Mavic 3/image.png' },
  { id: 58, name: 'DJI Air 3（9成新）', price: '¥5,488', image: 'public/Dji/Drone/Air/Air 3/image.png' },
  { id: 59, name: 'DJI Mini 3（95新）', price: '¥3,888', image: 'public/Dji/Drone/Mini/Mini 3/image.png' },
  { id: 60, name: 'DJI Mavic 3 Pro（9成新）', price: '¥5,288', image: 'public/Dji/Drone/Mavic/Mavic 3 Pro/image.png' },
  { id: 61, name: 'DJI Mini 4K（92新）', price: '¥2,688', image: 'public/Dji/Drone/Mini/Mini 4K/image.png' },
  { id: 62, name: 'DJI Mavic 3（9成新）', price: '¥4,288', image: 'public/Dji/Drone/Mavic/Mavic 3/image.png' },
  { id: 63, name: 'DJI Neo（95新）', price: '¥6,499', image: 'public/Dji/Drone/Neo/Neo/image.png' },
  { id: 64, name: 'Autel EVO Lite（9成新）', price: '¥5,299', image: 'public/Autel/EVO Lite/image.png' },
  { id: 65, name: 'DJI Mavic 4 Pro（92新）', price: '¥3,288', image: 'public/Dji/Drone/Mavic/Mavic 4 Pro/image.png' },
  { id: 66, name: 'Parrot ANAFI USA MIL（9成新）', price: '¥2,999', image: 'public/Parrot/ANAFI USA MIL/image.png' },
  { id: 67, name: 'DJI Avata2（95新）', price: '¥1,288', image: 'public/Dji/Drone/Avata/Avata2/image.png' },
  { id: 68, name: 'Autel EVO 2（9成新）', price: '¥2,899', image: 'public/Autel/EVO 2/image.png' },
  { id: 69, name: 'DJI Inspire 3（92新）', price: '¥18,888', image: 'public/Dji/Drone/Inspire/Inspire 3/image.png' },
  { id: 70, name: 'Skydio X10D（99成新）', price: '¥9,999', image: 'public/Skydio/X10D/image.png' },
]);

// 租赁 - 热门商品
const hotRentalProducts = ref([
  { id: 1, name: '索尼 A7M4 全画幅微单', price: '¥120/天', image: 'public/Sony/camera/A7M4/image.png' },
  { id: 2, name: '佳能 RF24-70mm F2.8 L IS USM 镜头', price: '¥80/天', image: 'public/Canon/lens/RF24-70mm F2.8 L IS USM/image.png' },
  { id: 3, name: 'DJI Mavic 3 无人机', price: '¥150/天', image: 'public/Dji/Drone/Mavic/Mavic 3/image.png' },
  { id: 4, name: 'GoPro HERO12 Black', price: '¥50/天', image: 'public/GoPro/HERO Black/HERO12 Black/image.png' },
  { id: 5, name: '索尼 FE 85mm F1.4 GM 镜头', price: '¥70/天', image: 'public/Sony/lens/FE 85mm F1.4 GM/image.png' },
  { id: 6, name: '佳能 EOS R5 全画幅微单', price: '¥180/天', image: 'public/Canon/camera/EOS R5/image.png' },
  { id: 7, name: '尼克尔 Z 70-200mm F2.8 镜头', price: '¥90/天', image: 'public/Nikon/lens/尼克尔 Z 70-200mm f2.8 VR S/image.png' },
  { id: 8, name: 'DJI Air 3 无人机', price: '¥100/天', image: 'public/Dji/Drone/Air/Air 3/image.png' },
  { id: 9, name: '富士 X-T5 微单相机', price: '¥100/天', image: 'public/Fujifilm/camera/X-T5/image.png' },
  { id: 10, name: 'DJI Osmo Action 4', price: '¥40/天', image: 'public/Dji/Action/Osmo Action 4/image.png' },
  { id: 11, name: '适马 24-70mm F2.8 DG DN II Art镜头', price: '¥60/天', image: 'public/Sigma/lens/24-70mm F2.8 DG DN II Art/image.png' },
  { id: 12, name: '索尼 A7R V 全画幅微单', price: '¥200/天', image: 'public/Sony/camera/A7R V/image.png' },
  { id: 13, name: 'DJI Mini 4 Pro 无人机', price: '¥60/天', image: 'public/Dji/Drone/Mini/Mini 4 Pro/image.png' },
  { id: 14, name: '腾龙 70-180mm F2.8 镜头', price: '¥50/天', image: 'public/Tamron/lens/70-180mm F2.8 Di III VXD/image.png' },
]);

// 租赁 - 相机
const rentalCameraProducts = ref([
  { id: 15, name: '索尼 A7R V 全画幅微单', price: '¥200/天', image: 'public/Sony/camera/A7R V/image.png' },
  { id: 16, name: '佳能 EOS R6 Mark II', price: '¥130/天', image: 'public/Canon/camera/EOS R6 Mark II/image.png' },
  { id: 17, name: '尼康 Z6 II 全画幅微单', price: '¥110/天', image: 'public/Nikon/camera/Z 6II/image.png' },
  { id: 18, name: '富士 X-S20 微单相机', price: '¥90/天', image: 'public/Fujifilm/camera/X-S20/image.png' },
  { id: 19, name: '松下 S5 II 全画幅微单', price: '¥100/天', image: 'public/Panasonic/camera/S5 II/image.png' },
  { id: 20, name: '索尼 A6700 APS-C 微单', price: '¥80/天', image: 'public/Sony/camera/A6700/image.png' },
  { id: 21, name: '佳能 EOS R10 微单相机', price: '¥70/天', image: 'public/Canon/camera/EOS R10/image.png' },
  { id: 22, name: '尼康 Z30 APS-C 微单', price: '¥60/天', image: 'public/Nikon/camera/Z 30/image.png' },
  { id: 23, name: '富士 X-H2S 高速微单', price: '¥150/天', image: 'public/Fujifilm/camera/X-H2S/image.png' },
  { id: 24, name: '松下 GH6 视频微单', price: '¥120/天', image: 'public/Panasonic/camera/GH6/image.png' },
  { id: 25, name: '索尼 ZV-E1 视频微单', price: '¥110/天', image: 'public/Sony/camera/ZV-E1/image.png' },
  { id: 26, name: '佳能 EOS R7 微单相机', price: '¥80/天', image: 'public/Canon/camera/EOS R7/image.png' },
  { id: 27, name: '尼康 Z7 II 全画幅微单', price: '¥140/天', image: 'public/Nikon/camera/Z 7II/image.png' },
  { id: 28, name: '徕卡 Q2 全画幅相机', price: '¥300/天', image: 'public/Leica/camera/Q/Q2/image.png' },
]);

// 租赁 - 镜头
const rentalLensProducts = ref([
  { id: 29, name: '索尼 FE 24-70mm F2.8 GM II', price: '¥90/天', image: 'public/Sony/lens/FE 24-70mm F2.8 GM II/image.png' },
  { id: 30, name: '佳能 RF 70-200mm F2.8 L IS USM', price: '¥80/天', image: 'public/Canon/lens/RF 70-200mm F2.8 L IS USM/image.png' },
  { id: 31, name: '尼克尔 Z 24-120mm F4 S', price: '¥60/天', image: 'public/Nikon/lens/尼克尔 Z 24-120mm F4 S/image.png' },
  { id: 32, name: '适马 24-70mm F2.8 DG DN Art', price: '¥60/天', image: 'public/Sigma/lens/24-70mm F2.8 DG DN Art/image.png' },
  { id: 33, name: '腾龙 70-180mm F2.8 Di III VC VXD G2', price: '¥50/天', image: 'public/Tamron/lens/70-180mm F2.8 Di III VC VXD G2/image.png' },
  { id: 34, name: '索尼 FE 16-35mm F2.8 GM', price: '¥80/天', image: 'public/Sony/lens/FE 16-35mm F2.8 GM/image.png' },
  { id: 35, name: '佳能 RF 50mm F1.2 L USM', price: '¥70/天', image: 'public/Canon/lens/RF 50mm F1.2 L USM/image.png' },
  { id: 36, name: '尼克尔 Z 50mm F1.8 S', price: '¥40/天', image: 'public/Nikon/lens/尼克尔 Z 50mm F1.8 S/image.png' },
  { id: 37, name: '适马 35mm F1.4 DG DN Art', price: '¥50/天', image: 'public/Sigma/lens/35mm F1.4 DG DN Art/image.png' },
  { id: 38, name: '腾龙 17-28mm F2.8 Di III RXD', price: '¥40/天', image: 'public/Tamron/lens/17-28mm F2.8 Di III RXD/image.png' },
  { id: 39, name: '索尼 FE 100-400mm F4.5-5.6 GM OSS', price: '¥100/天', image: 'public/Sony/lens/FE 100-400mm F4.5-5.6 GM OSS/image.png' },
  { id: 40, name: '佳能 RF 100-500mm F4.5-7.1 L IS USM', price: '¥90/天', image: 'public/Canon/lens/RF 100-500mm F4.5-7.1 L IS USM/image.png' },
  { id: 41, name: '尼克尔 Z 105mm F2.8 VR S 微距', price: '¥60/天', image: 'public/Nikon/lens/尼克尔 Z 105mm F2.8 VR S 微距/image.png' },
  { id: 42, name: '适马 100-400mm F5-6.3 DG DN OS', price: '¥70/天', image: 'public/Sigma/lens/100-400mm F5-6.3 DG DN OS/image.png' },
]);

// 租赁 - 运动相机
const rentalYundongXiangjiProducts = ref([
  { id: 43, name: 'GoPro HERO12 Black', price: '¥50/天', image: 'public/GoPro/HERO Black/HERO12 Black/image.png' },
  { id: 44, name: 'DJI Osmo Action 4', price: '¥40/天', image: 'public/Dji/Action/Osmo Action 4/image.png' },
  { id: 45, name: 'GoPro HERO11 Black', price: '¥45/天', image: 'public/GoPro/HERO Black/HERO11 Black/image.png' },
  { id: 46, name: 'Insta360 X4 全景相机', price: '¥60/天', image: 'public/Insta360/X/X4/image.png' },
  { id: 47, name: 'GoPro HERO10 Black', price: '¥40/天', image: 'public/GoPro/HERO Black/HERO10 Black/image.png' },
  { id: 48, name: 'DJI Osmo Action 3', price: '¥35/天', image: 'public/Dji/Action/Osmo Action 3/image.png' },
  { id: 49, name: 'Insta360 GO 3S 拇指相机', price: '¥50/天', image: 'public/Insta360/GO/GO 3S/image.png' },
  { id: 50, name: 'GoPro MAX 全景相机', price: '¥55/天', image: 'public/GoPro/MAX 360/MAX/image.png' },
  { id: 51, name: 'DJI Osmo Action 2', price: '¥40/天', image: 'public/Dji/Action/Osmo Action 2/image.png' },
  { id: 52, name: 'AKASO V50X 4K运动相机', price: '¥25/天', image: 'public/AKASO/V50X/image.png' },
  { id: 53, name: 'Insta360 Ace Pro 2 全景相机', price: '¥35/天', image: 'public/Insta360/Ace Pro/Ace Pro 2/image.png' },
  { id: 54, name: 'DJI Pocket 2 口袋相机', price: '¥40/天', image: 'public/Dji/Pocket/Pocket 2/image.png' },
  { id: 55, name: 'GoPro HERO9 Black', price: '¥35/天', image: 'public/GoPro/HERO Black/HERO9 Black/image.jpg' },
  { id: 56, name: 'Insta360 X5 全景相机', price: '¥50/天', image: 'public/Insta360/X/X5/image.png' },
]);

// 租赁 - 无人机
const rentalWurenjiProducts = ref([
  { id: 57, name: 'DJI Mavic 3 Pro', price: '¥180/天', image: 'public/Dji/Drone/Mavic/Mavic 3 Pro/image.png' },
  { id: 58, name: 'DJI Air 3', price: '¥100/天', image: 'public/Dji/Drone/Air/Air 3/image.png' },
  { id: 59, name: 'DJI Mini 3', price: '¥60/天', image: 'public/Dji/Drone/Mini/Mini 3/image.png' },
  { id: 60, name: 'DJI Mavic 3 Pro', price: '¥130/天', image: 'public/Dji/Drone/Mavic/Mavic 3 Pro/image.png' },
  { id: 61, name: 'DJI Mini 4 Pro', price: '¥70/天', image: 'public/Dji/Drone/Mini/Mini 4 Pro/image.png' },
  { id: 62, name: 'DJI Mini 4K', price: '¥80/天', image: 'public/Dji/Drone/Mini/Mini 4K/image.png' },
  { id: 63, name: 'DJI Avata 2', price: '¥120/天', image: 'public/Dji/Drone/Avata/Avata2/image.png' },
  { id: 64, name: 'Autel EVO Lite', price: '¥90/天', image: 'public/Autel/EVO Lite/image.png' },
  { id: 65, name: 'DJI Neo2', price: '¥90/天', image: 'public/Dji/Drone/Neo/Neo2/image.png' },
  { id: 66, name: 'Parrot ANAFI USA GOV', price: '¥150/天', image: 'public/Parrot/ANAFI USA GOV/image.png' },
  { id: 67, name: 'DJI Mini 2 SE', price: '¥40/天', image: 'public/Dji/Drone/Mini/Mini 2 SE/image.png' },
  { id: 68, name: 'Autel EVO 2', price: '¥50/天', image: 'public/Autel/EVO 2/image.png' },
  { id: 69, name: 'DJI Inspire 3', price: '¥500/天', image: 'public/Dji/Drone/Inspire/Inspire 3/image.png' },
  { id: 70, name: 'Skydio X10D', price: '¥150/天', image: 'public/Skydio/X10D/image.png' },
]);

const goShop = () => {
  router.push('/shop')
}
// 租赁 - 前往租赁
const goRent = () => {
  router.push('/rent')
}
// 二手交易 - 前往二手交易
const goSecondHand = () => {
  router.push('/second-hand')
}



const handleClick = (tab: TabsPaneContext) => {
  console.log(tab)
}
</script>

<style scoped>
/* 轮播图容器样式 */
.carousel-image-container {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f0f0;
}

.carousel-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 8px;
}
/* 标题 */
.section-title {
  background: rgba(25, 137, 250, 0.05);
  padding: 10px 20px;
  border-radius: 25px;
}
.section-title {
  animation: fadeInUp 0.6s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 1;
    transform: translateX(-50%) translateY(20px);
  }
  to {
    opacity: 0;
    transform: translateX(-50%) translateY(0);
  }
}


/* 选项卡(标签页)内容样式 */
.tabs-container {
  background-image: url('/白蓝.jpg');
  width: 90%;
  margin-left: 5%;
  margin-top: 20px;
  overflow: hidden; /* 清除内部浮动，避免容器高度塌陷 */
  padding: 10px 0; /* 增加上下内边距，优化整体间距 */
}

/* 前往商城按钮：调整位置，避免挤压标签页 */
.tabs-container .el-button {
  float: right;
  margin-bottom: 15px; /* 按钮与下方标签页的间距，确保垂直分离 */
}
.demo-tabs > .el-tabs__content {
  padding: 40px;
  color: #6b778c;
  font-size: 80px;
  font-weight: 800;
}

/* 新增：调整选项卡标题样式 */
/* 1. 统一标签标题的布局和间距 */
.tab-label {
  display: flex;
  align-items: center;
  gap: 8px; /* 图标与文字的间距（可调整） */
  padding: 8px 0; /* 标签内上下 padding，增加点击区域 */
}

/* 2. 调大标签文字大小 */
.tab-label span {
  font-size: 18px; /* 文字大小（可调整） */
  font-weight: 500; /* 可选：增加文字粗细 */
}

/* 3. 清除图标内联的过大 padding，统一间距 */
.tab-label img {
  padding: 0 !important; /* 覆盖内联样式的大 padding */
  margin: 0; /* 确保无额外边距 */
}

/* 4. 调整标签页之间的间隔 */
:deep(.el-tabs__item) {
  margin: 0 15px; /* 标签页左右间隔（可调整） */
}

/* 标签页容器 */
.tabs-container {
  margin-top: 20px;
  padding: 0 20px;
}

/* 标签页样式 */
:deep(.el-tabs__nav) {
  background-color: #f5f7fa;
  padding: 10px 10px 0;
  border-radius: 8px 8px 0 0;
  width: 100%; /* 确保导航栏宽度充满容器 */
}

:deep(.el-tabs__item) {
  font-size: 16px;
  font-weight: 500;
  padding: 12px 24px;
  margin-right: 10px;
  border-radius: 8px 8px 0 0;
}

:deep(.el-tabs__item.is-active) {
  background-color: #fff;
  color: #1989fa;
  border-bottom: none;
}

:deep(.el-tabs__content) {
  background-color: #fff;
  padding: 20px;
  border-radius: 0 8px 8px 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

/* 商品容器 */
.products-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
  width: 100%; /* 明确宽度，避免继承问题 */
}

/* 商品项样式 */
.product-item {
  background-color: #fff;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s ease;
  cursor: pointer;
}

.product-item:hover {
  box-shadow: 0 4px 12px 0 rgba(0, 0, 0, 0.15);
  transform: translateY(-5px);
}

/* 商品图片 */
.product-image {
  width: 100%;
  height: 150px;
  overflow: hidden;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.product-item:hover .product-image img {
  transform: scale(1.1);
}

/* 商品信息 */
.product-info {
  padding: 12px;
}

.product-name {
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 8px;
  color: #303133;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.product-price {
  font-size: 16px;
  font-weight: 600;
  color: #f56c6c;
}

@media (max-width: 992px) {
  .carousel-container {
    margin-top: 0;
  }

  .el-carousel {
    height: 250px !important;
  }

  .el-carousel__item--card {
    height: 200px !important;
  }

  .carousel-image-container {
    padding: 10px;
  }

  .section-title {
    font-size: 18px;
    padding: 8px 15px;
  }

  .tabs-container {
    width: 95%;
    margin-left: 2.5%;
    padding: 0 10px;
  }

  :deep(.el-tabs__item) {
    font-size: 14px;
    padding: 8px 16px;
    margin-right: 8px;
  }

  :deep(.el-tabs__content) {
    padding: 15px;
  }

  .products-container {
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 15px;
  }

  .product-image {
    height: 120px;
  }

  .product-info {
    padding: 10px;
  }

  .product-name {
    font-size: 13px;
  }

  .product-price {
    font-size: 14px;
  }
}

@media (max-width: 576px) {
  .el-carousel {
    height: 180px !important;
  }

  .el-carousel__item--card {
    height: 140px !important;
  }

  .el-carousel--card .el-carousel__item--card.is-active {
    width: 70%;
    margin-left: 15%;
  }

  .section-title {
    font-size: 16px;
    padding: 6px 12px;
  }

  .title-icon {
    width: 24px !important;
  }

  .tabs-container {
    width: 100%;
    margin-left: 0;
    padding: 0 5px;
  }

  :deep(.el-tabs__item) {
    font-size: 12px;
    padding: 6px 12px;
    margin-right: 5px;
  }

  :deep(.el-tabs__content) {
    padding: 10px;
  }

  .products-container {
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
  }

  .product-image {
    height: 100px;
  }

  .product-info {
    padding: 8px;
  }

  .product-name {
    font-size: 12px;
    margin-bottom: 4px;
  }

  .product-price {
    font-size: 13px;
  }

  .tabs-container .el-button {
    padding: 8px 12px;
    font-size: 12px;
  }
}
</style>
