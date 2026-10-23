use olist_raw;

-- 客户信息表
-- PK选择customer_id，因为customer_unique_id不唯一，同一客户多单会重复
create table if not exists customers
(
customer_id 				VARCHAR(32) NOT NULL primary key,
customer_unique_id 			VARCHAR(32) NOT NULL,
customer_zip_code_prefix 	VARCHAR(5),
customer_city 				VARCHAR(100),
customer_state 				VARCHAR(10)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 地区信息表
-- decimal(总长度，小数部分长度）
-- 【PK】这张表特殊。原始数据里，同一邮编前缀 geolocation_zip_code_prefix 可能出现多次，因为一个邮编区有多个经纬度点。所以：
-- geolocation_zip_code_prefix 单独不唯一，整张表没有天然主键
create table if not exists geolocation
(
geolocation_zip_code_prefix 	VARCHAR(5) not null,
geolocation_lat 				DECIMAL(15,12),
geolocation_lng 				DECIMAL(15,12),
geolocation_city 				VARCHAR(100),
geolocation_state 				VARCHAR(10),
KEY idx_zip (geolocation_zip_code_prefix)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 订单详细信息表
create table if not exists order_items
(
order_id 				VARCHAR(32) not null,
order_item_id 			int not null,
product_id 				VARCHAR(32),
seller_id 				VARCHAR(32),
shipping_limit_date 	DATETIME,
price 					DECIMAL(10,2),
freight_value 			DECIMAL(10,2),			-- 订单运费
KEY idx_product_id (product_id),		-- 
KEY idx_seller_id (seller_id),
primary key (order_id, order_item_id)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 订单付款数据表
create table if not exists order_payments
(
order_id 				VARCHAR(32) NOT NULL,
payment_sequential 		INT NOT NULL,
payment_type 			VARCHAR(20),
payment_installments 	INT,   			-- 客户选择的分期付款数量
payment_value 			DECIMAL(10,2),
PRIMARY KEY (order_id, payment_sequential)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 客户评价数据表
-- 需要确定主键是order_id还是review_id，还是复合主键。
-- 经后续步骤的观察，发现存在一个review_id对应>1个order_id的情况（3242cc306a9218d0377831e175d62fbf）；
-- 也可能存在有些订单有多条评价的情况（客户追平/系统bug）
-- 因此，需要先识别（诊断）
-- 更重要的：语义上，这条记录的身份是"评价"，不是"订单"。order_id是外键，指向它评价的订单。customers
create table if not exists order_reviews
(
review_id 				VARCHAR(32) NOT NULL,
order_id 				VARCHAR(32),
review_score            INT,
review_comment_title    TEXT,
review_comment_message  TEXT,
review_creation_date    DATETIME,
review_answer_timestamp DATETIME,
KEY idx_review_id (review_id),
KEY idx_order_id (order_id)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 订单交易数据表（多个时间戳）
create table if not exists orders
(
order_id 						VARCHAR(32) NOT NULL PRIMARY KEY,
customer_id						VARCHAR(32) NOT NULL,
order_status					VARCHAR(20),
order_purchase_timestamp        DATETIME,
order_approved_at               DATETIME,
order_delivered_carrier_date    DATETIME,
order_delivered_customer_date   DATETIME,
order_estimated_delivery_date   DATETIME,
KEY idx_customer_id (customer_id),
KEY idx_purchase_ts (order_purchase_timestamp)		-- ?
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 商品详细信息表
create table if not exists products
(
product_id						VARCHAR(32) NOT NULL PRIMARY KEY,
product_category_name       	VARCHAR(100),
product_name_lenght         	INT,
product_description_lenght  	INT,
product_photos_qty          	INT,
product_weight_g            	DECIMAL(10,2),
product_length_cm           	DECIMAL(10,2),
product_height_cm           	DECIMAL(10,2),
product_width_cm            	DECIMAL(10,2)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 卖家数据表
create table if not exists sellers
(
seller_id					VARCHAR(32) NOT NULL PRIMARY KEY,
seller_zip_code_prefix		VARCHAR(5) NOT NULL,
seller_city					VARCHAR(100),
seller_state            	VARCHAR(10)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 品类翻译表
create table if not exists product_category_name_translation
(
product_category_name         	VARCHAR(100) NOT NULL PRIMARY KEY,
product_category_name_english 	VARCHAR(100)
) engine=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
