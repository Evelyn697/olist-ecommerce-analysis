-- ==============================================================
-- 品类 × 地区交叉洞察
-- 目的：每个州的 Top 3 品类，看地域偏好
-- 依赖：fct_order_items + fct_orders + dim_customer_id_map
-- 用到 CTE 和窗口函数 ROW_NUMBER
-- ==============================================================
USE olist_analytics;

WITH state_category AS (
    -- 第一步：算每个（州, 品类）组合的 GMV 和订单数
    SELECT
        m.customer_state,
        i.product_category_english AS category,
        SUM(i.price)               AS gmv,
        COUNT(DISTINCT i.order_id) AS orders
    FROM fct_order_items i
    JOIN fct_orders o            ON i.order_id  = o.order_id
    JOIN dim_customer_id_map m   ON o.customer_id = m.customer_id
    WHERE o.is_valid_order = 1
      AND i.product_category_english != 'unknown'
    GROUP BY m.customer_state, i.product_category_english
),
state_total AS (
    -- 第二步：算每个州的总 GMV，用于计算占比
    SELECT
        customer_state,
        SUM(gmv) AS total_gmv,
        sum(orders) as total_orders
    FROM state_category
    GROUP BY customer_state
    HAVING total_orders >= 500      -- ← 过滤小样本州
),
ranked AS (
    -- 第三步：每个州内按 GMV 降序排名
    SELECT
        sc.customer_state,
        sc.category,
        sc.gmv,
        sc.orders,
        st.total_gmv,
        ROUND(sc.gmv / st.total_gmv * 100, 2) AS category_share_pct,
        -- ROW_NUMBER：每个州内按 gmv 降序编号
        ROW_NUMBER() OVER (
            PARTITION BY sc.customer_state
            ORDER BY sc.gmv DESC
        ) AS rn
    FROM state_category sc
    JOIN state_total st ON sc.customer_state = st.customer_state
)
-- 第四步：每个州只保留前 3 名
SELECT
    customer_state,
    category,
    ROUND(gmv, 2)              AS gmv,
    orders,
    category_share_pct
FROM ranked
WHERE rn <= 3
ORDER BY customer_state, rn;