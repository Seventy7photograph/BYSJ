package bysj.pets.bec.dto;

import lombok.Data;
import java.util.List;

@Data
public class ProductImageDTO {
    private Long productId; // 商品ID
    private String imageType; // 图片类型（main/detail）
    private List<Long> imageIds; // 图片ID列表
}
