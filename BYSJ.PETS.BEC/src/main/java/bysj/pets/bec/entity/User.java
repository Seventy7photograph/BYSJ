package bysj.pets.bec.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * <p>
 * 用途：存储所有用户（个人 / 企业 / 管理员）的基础身份信息，是系统权限与业务操作的核心关联表。	备注：个人用户未填写id_card或企业用户未填写business_license时，status为 2，仅可浏览商品，不可下单 / 发布商品。
 * </p>
 *
 * @author zsj
 * @since 2025-11-30
 */

@ToString
@Data
@Accessors(chain = true)
public class User implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 用户唯一标识（自增 ID）
     */
    @TableId(value = "user_id", type = IdType.AUTO)
    private Long userId;

    /**
     * 登录账号（个人为手机号 / 邮箱，企业为统一信用代码）
     */
    private String username;

    /**
     * 随机昵称（用户_+6位随机数）
     */
    private String nickname;

    /**
     * 加密存储的密码（MD5 + 盐值）
     */
    private String password;

    /**
     * 用户类型：1 - 个人用户，2 - 企业用户（器材商家），3 - 管理员，4 -超级管理员
     */
    @TableField("user_type")
    private Byte userType;

    /**
     * 个人用户真实姓名（实名认证用）
     */
    @TableField("real_name")
    private String realName;

    /**
     * 个人用户身份证号（加密存储，仅管理员可查看）
     */
    @TableField("id_card")
    private String idCard;

    /**
     * 企业营业执照图片路径（存储于 MinIO / 本地）
     */
    @TableField("business_license")
    private String businessLicense;

    /**
     * 法人身份证正面图片路径（存储于 MinIO / 本地）
     */
    @TableField("legal_id_front")
    private String legalIdFront;

    /**
     * 法人身份证反面图片路径（存储于 MinIO / 本地）
     */
    @TableField("legal_id_back")
    private String legalIdBack;

    /**
     * 联系电话（用于验证码登录、订单通知）
     */
    @TableField("phone")
    private String phone;

    /**
     * 邮箱（用于密码重置、系统通知）
     */
    @TableField("email")
    private String email;

    /**
     * 性别：0 - 未知，1 - 男，2 - 女
     */
    private Byte gender;

    /**
     * 账号状态：0 - 禁用（违规），1 - 正常，2 - 待审核（企业 / 个人未认证）
     */
    private Byte status;

    /**
     * 账号创建时间
     */
    @TableField(value = "create_time", fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /**
     * 账号信息更新时间
     */
    @TableField(value = "update_time", fill = FieldFill.UPDATE)
    private LocalDateTime updateTime;

    /**
     * 用户头像路径（存储于本地public/head目录）
     */
    @TableField("avatar_url")
    private String avatarUrl;
    
    /**
     * 店铺名称
     */
    @TableField("shop_name")
    private String shopName;
    
    /**
     * 企业类型：personal-个人店铺，enterprise-企业店铺
     */
    @TableField("business_type")
    private String businessType;
    
    /**
     * 店铺状态：0-关闭，1-正常，2-审核中
     */
    @TableField("shop_status")
    private Integer shopStatus;
    
    /**
     * 开店时间
     */
    @TableField("open_time")
    private LocalDateTime openTime;
    
    /**
     * 店铺地址
     */
    @TableField("shop_address")
    private String shopAddress;
    
    /**
     * 店铺简介
     */
    @TableField("shop_description")
    private String shopDescription;
    
    /**
     * 是否有店铺：0-无，1-有
     */
    @TableField("has_shop")
    private Byte hasShop;
}
