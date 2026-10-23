-- ============================================================
-- 脚本目的：构建客户 RFM 分层表 fct_customer_rfm
--
-- RFM = Recency（最近一次消费）、Frequency（消费频次）、Monetary（消费金额）
--
-- 关键背景：
--   Olist 复购率只有 3.12%，F 维度几乎失效（绝大多数客户 F=1）。
--   所以分层主要用 R + M，F 只保留作为参考。
--
-- 分层逻辑：
--   1. 用 NTILE(5) 把 R 和 M 各分成 5 档，1-5 分（分数越高越好）
--   2. 根据 R 分数和 M 分数组合，把客户归入 5 个群体
-- 依据：前40%，代表"高于平均"，后40%，代表"低于平均"，中间20%，代表“平均水平"。
-- 		用分位数把连续变量离散化，便于业务分组。
-- ============================================================

use olist_analytics;

drop table if exists fct_customer_rfm;

create table fct_customer_rfm as 
select
	customer_unique_id,
    -- ===== R 维度 =====
    -- 以数据集最后一天为"今天"，算客户最近一次消费距今天的天数
    -- 用子查询而不是 CURRENT_DATE，保证脚本可复现
    recency_days,
    frequency,
    monetary,
    -- ===== R/M 打分 =====
    -- NTILE(5)：把数据按指定顺序分成 5 组，每组数量大致相等，
    --           第 1 组返回 1，第 5 组返回 5
    -- R 打分：按 recency_days DESC 排序 → recency_days 最大的拿 1 分（最差），recency_days 最小的拿 5 分（最好）
    ntile(5) over (order by recency_days desc) as r_score,
    ntile(5) over (order by monetary asc) as m_score,
    
    -- ===== 客户分层 =====
    -- 根据 R 和 M 的组合划分客户群体
    -- 阈值 4：分数 4-5 视为"高"，1-2 视为"低"
    CASE
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) >= 4
             AND NTILE(5) OVER (ORDER BY monetary ASC) >= 4
             THEN '高价值活跃'
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) <= 2
             AND NTILE(5) OVER (ORDER BY monetary ASC) >= 4
             THEN '高价值流失风险'
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) >= 4
             AND NTILE(5) OVER (ORDER BY monetary ASC) <= 2
             THEN '低价值活跃'
        WHEN NTILE(5) OVER (ORDER BY recency_days DESC) <= 2
             AND NTILE(5) OVER (ORDER BY monetary ASC) <= 2
             THEN '低价值流失'
        ELSE '中等价值'
    END AS segment
from 
	(-- 第一层：计算基础字段
    SELECT
        customer_unique_id,
        -- ===== R 维度 =====
		-- 以数据集最后一天为"今天"，算客户最近一次消费距今天的天数
		-- 用子查询而不是 CURRENT_DATE，保证脚本可复现
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM fct_orders),
            last_order_date
        ) AS recency_days,
        -- ===== F 维度 =====
        valid_orders  AS frequency,
        -- ===== M 维度 =====
        total_monetary AS monetary
    FROM dim_customers
    -- 只对有有效订单的客户做 RFM，排除只有取消订单的客户
    WHERE valid_orders > 0
	) t;
    
    
    
SELECT
	segment, 
    COUNT(*) AS cnt,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fct_customer_rfm), 2) AS pct,
	ROUND(AVG(monetary), 2) AS avg_monetary,
	ROUND(AVG(recency_days), 0) AS avg_recency
FROM fct_customer_rfm
GROUP BY segment
ORDER BY cnt DESC;
