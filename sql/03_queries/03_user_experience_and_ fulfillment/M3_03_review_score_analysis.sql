-- ==============================================================
-- M3 用户评价与物流分析 | Q3 评分分析（review score analysis）
-- 计算指标：
-- （1）平均评分、1星占比、5星占比    big number
-- （2）评分分布  					  bar chart
-- （3）评分月度趋势				  line chart（每月的平均评分）
-- （4）各州平均评分				  country map
-- 数据来源：v_orders_enriched_new
-- 统计口径：‘2017-01’至‘2018-08’期间的有效订单，且包含未送达订单。(*)需要筛选出评分不为NULL的
-- 			 时间上和之前的分析一致，但由于评价是客户的主观打分，
-- 			 在看整体评分时，不能忽略那些因为“迟迟未送达”或“被取消”而给了 1 星差评的订单。这恰恰反映了平台的真实服务体验。
-- ==============================================================

-- （1）平均评分、1星占比、5星占比    big number     - > 平均评分：4.12，1星占比10.67%，5星占比58.35%
use olist_analytics;

select
	round(avg(review_score_avg), 2) as avg_review_score,
    round(sum(case when review_score_avg = 1 then 1 else 0 end) * 100 / count(*), 2) as pct_1star,
    round(sum(case when review_score_avg = 5 then 1 else 0 end) * 100 / count(*), 2) as pct_5star
from v_orders_enriched_new
where is_valid_order = 1 
		and review_score_avg is not null
		and purchase_year_month between '2017-01' and '2018-08';

-- （2）评分分布
-- 结果：5星 58.35%，4星
use olist_analytics;

select
	floor(review_score_avg) as score_bucket,
	count(*) as order_cnt,
    round(count(*) * 100 / sum(count(*)) over(), 2) as pct
from v_orders_enriched_new
where is_valid_order = 1 
		and review_score_avg is not null
		and purchase_year_month between '2017-01' and '2018-08'
group by floor(review_score_avg)
order by score_bucket desc;

-- （3）评分月度趋势
use olist_analytics;

select
	purchase_year_month,
    round(avg(review_score_avg), 3) as avg_score
from v_orders_enriched_new
where is_valid_order = 1 
		and review_score_avg is not null
		and purchase_year_month between '2017-01' and '2018-08'
group by purchase_year_month
order by purchase_year_month;

-- （4）各州平均评分
use olist_analytics;

select
	max(customer_state) as customer_state,  -- 一定要加一个聚合函数
	customer_state_br,
    round(avg(review_score_avg), 3) as avg_score,
    count(*) as order_cnt
from v_orders_enriched_new
where is_valid_order = 1 
		and review_score_avg is not null
		and purchase_year_month between '2017-01' and '2018-08'
group by customer_state_br
order by customer_state_br;