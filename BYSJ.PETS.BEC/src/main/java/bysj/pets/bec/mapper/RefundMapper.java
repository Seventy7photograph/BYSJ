package bysj.pets.bec.mapper;

import bysj.pets.bec.entity.Refund;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

public interface RefundMapper extends BaseMapper<Refund> {
    Refund selectByOrderId(Long orderId);
}