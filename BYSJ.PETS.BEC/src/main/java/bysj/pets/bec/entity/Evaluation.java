package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 评价实体类
 */
@Data
@TableName("evaluation")
public class Evaluation {

    /**
     * 评价唯一标识
     */
    @TableId(type = IdType.AUTO)
    private Long evalId;

    /**
     * 关联order.order_id，订单删除时同步删除评价
     */
    private Long orderId;

    /**
     * 关联product.product_id，商品下架不影响评价展示
     */
    private Long productId;

    /**
     * 关联user.user_id，评价归属用户
     */
    private Long userId;

    /**
     * 关联user.user_id，评价对应的商家
     */
    private Long sellerId;

    /**
     * 综合评分（1-5 星，1 星最差，5 星最好）
     */
    private Double score;

    /**
     * 器材质量评分（1-5 星，仅购买 / 租赁 / 二手场景）
     */
    private Double qualityScore;

    /**
     * 商家服务评分（1-5 星，所有场景）
     */
    private Double serviceScore;

    /**
     * 物流速度评分（1-5 星，仅购买 / 二手场景，自提为 5 星）
     */
    private Double logisticsScore;

    /**
     * 评价内容（≥10 字，禁止辱骂、虚假内容）
     */
    private String content;

    /**
     * 评价图片路径（JSON 数组，≤5 张）
     */
    private String imgUrls;

    /**
     * 评价状态：0 - 已删除，1 - 正常展示，2 - 违规隐藏（管理员操作）
     */
    private Byte evalStatus;

    /**
     * 商家回复内容
     */
    private String replyContent;

    /**
     * 商家回复时间
     */
    private LocalDateTime replyTime;

    /**
     * 评价提交时间
     */
    private LocalDateTime createTime;

    /**
     * 评价状态更新时间
     */
    private LocalDateTime updateTime;

    /**
     * 用户名（关联查询）
     */
    private String userName;

    /**
     * 商品名称（关联查询）
     */
    private String productName;
}
