-- 08_create_v_orders_enriched.sql
-- 运行之后再运行A2.1_add_index.sql，添加索引，然后再查看视图，这样能加速，避免数据量过大导致与mysql服务器断连。
-- 分析主视图，Superset 的大部分图表都基于它。

-- ============================================================
-- 脚本目的：构建订单宽表视图 v_orders_enriched
--
-- 类型：VIEW（视图），不是 TABLE
--   - 视图不存数据，只保存查询逻辑
--   - 每次查询视图时实时执行底层 SELECT
--   - 好处：底层表更新后，视图自动反映最新数据
--
-- 粒度：一行 = 一个订单
-- 用途：Superset 经营总览、用户分析、评价物流分析的主数据源
-- ============================================================

use olist_analytics;

create or replace view v_orders_enriched as
select
	-- ===== 订单ID和客户信息 =====
    o.order_id,
    o.customer_id,
    m.customer_unique_id,
    m.customer_city,
    m.customer_state,
    
    -- ===== 订单属性 =====
    o.order_status,
    o.order_purchase_timestamp,
    o.purchase_year_month,
    o.purchase_year,
    o.purchase_month,
    o.purchase_weekday,
    o.purchase_hour,
    
    -- ===== 履约字段 =====
    o.delivery_days,
    o.estimated_days,
    o.delay_days,
    o.is_late,
    o.is_delivered,
    o.is_canceled,
    o.is_valid_order,
    
    -- ===== 金额字段（COALESCE 处理 775 个无 items 的订单）=====
    COALESCE(s.item_count, 0)        AS item_count,
    COALESCE(s.product_count, 0)     AS product_count,
    COALESCE(s.seller_count, 0)      AS seller_count,
    COALESCE(s.product_revenue, 0)   AS product_revenue,
    COALESCE(s.freight_revenue, 0)   AS freight_revenue,
    COALESCE(s.order_total_value, 0) AS order_total_value,
    
    -- ===== 评价字段（COALESCE 处理无评价的订单）=====
    r.review_score_avg,
    r.review_count
from fct_orders o
-- 关联客户唯一ID
left join dim_customer_id_map m on o.customer_id = m.customer_id
-- 关联订单金额汇总
left join fct_order_summary s on o.order_id = s.order_id
-- 关联评价聚合
left join fct_order_reviews r on o.order_id = r.order_id;

