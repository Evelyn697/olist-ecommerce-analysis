-- ==============================================================
-- 脚本目的：构建延迟天数分桶与评分的聚合表 fct_delay_review
-- 粒度：一行 = 一个延迟分桶
-- 来源：fct_order_reviews
-- 口径：2017-01至2018-08月期间的已送达的有效订单，且分数不为NULL。
-- ===============================================================

use olist_analytics;

drop table if exists fct_delay_review;

create table fct_delay_review as
select
	case
		when delay_days <= 0 then '1. 准时或提前'
        when delay_days > 0 and delay_days <= 3 then '2. 晚到 1-3 天'
        when delay_days > 3 and delay_days <= 7 then '3. 晚到 4-7 天'
        when delay_days > 7 and delay_days <= 14 then '4. 晚到 8-14 天'
        when delay_days > 14 and delay_days <= 30 then '5. 晚到 15-30 天'
        else '6. 晚到 30 天以上'
	end as delay_bucket,
    count(distinct order_id) as order_cnt,
    -- 窗口函数永远是作用在 GROUP BY 聚合之后的“结果集”上。所以在写 OVER() 里面的内容时，你看到的已经是“每个桶只剩下一行”的世界了。
    -- COUNT(*) OVER()，它数的是桶的个数。
	-- SUM(COUNT(DISTINCT order_id)) OVER()，它数的是每个桶里订单数的总和。
    round(count(distinct order_id)* 100 / sum(count(distinct order_id)) over (), 2) as order_pct,
    round(avg(review_score_avg), 2) as avg_review_score,
    round(avg(case when review_score_avg = 5 then 1 else 0 end) * 100, 2) as pct_5star,
    round(avg(case when review_score_avg = 1 then 1 else 0 end) * 100, 2) as pct_1star
from v_orders_enriched
where is_valid_order = 1 
	  and is_delivered = 1 
	  and review_score_avg is not null
	  and purchase_year_month between '2017-01' and '2018-08'
group by delay_bucket
order by delay_bucket;

