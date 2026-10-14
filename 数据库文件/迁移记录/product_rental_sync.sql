-- 解决product表和product_rental_detail表的数据一致性问题

-- 1. 创建触发器，当product表插入或更新租赁商品时，自动同步到product_rental_detail表
DELIMITER //

-- 删除已存在的触发器
DROP TRIGGER IF EXISTS after_product_insert;
DROP TRIGGER IF EXISTS after_product_update;

-- 插入时的触发器
CREATE TRIGGER after_product_insert
AFTER INSERT ON product
FOR EACH ROW
BEGIN
    -- 只处理租赁商品
    IF NEW.product_type = 3 THEN
        -- 为新租赁商品创建默认的product_rental_detail记录
        INSERT INTO product_rental_detail (
            product_id, deposit, max_rental_days, min_rental_days, 
            insurance_fee, late_fee_rate, damage_fee_rule, 
            pickup_methods, delivery_fee
        ) VALUES (
            NEW.product_id, 
            NEW.original_price * 0.1, -- 默认押金为原价的10%
            90, -- 默认最长租赁期限
            NEW.min_rental_days, -- 使用product表中的起租天数
            0.00, -- 默认保险费用
            0.05, -- 默认逾期违约金率
            '请联系客服了解详细赔偿规则', -- 默认损坏赔偿规则
            'delivery', -- 默认取货方式
            0.00 -- 默认配送费用
        );
    END IF;
END //

-- 更新时的触发器
CREATE TRIGGER after_product_update
AFTER UPDATE ON product
FOR EACH ROW
BEGIN
    -- 声明变量
    DECLARE detail_count INT;
    
    -- 只处理租赁商品
    IF NEW.product_type = 3 THEN
        -- 检查product_rental_detail表中是否存在对应记录
        SELECT COUNT(*) INTO detail_count FROM product_rental_detail WHERE product_id = NEW.product_id;
        
        IF detail_count > 0 THEN
            -- 更新已存在的记录
            UPDATE product_rental_detail
            SET 
                min_rental_days = NEW.min_rental_days,
                deposit = NEW.original_price * 0.1,
                updated_time = NOW()
            WHERE product_id = NEW.product_id;
        ELSE
            -- 创建新记录
            INSERT INTO product_rental_detail (
                product_id, deposit, max_rental_days, min_rental_days, 
                insurance_fee, late_fee_rate, damage_fee_rule, 
                pickup_methods, delivery_fee
            ) VALUES (
                NEW.product_id, 
                NEW.original_price * 0.1, -- 默认押金为原价的10%
                90, -- 默认最长租赁期限
                NEW.min_rental_days, -- 使用product表中的起租天数
                0.00, -- 默认保险费用
                0.05, -- 默认逾期违约金率
                '请联系客服了解详细赔偿规则', -- 默认损坏赔偿规则
                'delivery', -- 默认取货方式
                0.00 -- 默认配送费用
            );
        END IF;
    END IF;
END //

DELIMITER ;

-- 2. 为现有租赁商品创建product_rental_detail记录
INSERT INTO product_rental_detail (
    product_id, deposit, max_rental_days, min_rental_days, 
    insurance_fee, late_fee_rate, damage_fee_rule, 
    pickup_methods, delivery_fee
) SELECT 
    p.product_id, 
    p.original_price * 0.1, -- 默认押金为原价的10%
    90, -- 默认最长租赁期限
    p.min_rental_days, -- 使用product表中的起租天数
    0.00, -- 默认保险费用
    0.05, -- 默认逾期违约金率
    '请联系客服了解详细赔偿规则', -- 默认损坏赔偿规则
    'delivery', -- 默认取货方式
    0.00 -- 默认配送费用
FROM product p
WHERE p.product_type = 3 AND p.product_id NOT IN (SELECT product_id FROM product_rental_detail);

-- 3. 同步现有product_rental_detail记录中的min_rental_days与product表保持一致
UPDATE product_rental_detail prd
JOIN product p ON prd.product_id = p.product_id
SET prd.min_rental_days = p.min_rental_days
WHERE p.product_type = 3;

-- 4. 验证数据同步结果
SELECT 
    p.product_id, 
    p.model, 
    p.min_rental_days AS product_min_rental_days, 
    prd.min_rental_days AS rental_detail_min_rental_days,
    CASE WHEN p.min_rental_days = prd.min_rental_days THEN '一致' ELSE '不一致' END AS status
FROM product p
LEFT JOIN product_rental_detail prd ON p.product_id = prd.product_id
WHERE p.product_type = 3;
