-- ================================================================
-- M2 Q1 | 各月份的用户规模，用户月增长数、月增长率；
-- 统计口径：月度活跃用户（当月下单过的用户），包括当月新客户和复购客户。
-- 由于 olist 复购率只有3.12%，活跃用户数和新增用户数应该很接近，因此这里只分析月活跃用户。
-- based on view: v_orders_enriched, cols:Purchase_year_month, customer_unique_id

-- 窗口函数 LAG(列, 偏移量) OVER (ORDER BY ...) 的作用是：取"上一行"的值。
-- 由于同一层不能引用自己的别名，因此需要使用CTE（共用表表达式）分两层，第一层计算用户数，第二层计算增长数。
-- ================================================================

use olist_analytics;

with monthly_uses as(
	select purchase_year_month,
		   count(distinct customer_unique_id) as user_cnt
	from v_orders_enriched
    where is_valid_order = 1 and purchase_year_month between '2017-01' and '2018-08'
    group by purchase_year_month
	order by purchase_year_month
)
select
	purchase_year_month,
    user_cnt,
    -- 上月用户数
    lag(user_cnt) over (order by purchase_year_month) as prev_user_cnt,
    -- 净增长 = 本月 - 上月
    user_cnt - lag(user_cnt) over (order by purchase_year_month) as user_growth,
    -- 增长率 = (本月 - 上月) / 上月 * 100
    -- ROUND 保留两位小数
    -- 第一行因为 prev 是 NULL，整个表达式结果是 NULL，这是合理的
    round((user_cnt - lag(user_cnt) over (order by purchase_year_month)) * 100/lag(user_cnt) over (order by purchase_year_month), 
			2) as growth_rate_pct
from monthly_uses
order by purchase_year_month;
