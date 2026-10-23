-- ============================================================
-- 脚本目的：构建客户维度表 dim_customers
--
-- 粒度：一行 = 一个真实客户（customer_unique_id 唯一）
-- 数据源：dim_customer_id_map + fct_orders + fct_order_summary
--
-- 与 dim_customer_id_map 的区别：
--   - dim_customer_id_map：一行 = 一个订单级 customer_id，只做映射
--   - dim_customers：一行 = 一个客户级 customer_unique_id，含聚合指标
--
-- 复购率、RFM、用户分层都基于这张表。
-- customer_city，customer_state都取最新一笔订单对应的城市和州。
-- ============================================================

use olist_analytics;

drop table if exists dim_customers;

CREATE TABLE dim_customers AS
SELECT
    m.customer_unique_id,
    m.customer_city  AS customer_city,
    m.customer_state AS customer_state,
    agg.total_orders,
    agg.valid_orders,
    agg.total_monetary,
    agg.first_order_date,
    agg.last_order_date
FROM (
    -- 用 ROW_NUMBER 给每个客户的订单按时间编号，取第 1 条
    SELECT
        m.customer_unique_id,
        m.customer_city,
        m.customer_state,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY m.customer_unique_id
            ORDER BY o.order_purchase_timestamp ASC
        ) AS rn
    FROM dim_customer_id_map m
    LEFT JOIN fct_orders o ON m.customer_id = o.customer_id
) m
JOIN (
    -- 聚合指标
    SELECT
        m.customer_unique_id,
        -- 总订单数（含取消和不可用）
        COUNT(DISTINCT o.order_id) AS total_orders,
        -- 有效订单数（排除 canceled 和 unavailable）
		-- SUM(CASE WHEN ... THEN 1 ELSE 0 END) 是"条件计数"的标准写法
        SUM(CASE WHEN o.is_valid_order = 1 THEN 1 ELSE 0 END) AS valid_orders,
		-- 累计消费金额（只算有效订单，含运费，与 GMV 口径一致）
		-- COALESCE(x, 0)：如果 x 是 NULL 就返回 0
		-- 为什么会有 NULL？因为 LEFT JOIN 后如果订单没有 items，order_total_value 为 NULL。这类订单金额应记为 0
        COALESCE(SUM(CASE WHEN o.is_valid_order = 1 THEN s.order_total_value ELSE 0 END), 0) AS total_monetary,
        -- 首次和最近下单时间
        MIN(o.order_purchase_timestamp) AS first_order_date,
        MAX(o.order_purchase_timestamp) AS last_order_date
    FROM dim_customer_id_map m
    LEFT JOIN fct_orders o        ON m.customer_id = o.customer_id
    LEFT JOIN fct_order_summary s ON o.order_id    = s.order_id
    -- 按客户级 ID 分组，把同一客户的多个订单聚合成一行
    GROUP BY m.customer_unique_id
) agg ON m.customer_unique_id = agg.customer_unique_id
WHERE m.rn = 1;


SELECT COUNT(*) FROM dim_customers;                        -- 96096
SELECT COUNT(*) FROM dim_customers WHERE total_orders > 1; -- 复购客户数 2997
SELECT ROUND(SUM(total_monetary), 2) FROM dim_customers;   -- 有效订单的总 GMV 15735527.03，和原始的1584万相比相差了无效订单（unavailable & canceled）的GMV

-- 复购率 = 复购客户数 / 总客户数
SELECT
    ROUND(
        SUM(CASE WHEN valid_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(CASE WHEN valid_orders > 0 THEN 1 ELSE 0 END),
        2
    ) AS repurchase_rate_pct
FROM dim_customers;											-- 3.01%

-- fct_order_summary 里无效订单（canceled/unavailable)的金额
SELECT ROUND(SUM(s.order_total_value), 2) AS invalid_gmv
FROM fct_orders o
JOIN fct_order_summary s ON o.order_id = s.order_id
WHERE o.is_valid_order = 0;						-- 结果：108026.21，说明有效订单的总GMV 15735527.03 = 原始的1584万 - 无效订单的无效GMV；