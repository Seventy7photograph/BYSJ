-- 创建触发器，当product表插入新记录时，自动在inventory表中创建对应记录
DELIMITER //

-- 删除已存在的触发器
DROP TRIGGER IF EXISTS after_product_insert;

CREATE TRIGGER after_product_insert
AFTER INSERT ON product
FOR EACH ROW
BEGIN
    -- 为新商品创建默认SKU（如果不存在）
    INSERT INTO sku (product_id, sku_attribute, sku_value, price, stock, min_stock, sales)
    VALUES (NEW.product_id, '默认', '默认', NEW.price, NEW.stock, NEW.min_stock, 0)
    ON DUPLICATE KEY UPDATE stock = NEW.stock, min_stock = NEW.min_stock;
    
    -- 获取刚插入的SKU ID
    SET @sku_id = LAST_INSERT_ID();
    
    -- 为新商品创建库存记录
    INSERT INTO inventory (product_id, product_name, product_type, sku_id, sku_attribute, sku_value, current_stock, min_stock, sales)
    VALUES (
        NEW.product_id,
        CONCAT((SELECT brand_name FROM brand WHERE brand_id = NEW.brand), ' ', NEW.model),
        CASE 
            WHEN NEW.product_type = 1 THEN 'new'
            WHEN NEW.product_type = 2 THEN 'used'
            WHEN NEW.product_type = 3 THEN 'rental'
            ELSE 'new'
        END,
        @sku_id,
        '默认',
        '默认',
        NEW.stock,
        NEW.min_stock,
        0
    );
END //
DELIMITER ;

-- 为没有SKU的商品创建SKU记录
INSERT INTO sku (product_id, sku_attribute, sku_value, price, stock, min_stock, sales)
SELECT 
    p.product_id,
    '默认' AS sku_attribute,
    '默认' AS sku_value,
    p.price,
    p.stock,
    p.min_stock,
    0 AS sales
FROM product p
WHERE p.product_id NOT IN (SELECT product_id FROM sku);

-- 为现有商品创建库存记录的SQL语句
INSERT INTO inventory (product_id, product_name, product_type, sku_id, sku_attribute, sku_value, current_stock, min_stock, sales)
SELECT 
    p.product_id,
    CONCAT(b.brand_name, ' ', p.model) AS product_name,
    CASE 
        WHEN p.product_type = 1 THEN 'new'
        WHEN p.product_type = 2 THEN 'used'
        WHEN p.product_type = 3 THEN 'rental'
        ELSE 'new'
    END AS product_type,
    (SELECT sku_id FROM sku WHERE product_id = p.product_id LIMIT 1) AS sku_id,
    '默认' AS sku_attribute,
    '默认' AS sku_value,
    p.stock AS current_stock,
    p.min_stock,
    0 AS sales
FROM product p
JOIN brand b ON p.brand = b.brand_id
WHERE p.product_id NOT IN (SELECT product_id FROM inventory);