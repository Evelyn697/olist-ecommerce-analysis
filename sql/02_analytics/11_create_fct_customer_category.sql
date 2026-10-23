-- ================================================================
-- 中间表构建 | 输出：表格fct_customer_category
-- 目的：构建“用户分层 × 品类”的聚合表，分析分析不同客户分层对品类的偏好差异。其中，用户已按RFM理论分为5个群体。

-- 粒度：一行 = (segment, category) 组合
-- 口径：有效订单 & 品类已知（去除unknown）
-- JOIN 链：
--   fct_order_items → fct_orders → dim_customer_id_map → fct_customer_rfm
-- =================================================================

use olist_analytics;

DROP TABLE IF EXISTS fct_customer_category;

create table fct_customer_category as
select
	r.segment,
    i.product_category_english as category,
    -- 该分层中买过该品类的客户数（去重）
    count(distinct r.customer_unique_id) as customer_cnt,
    -- 该分层中买过该品类的订单数（去重）
    count(distinct i.order_id) as order_cnt,
    -- 该分层在该品类上的总 GMV（不含运费）
    round(sum(i.price), 2) as gmv
from fct_order_items i
join fct_orders o            on i.order_id    = o.order_id
join dim_customer_id_map m	 on o.customer_id = m.customer_id
join fct_customer_rfm r		 on m.customer_unique_id = r.customer_unique_id
where o.is_valid_order = 1 and i.product_category_english != 'unknown'
group by r.segment, i.product_category_english;

-- 创建索引
create index idx_segment  on fct_customer_category (segment);
create index idx_category on fct_customer_category (category);

-- 验证
SELECT COUNT(*) FROM fct_customer_category;                    -- 应约 5 × 71 = 355 -> 实际：344（要去除unknown的）
SELECT segment, COUNT(*) FROM fct_customer_category GROUP BY segment;
SELECT ROUND(SUM(gmv), 2) FROM fct_customer_category;          -- 13315828.19
