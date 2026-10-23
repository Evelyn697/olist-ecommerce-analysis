-- ================================================================
-- M2 Q2 | RFM分层结果；
-- 分层代码见sql\02_analysis\07_create_fct_customer_rfm.sql，结果见fct_customer_rfm 
-- 口径：2016.09~2018.09，没有做时间的筛选。
-- （1）各分层客户数（&百分比）、 GMV 贡献（&百分比）与客单价
-- （2）各分层的RFM三要素均值、最值：平均最近消费距今天数、平均消费频次（各群体很接近）、平均累计消费金额、
-- 									  MIN（最近消费距今天天数）、MAX（最近消费距今天天数）、MIN（累计消费金额）、MAX（累计消费金额）。
-- （3）F 分布查询：各分层的消费频次分布，看复购行为的差异
--      —— 因为平均频次差异很小，所以看分布
-- ================================================================

use olist_analytics;

-- CTE（共用表表达式），输出5行，对应5类用户群体的信息（聚合指标）
with segment_agg as
(
	select
		segment,
		count(distinct customer_unique_id) as customer_cnt,
		sum(monetary) as gmv,
		sum(frequency) as total_orders,
		round(avg(recency_days), 0)       as avg_recency_days,   -- 平均最近消费距今天数
		round(avg(frequency), 2)          as avg_frequency,      -- 平均消费频次
		round(avg(monetary), 2)           as avg_monetary,       -- 平均累计消费金额
		round(min(recency_days), 0)       as min_recency,
		round(max(recency_days), 0)       as max_recency,
		round(min(monetary), 2)           as min_monetary,
		round(max(monetary), 2)           as max_monetary
	from fct_customer_rfm
    group by segment
)
select
	segment,
	customer_cnt,
    round(gmv, 2) as gmv,
    round(gmv/total_orders, 2) as aov,
    round(customer_cnt * 100/ sum(customer_cnt) over() , 2) as customer_pct,
    round(gmv * 100/ sum(gmv) over(), 2) as gmv_pct,
    avg_recency_days,   -- 平均最近消费距今天数
	avg_frequency,      -- 平均消费频次
	avg_monetary,       -- 平均累计消费金额
	min_recency,
	max_recency,
	min_monetary,
	max_monetary
from segment_agg
order by gmv desc;


-- ================================================================
-- （3）F分布查询：各分层的消费频次分布，看复购行为的差异
--      —— 因为平均频次差异很小，所以看分布
-- 结论：
-- ================================================================
select
	segment,
    count(*) as total,
    sum(case when frequency = 1 then 1 else 0 end) as freq_1,
    sum(case when frequency = 2 then 1 else 0 end) as freq_2,
    sum(case when frequency >= 3 then 1 else 0 end) as freq_3plus,
    sum(case when frequency = 1 then 1 else 0 end)*100/count(*) as freq_1_pct,
    sum(case when frequency = 2 then 1 else 0 end)*100/count(*) as freq_2_pct,
    sum(case when frequency >= 3 then 1 else 0 end)*100/count(*) as freq_3plus_pct,
    round(sum(case when frequency >= 2 then 1 else 0 end) * 100/count(*), 2) as repurchase_pct
from fct_customer_rfm
group by segment
order by repurchase_pct desc;
