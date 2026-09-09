<template>
  <div class="footer-container">
    <div class="footer-content">
      <!-- 关于我们 -->
      <div class="footer-section">
        <h3 class="section-title">关于我们</h3>
        <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;摄影器材交易系统是一个专注于摄影器材交易的平台，提供全新和二手器材的买卖、租赁等服务。</p>
      </div>

      <!-- 联系我们 -->
      <div class="footer-section">
        <h3 class="section-title">联系我们</h3>
        <ul class="contact-list">
          <li><i class="el-icon-location"></i> 地址：广东省广州市从化区摄影大道123号</li>
          <li><i class="el-icon-phone"></i> 电话：010-12345678</li>
          <li><i class="el-icon-message"></i> 邮箱：PETS@photo-trade.com</li>
        </ul>
      </div>

      <!-- 支持 -->
      <div class="footer-section">
        <h3 class="section-title">支持</h3>
        <ul class="link-list">
          <li><router-link to="/support/app">App下载</router-link></li>
          <li><router-link to="/support/help">帮助中心</router-link></li>
          <li><router-link to="/support/swap">以旧换新</router-link></li>
          <li><router-link to="/support/feedback">反馈意见</router-link></li>
        </ul>
      </div>

      <!-- 快速链接 -->
      <div class="footer-section">
        <h3 class="section-title">快速链接</h3>
        <ul class="link-list">
          <li><router-link to="/index">首页</router-link></li>
          <li><router-link to="/shop">器材商城</router-link></li>
          <li><router-link to="/second-hand">二手交易</router-link></li>
          <li><router-link to="/rent">租赁中心</router-link></li>
          <!-- <li><router-link to="/accessories">配件商城</router-link></li> -->
          <li><router-link to="/community">社区订阅</router-link></li>
        </ul>
      </div>

      <!-- 关注我们 -->
      <div class="footer-section">
        <h3 class="section-title">关注我们</h3>
        <div class="social-icons">
          <a href="#" class="social-icon"><img src="/wechat.png" alt="微信" width="24" height="24"></a>
          <a href="#" class="social-icon"><img src="/weibo.png" alt="微博" width="24" height="24"></a>
          <a href="#" class="social-icon"><img src="/qq.png" alt="QQ" width="24" height="24"></a>
          <a href="#" class="social-icon"><img src="/douyin.png" alt="抖音" width="24" height="24"></a>
          <a href="#" class="social-icon"><img src="/xiaohongshu.png" alt="小红书" width="24" height="24"></a>
        </div>
      </div>
    </div>

    <!-- 版权信息 -->
    <div class="footer-bottom">
      <p>© 2025 摄影器材交易系统. All Rights Reserved. 粤ICP备12345678号</p>
    </div>
  </div>
<!-- Backtop 回到顶部 -->
  <!-- <el-backtop :right="100" :bottom="100" style="height: 60px; width: 60px;">Top</el-backtop> -->
</template>

<script lang="ts" setup name="Footer"></script>

<style scoped>
.footer-container {
  background-color: #303133;
  color: #fff;
  padding: 40px 0 20px;
  margin-top: auto;
}

.footer-content {
  display: flex;
  justify-content: space-around;
  max-width: 1500px;
  margin: 0 auto 35px;
  flex-wrap: wrap;
  gap: 30px;
}

.footer-section {
  flex: 1;
  min-width: 200px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 15px;
  color: #fff;
}

.footer-section p {
  font-size: 14px;
  line-height: 1.6;
  color: #909399;
}

.contact-list, .link-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.contact-list li, .link-list li {
  font-size: 14px;
  margin-bottom: 10px;
  color: #909399;
  display: flex;
  align-items: center;
}

.contact-list i {
  margin-right: 8px;
  color: #409eff;
}

.link-list a {
  color: #909399;
  text-decoration: none;
  transition: color 0.3s;
}

.link-list a:hover {
  color: #409eff;
}

.social-icons {
  display: flex;
  gap: 15px;
}

.social-icon {
  width: 40px;
  height: 40px;
  background-color: rgb(255, 255, 255);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 20px;
  transition: all 0.3s;
  text-decoration: none;
}

.social-icon:hover {
  background-color: #409eff;
  transform: translateY(-3px);
}

.footer-bottom {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 20px;
  text-align: center;
}

.footer-bottom p {
  font-size: 12px;
  color: #87898d;
  margin: 0;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .footer-content {
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .footer-section {
    min-width: 250px;
  }

  .contact-list li {
    justify-content: center;
  }
}
</style>
