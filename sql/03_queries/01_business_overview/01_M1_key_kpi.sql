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