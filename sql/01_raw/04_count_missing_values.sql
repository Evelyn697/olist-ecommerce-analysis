-- 检查NULL率和重复率；
use olist_raw;

-- 订单详情表，统计总行数和各列缺失数据量。
-- 总行数 112650，其他各列均没有缺失。复合主键：(order_id, order_item_id)
select
COUNT(*) AS total,
count(distinct order_id) as count_order_id,		-- 98666(775 个订单没有 order_items 记录)
sum(product_id is null) as oi_no_product_id,
sum(seller_id is null) as oi_no_seller_id,
sum(order_item_id is null) as oi_no_order_item_id,
sum(shipping_limit_date is null) as oi_no_shipping_limit_date,
sum(price is null) as oi_no_price,
sum(freight_value is null) as oi_no_freight_value
from order_items;

-- order_payments 订单付款详情表 统计各列缺失情况和异常值（原则：payment_sequential=0代表异常）
-- 结论：总行数103886，其他各列均没有缺失，但有9行的payment_value=0，涉及8个order_id。
-- 该表格以(order_id, payment_sequential)作为复合主键。
select
count(*) as total,
count(distinct order_id) as count_order_id,		-- 99440
sum(payment_sequential is null) as op_no_payment_sequential,
sum(payment_sequential=0) as op_obnormal_payment_info,
sum(payment_type is null) as op_no_payment_type,
sum(payment_installments is null) as op_no_payment_installments,
sum(payment_value is null) as op_on_payment_value,
sum(payment_value=0) as op_obnormal_payment_value
from order_payments;

-- order_reviews 订单评价数据
-- 原始数据共99224行，其中各行的review_id, order_id, review_score，review_creation_date，review_answer_timestamp均没有缺失，重复情况见python脚本/scripts/01_etl/check_review_dupes.py分析
-- 87656行缺少评论表提，58247行缺少评论内容。
select
count(*) as total,
sum(review_id is null) as or_no_review_id,
sum(order_id is null) as or_no_order_id,
sum(review_score is null) as or_no_review_score,
sum(review_comment_title is null) as or_no_review_comment_title,
sum(review_comment_message is null) as or_no_review_comment_message,
sum(review_creation_date is null) as or_no_review_creation_date,
sum(review_answer_timestamp is null) as or_no_review_answer_timestamp
from order_reviews;

-- orders 订单配送信息表
-- 原始数据共99441行，订单ID没有重复。所有行都有order_status和purchase_timestamp信息，共160行没有付款审批时刻信息，1783行没有发布给物流的时刻信息，2965行没有实际交付日期，所有订单均有预期交付日期。
-- 没有付款审批时刻信息，是否代表订单无效？625个状态为canceled的订单是否要删除？
-- 筛选出160个没有付款审批时刻的行，其status对应有canceled(141行)，created(5行)，delivered(14行)。
select
count(*) as total,
count(distinct order_id) as count_order_id,
sum(order_status is null) as no_order_status,
sum(order_purchase_timestamp is null) as no_order_purchase_timestamp,
sum(order_approved_at is null) as no_order_approved_at,
sum(order_delivered_carrier_date is null) as no_order_delivered_carrier_date,
sum(order_delivered_customer_date is null) as no_order_delivered_customer_date,
sum(order_estimated_delivery_date is null) as no_order_estimated_delivery_date
from orders;

-- products 产品详情表
-- 原始数据共32951行，产品ID没有重复。其中，610行没有产品品类信息和产品照片数量信息，2行没有产品尺寸/重量信息。
select
count(*) as total,
count(distinct product_id) as count_product_id,
sum(product_category_name is null) as no_product_category_name,
sum(product_name_lenght is null) as no_product_name_lenght,
sum(product_description_lenght is null) as no_product_description_lenght,
sum(product_photos_qty is null) as no_product_photos_qty,
sum(product_weight_g is null) as no_product_weight_g,
sum(product_length_cm is null) as no_product_length_cm,
sum(product_height_cm is null) as no_product_height_cm,
sum(product_width_cm is null) as no_product_width_cm
from products;

-- product_category_name_translation 产品名称翻译表
-- 共71行
select
count(*) as total,
count(distinct product_category_name) as count_distinct_product_category_name,
count(distinct product_category_name_english) as count_distinct_product_category_name_english,
sum(product_category_name_english is null) as no_product_category_name_english
from product_category_name_translation;

-- 提取14个delivered 却缺审批时间的异常数据：
SELECT 
*
FROM orders
WHERE order_approved_at IS NULL AND order_status = 'delivered'
LIMIT 20;

-- 从 orders 表中获取订单状态分布
select
	order_status,
	COUNT(*) AS cnt,
    round(count(*) * 100/ (select count(*) from orders), 2) as pct
from orders
group by order_status
order by cnt desc;

-- 计算产品品类翻译覆盖率;
-- total_cats=73，translated_cats=71，说明有2种品类没有对应的翻译信息。
select
	COUNT(DISTINCT p.product_category_name) AS total_cats,
	COUNT(DISTINCT CASE WHEN t.product_category_name_english IS NOT NULL
						THEN p.product_category_name END) AS translated_cats
from products p
left join product_category_name_translation t
on p.product_category_name = t.product_category_name;

-- 寻找没有翻译信息的产品品类名称；结果：pc_gamer, portateis_cozinha_e_preparadores_de_alimentos
select
	distinct p.product_category_name as p_product_category_name,
    t.product_category_name as t_product_category_name
from products p
left join product_category_name_translation t
on p.product_category_name = t.product_category_name
order by p_product_category_name asc;

-- 方法2：
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;
  
