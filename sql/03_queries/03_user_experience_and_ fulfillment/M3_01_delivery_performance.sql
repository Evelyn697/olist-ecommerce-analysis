-- ========================================================
-- M3 用户评价与物流分析 | Q1 配送时效KPI + 分布
-- 计算指标：平均实际送达天数、平均承诺天数、平均提前天数、配送准时率。配送天数分布
-- 数据来源：fct_orders
-- 统计口径：只统计有效且已送达的订单。平均提前天数针对所有已送达订单（涵盖晚到订单），体现整体履约能力。
-- ========================================================

-- 1. 配送时效KPI
use olist_analytics;

select
	-- 1. 平均实际送达天数  -> 12.48
	round(avg(delivery_days), 2) as avg_delivery_days,
    -- 2. 平均承诺送达天数  -> 24.28
    round(avg(estimated_days), 2) as avg_estimated_days,
    -- 3. 整体平均提前天数（晚到则为负数）-> 11.81
    round(avg(-delay_days), 2) as avg_advance_days,
    -- 4. 准时送达率（准时或提前）-> 91.86%
    round(sum(CASE WHEN is_late = 0 THEN 1 ELSE 0 END)/count(*), 4) as on_time_delivery_rate,
    -- 补充：条件计数，方便核对
    COUNT(*) AS total_delivered_orders
from fct_orders
where is_valid_order = 1 and is_delivered = 1 and purchase_year_month between '2017-01' and '2018-08';

-- 2. 配送天数分布
USE olist_analytics;

-- 目的：查看订单配送天数的分布情况
-- 核心逻辑：按天数分桶，统计每个桶内的订单数
SELECT
    CASE
        WHEN delivery_days <= 3  THEN '0-3天 (极速)'
        WHEN delivery_days <= 7  THEN '4-7天 (较快)'
        WHEN delivery_days <= 14 THEN '8-14天 (正常)'
        WHEN delivery_days <= 21 THEN '15-21天 (偏慢)'
        WHEN delivery_days <= 30 THEN '22-30天 (很慢)'
        ELSE '30天以上 (极慢)'
    END AS delivery_bucket,
    COUNT(*) AS order_cnt,
    -- 算一下占比
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM fct_orders
WHERE is_valid_order = 1 
  AND is_delivered = 1 
  AND purchase_year_month BETWEEN '2017-01' AND '2018-08'
GROUP BY delivery_bucket
ORDER BY delivery_bucket;

-- 3.月度配送时效趋势（双轴折线图）
USE olist_analytics;

-- 目的：看实际配送时间和承诺时间的月度变化趋势（superset可直接绘图，不用生成虚拟数据集或导入物理表）
SELECT
    purchase_year_month,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(estimated_days), 2) AS avg_estimated_days
FROM fct_orders
WHERE is_valid_order = 1 
  AND is_delivered = 1 
  AND purchase_year_month BETWEEN '2017-01' AND '2018-08'
GROUP BY purchase_year_month
ORDER BY purchase_year_month;

-- 4. 各州配送时效对比（最慢 Top 15）
use olist_analytics;

select
	customer_state,
    round(avg(delivery_days), 2) as avg_delivery_days,
    count(*) as order_cnt
from fct_orders o
join dim_customer_id_map m
on o.customer_id = m.customer_id
where is_valid_order = 1 
  and is_delivered = 1 
  and purchase_year_month between '2017-01' and '2018-08'
group by customer_state
-- 过滤掉样本量太小的州，避免统计偏差
having count(*) >= 100
order by avg_delivery_days desc
limit 15;
