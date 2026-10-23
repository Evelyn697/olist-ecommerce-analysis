-- ==============================================================
-- 脚本目的：fct_state_delivery_review
-- 服务图片：绘制各州配送天数 VS 评分散点图 
-- 粒度：
-- 来源：v_orders_enriched
-- 口径：2017-01至2018-08月期间的已送达的有效订单，且分数不为NULL。
-- ===============================================================

use olist_analytics;

drop table if exists fct_state_delivery_review;

create table fct_state_delivery_review as
select
    customer_state,
    count(distinct order_id) as order_cnt,
    round(avg(delivery_days), 2) as avg_delivery_days,
    round(avg(review_score_avg), 2) as avg_review_score,
    round(avg(is_late) * 100, 2) as late_rate_pct
from v_orders_enriched
where is_valid_order = 1 
	  and is_delivered = 1 
	  and review_score_avg is not null
	  and customer_state is not null
	  and purchase_year_month between '2017-01' and '2018-08'
group by customer_state;