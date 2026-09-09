package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.Brand;
import bysj.pets.bec.mapper.BrandMapper;
import bysj.pets.bec.service.BrandService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class BrandServiceImpl extends ServiceImpl<BrandMapper, Brand> implements BrandService {
}
