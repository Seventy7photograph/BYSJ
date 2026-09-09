package bysj.pets.bec.service;

import bysj.pets.bec.entity.Product;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 用途：存储摄影器材的核心基础信息，区分全新 / 二手 / 租赁三种商品类型，是商品管理与交易的核心表。	备注：全新器材需关联品牌授权证明（存储于product_detail），否则audit_status驳回；库存低于 5 件时，系统自动提醒seller_id对应的商家补货。 服务类
 * </p>
 *
 * @author zsj
 * @since 2025-12-22
 */
public interface IProductService extends IService<Product> {

}
