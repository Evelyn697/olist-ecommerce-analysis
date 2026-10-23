-- ==========================================================
-- M1 
-- M1.1 GMV（所有订单+有效订单）、总订单数&有效订单数、客户数、客单价AOV（有效订单）、平均评分（有效订单）、晚到率
-- ==========================================================

use olist_analytics;

select
	sum(order_total_value) as gmv_all,
    count(*) as total_orders,
    count(distinct customer_unique_id) as customer_cnt
from v_orders_enriched;

select
	sum(order_total_value) as gmv_valid,
	count(*) as valid_orders,
	round(sum(order_total_value)/count(*), 2) as AOV,
    round(AVG(review_score_avg), 2) as avg_review_score,
    -- 物流迟到率：晚到的订单数/所有已送达的订单数。
    round(sum(is_late)/sum(is_delivered), 3) as late_rate
from v_orders_enriched
where is_valid_order = 1;

-- ==========================================================
-- M1.2 时间趋势——月度 GMV、订单量、客单价趋势
-- 目的：按月展示 GMV、订单量、客单价趋势
-- 依赖：v_orders_enriched
-- 预期：每月一行，2016-09 至 2018-08
-- ==========================================================
select
	purchase_year_month,
	round(sum(order_total_value), 2) as gmv,
    count(distinct order_id) as orders,
    round(sum(order_total_value)/count(distinct order_id), 2) as aov
from v_orders_enriched
where is_valid_order = 1
group by purchase_year_month
order by purchase_year_month asc;

-- ==========================================================
-- M1.3 地区分布——地区 GMV Top 10
-- ==========================================================
select
	customer_state,
    round(sum(order_total_value), 2) 							as gmv,
    count(distinct order_id) 									as orders,
    count(distinct customer_unique_id)  						as customers,
    round(sum(order_total_value) / count(distinct order_id), 2) as aov,
    round(
		sum(order_total_value) * 100 / (select sum(order_total_value) from v_orders_enriched where is_valid_order = 1),
        2
    )															as gmv_pct
from v_orders_enriched
where is_valid_order = 1
group by customer_state
ORDER BY gmv DESC
LIMIT 10;


-- ==========================================================
-- M1.4 品类分布————品类 GMV Top 10 & 品类订单量TOP 10
-- 目的：哪些品类贡献最多 GMV，以及哪些品类订单量最多（“销售额多” VS “卖的数量多”，比较是否一致）
-- 依赖：fct_order_items + fct_orders（用 fct_orders 过滤有效订单）
-- 口径：品类 GMV 用 SUM(price)，不含运费（运费无法按品类分摊）
-- ==========================================================
select
	i.product_category_english                                AS category,
    round(sum(i.price), 2)                                    AS gmv,
    count(distinct i.order_id)                                AS orders,
    round(sum(i.price) / count(distinct i.order_id), 2)       AS gmv_per_order
from fct_order_items i
join fct_orders o
on i.order_id = o.order_id
where o.is_valid_order = 1 AND i.product_category_english != 'unknown'   -- 排除未翻译品类
group by i.product_category_english
order by gmv desc
limit 10;

SELECT
    i.product_category_english                                AS category,
    COUNT(DISTINCT i.order_id)                                AS orders,
    ROUND(SUM(i.price), 2)                                    AS gmv,
    ROUND(SUM(i.price) / COUNT(DISTINCT i.order_id), 2)       AS gmv_per_order
FROM fct_order_items i
JOIN fct_orders o ON i.order_id = o.order_id
WHERE o.is_valid_order = 1 AND i.product_category_english != 'unknown'
GROUP BY i.product_category_english
ORDER BY orders DESC
LIMIT 10;

-- ==============================================================
-- M1.5 品类 × 地区交叉洞察
-- 目的：每个州的 Top 3 品类，看地域偏好
-- 依赖：fct_order_items + fct_orders + dim_customer_id_map
-- 用到 CTE 和窗口函数 ROW_NUMBER
-- ==============================================================
USE olist_analytics;

WITH state_category AS (
    -- 第一步：算每个（州, 品类）组合的 GMV 和订单数
    SELECT
        m.customer_state,
        i.product_category_english AS category,
        SUM(i.price)               AS gmv,
        COUNT(DISTINCT i.order_id) AS orders
    FROM fct_order_items i
    JOIN fct_orders o            ON i.order_id  = o.order_id
    JOIN dim_customer_id_map m   ON o.customer_id = m.customer_id
    WHERE o.is_valid_order = 1
      AND i.product_category_english != 'unknown'
    GROUP BY m.customer_state, i.product_category_english
),
state_total AS (
    -- 第二步：算每个州的总 GMV，用于计算占比
    SELECT
        customer_state,
        SUM(gmv) AS total_gmv,
        sum(orders) as total_orders
    FROM state_category
    GROUP BY customer_state
    HAVING total_orders >= 500      -- ← 过滤小样本州
),
ranked AS (
    -- 第三步：每个州内按 GMV 降序排名
    SELECT
        sc.customer_state,
        sc.category,
        sc.gmv,
        sc.orders,
        st.total_gmv,
        ROUND(sc.gmv / st.total_gmv * 100, 2) AS category_share_pct,
        -- ROW_NUMBER：每个州内按 gmv 降序编号
        ROW_NUMBER() OVER (
            PARTITION BY sc.customer_state
            ORDER BY sc.gmv DESC
        ) AS rn
    FROM state_category sc
    JOIN state_total st ON sc.customer_state = st.customer_state
)
-- 第四步：每个州只保留前 3 名
SELECT
    customer_state,
    category,
    ROUND(gmv, 2)              AS gmv,
    orders,
    category_share_pct
FROM ranked
WHERE rn <= 3
ORDER BY customer_state, rn;

create view v_orders_enriched_new as 
select
review_count, review_score_avg, order_total_value, freight_revenue, product_revenue, seller_count, product_count, 
item_count, is_valid_order, is_canceled, is_delivered, delay_days, is_late, estimated_days, delivery_days, 
purchase_hour, purchase_weekday, purchase_month, purchase_year, purchase_year_month, order_purchase_timestamp, 
order_status, customer_state, customer_city, customer_unique_id, customer_id, order_id,
concat('BR-', customer_state) as customer_state_br
from v_orders_enriched;
