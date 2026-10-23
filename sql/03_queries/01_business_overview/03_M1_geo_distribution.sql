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
