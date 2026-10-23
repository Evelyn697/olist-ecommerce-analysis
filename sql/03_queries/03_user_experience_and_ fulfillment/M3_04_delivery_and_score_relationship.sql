-- ========================================================
-- M3 用户评价与物流分析 | Q4 物流时效 × 评分关联
-- （1）延迟天数与评分 fct_delay_review
-- （2）延迟天数 VS 评分 热力图  fct_delay_review
-- （3）各州“配送天数 × 评分” 散点（气泡图） fct_state_delivery_review
-- （4）热力图：评分 1-5 分布 vs 延迟情况
-- ========================================================


-- （3）各州“配送天数 × 评分” 散点
USE olist_analytics;

SELECT
    customer_state,
    avg_delivery_days,
    avg_review_score,
    order_cnt
FROM fct_state_delivery_review
WHERE order_cnt >= 100;  -- 过滤掉极小样本的州，避免散点图失真

-- （4）热力图：评分 1-5 分布 vs 延迟情况
USE olist_analytics;

SELECT
    CASE
        WHEN delay_days <= 0  THEN '1. 准时或提前'
        WHEN delay_days <= 3  THEN '2. 晚到 1-3 天'
        WHEN delay_days <= 7  THEN '3. 晚到 4-7 天'
        ELSE '4. 晚到 7 天以上'
    END AS delay_group,
    
    -- 把评分变成 1-5 类
    FLOOR(review_score_avg) AS score_bucket,
    COUNT(DISTINCT order_id) AS order_cnt
FROM v_orders_enriched
WHERE is_valid_order = 1 
  AND is_delivered = 1 
  AND review_score_avg IS NOT NULL
  AND purchase_year_month BETWEEN '2017-01' AND '2018-08'
GROUP BY delay_group, FLOOR(review_score_avg)
ORDER BY delay_group, score_bucket;