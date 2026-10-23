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