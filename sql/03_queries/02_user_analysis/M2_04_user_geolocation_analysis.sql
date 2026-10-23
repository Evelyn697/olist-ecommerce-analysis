-- ================================================================
-- M2 Q4 | 用户-地域分布分析

-- 目的：各州的用户数、GMV、AOV，以及高价值客户占比
-- 依赖：v_orders_enriched + fct_customer_rfm + dim_customer_id_map
-- 粒度：一行 = 一个州
-- ================================================================

use olist_analytics;

with state_user as
-- 表格state_user：每行为一个州，存储各州用户数、订单数、GMV、AOV信息；
	(select
		customer_state,
		count(distinct customer_unique_id) 					as customer_cnt,
		count(distinct order_id)		   					as order_cnt,
		sum(order_total_value)			   					as gmv,
		sum(order_total_value) / count(distinct order_id)	as aov
	from v_orders_enriched
	where is_valid_order = 1 and customer_state is not null
	group by customer_state
),
state_high_value as
-- 表格state_high_value：各州的高价值客户数
	(select
		m.customer_state,
        count(distinct r.customer_unique_id) as high_value_cnt
    from fct_customer_rfm r
    left join dim_customer_id_map m
    on r.customer_unique_id = m.customer_unique_id
    where r.segment in ('高价值活跃', '高价值流失风险')
    group by m.customer_state
)
select
	su.customer_state,
    su.customer_cnt,
    su.order_cnt,
    round(su.customer_cnt* 100 / sum(su.customer_cnt) over(), 2)		as customer_pct,
	round(su.order_cnt * 100 / sum(su.order_cnt) over(), 2)				as order_pct,
    round(su.gmv, 2) 													as gmv,
    round(su.aov, 2) 													as aov,
    coalesce(shv.high_value_cnt, 0) 									as high_value_cnt,
    -- 高价值客户占比
    round(coalesce(shv.high_value_cnt, 0) * 100 / su.customer_cnt, 2) 	as high_value_pct,
    -- 该州 GMV 占全国比例
    round(su.gmv * 100.0 / sum(su.gmv) over(), 2) 						as gmv_pct
from state_user su
left join state_high_value shv
on su.customer_state = shv.customer_state
order by su.gmv desc;

-- ============================================================================
-- 结果分析：
-- （1）SP 州"量大质一般"
-- ① SP 州的用户虽然多，但平均质量低于全国（全国高质量用户占比：32.1%）
-- ② 大城市的用户可能更"比价"，或者平台在 SP 州的拉新策略偏"走量"
-- ③ SP 州的 GMV 占比（37.36%）< 用户占比（41.83%），说明每个 SP 用户贡献的 GMV 低于平均
-- 这是非常反直觉的发现——按常识，经济最发达的州应该客户质量最高。但数据显示相反。可能的解释：
-- ① SP 州用户基数大，长尾低价值用户拉低了平均
-- ② 其他州可能"物流贵、平台选择少"，反而留下的客户更精准。

-- （2）部分小州（用户数<400）高价值占比显著偏高，是"质优量少"的典型。
-- 比如：AC、RO、SE、AL，可能的原因：
-- 		客户网购选择少，一旦选 Olist 就长期用
-- 		客户群体偏中产，AOV 高
-- 		样本小，统计噪声大

-- （3）部分用户规模中等（700~1000）的州的AOV高于大州SP的AOV
-- 例如：PA、MA、MT、PB，可以作为精准营销的目标。
