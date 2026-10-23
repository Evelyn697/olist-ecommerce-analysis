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