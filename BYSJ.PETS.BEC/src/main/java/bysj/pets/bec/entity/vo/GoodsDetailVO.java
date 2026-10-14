package bysj.pets.bec.entity.vo;

import com.baomidou.mybatisplus.annotation.TableField;
import lombok.Data;
import java.math.BigDecimal;
import java.sql.Blob;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.List;

@Data
public class GoodsDetailVO {
    private Long id;
    private String name;
    private String brandName;
    private Integer categoryId;
    private BigDecimal price;
    private BigDecimal originalPrice;
    private Integer stock;
    private String imageUrl;
    private String description;

    private Map<String, String> specifications;
    private List<String> imageUrls;

    // 二手商品特有字段
    private String qualityReport; // 第三方质检报告路径
    private String usedTime; // 使用时长
    private String defectDesc; // 瑕疵描述
    private List<String> defectImg; // 瑕疵图片路径
    private Integer sellerType; // 卖家类型：1-个人闲置，2-企业商家
    private Integer negotiateStatus; // 议价状态：0-未议价，1-议价中，2-议价达成，3-议价失败
    private BigDecimal finalPrice; // 议价最终价格
    private Integer condition; // 商品成色
    private Long sellerId; // 卖家ID
    private String sellerName; // 卖家昵称
    // 新增字段
    private Map<String, String> parameters; // 专业参数
    private String warrantyInfo; // 保修信息
    private String secondHandDescription; // 二手商品描述
    private List<String> secondHandImgUrls; // 二手商品实拍图
    
    // 租赁商品特有字段
    private Integer minRentalDays; // 起租天数
    private Integer maxRentalDays; // 最大租赁天数
    private BigDecimal deposit; // 押金
    private BigDecimal insuranceFee; // 保险费用
    private BigDecimal lateFeeRate; // 逾期违约金率
    private String damageFeeRule; // 损坏赔偿规则
    private String pickupMethods; // 取货方式
    private BigDecimal deliveryFee; // 配送费用

    // 计算属性：是否可以议价
    public boolean isNegotiable() {
        return negotiateStatus == null || negotiateStatus == 0;
    }

    // 计算属性：显示价格
    public BigDecimal getDisplayPrice() {
        return finalPrice != null ? finalPrice : price;
    }
}
