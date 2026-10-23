use olist_analytics;

create table if not exists dim_product_category_translation
(
product_category_name				VARCHAR(100) NOT NULL PRIMARY KEY,
product_category_name_english		VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 先把原始数据集 Olist_raw 中有的 71 行记录 copy 过来。
insert into olist_analytics.product_category_translation
SELECT product_category_name, product_category_name_english
FROM olist_raw.product_category_name_translation;

-- 再添加原始数据集中缺失的翻译信息。
insert into olist_analytics.product_category_translation 
values
	('pc_gamer', 'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_preparers');
