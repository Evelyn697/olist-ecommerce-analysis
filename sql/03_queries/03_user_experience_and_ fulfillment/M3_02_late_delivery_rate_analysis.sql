-- ========================================================
-- M3 用户评价与物流分析 | Q2 延迟分析
-- （1）整体延迟率		（big number）
-- （2）延迟率月度趋势 （line chart）
-- （3）各州延迟率对比	（country map/bar chart）
-- （4）各品类延迟率	（table/bar chart）
-- 		需要生成中间表 fct_delivery_category，依赖 fct_orders（延迟情况）、fct_order_items（品类名称）
--      前序要求：执行代码 sql/02_analytics/12_create...
-- ========================================================

-- （1）计算整体延迟率  -> 结果：8.13%
-- 口径：分母是已送达订单（且为有效订单），日期范围：2017-01-01~2018-08-31
use olist_analytics;

select
	round(sum(case when is_late = 1 then 1 else 0 end)/sum(case when is_delivered = 1 then 1 else 0 end), 4) as late_delivery_rate
from fct_orders
where is_valid_order = 1 and is_delivered = 1 and purchase_year_month between '2017-01' and '2018-08';

-- （2）延迟率月度趋势
-- 口径：同上
use olist_analytics;

select
	purchase_year_month,
	round(sum(case when is_late = 1 then 1 else 0 end)/sum(case when is_delivered = 1 then 1 else 0 end), 4) as late_delivery_rate
from fct_orders
where is_valid_order = 1 and is_delivered = 1 and purchase_year_month between '2017-01' and '2018-08'
group by purchase_year_month
order by purchase_year_month;

-- （3）各州延迟率对比
-- 口径：同上
use olist_analytics;

select
	customer_state,
    concat('BR-', customer_state) as br_customer_state,
    round(sum(case when is_late = 1 then 1 else 0 end)/sum(case when is_delivered = 1 then 1 else 0 end), 4) as late_delivery_rate
from fct_orders o
join dim_customer_id_map m
on o.customer_id = m.customer_id
where is_valid_order = 1 and is_delivered = 1 and purchase_year_month between '2017-01' and '2018-08'
group by m.customer_state
order by late_delivery_rate desc;

-- （4）各品类延迟率
use olist_analytics;

select
	product_category_english,
    -- 该品类的所有订单数量
    sum(total_orders) as total_orders,
    -- 该品类的晚到订单数量
    sum(late_orders) as late_orders,
    -- 晚到率
    round(sum(late_orders) * 100/ sum(total_orders), 2) as category_late_rate
from fct_delivery_category
group by product_category_english
having sum(total_orders) >= 100
order by category_late_rate desc;
