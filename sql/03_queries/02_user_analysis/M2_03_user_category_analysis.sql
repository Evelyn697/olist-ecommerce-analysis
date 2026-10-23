-- ================================================================
-- M2 Q3 | 用户分析：不同用户群体的品类购买偏好差异：
-- （1）各用户群体的 Top 5 品类
-- （2）品类偏好度指数 = (该用户群体该品类的GMV在该用户群体的所有品类的总GMV占比) / (该品类的GMV占整个平台总GMV的比例)
-- ================================================================

use olist_analytics;

with ranked as (
	-- 本层查询粒度：(segment, category)
	select
		segment,
		category,
		customer_cnt,
		order_cnt,
		gmv,
		-- 每个分层内按 GMV 降序排名
		row_number() over (
			partition by segment
			order by gmv desc
		) as rn,
		-- 该品类在该分层内的 GMV 占比
		round(gmv * 100 / sum(gmv) over(partition by segment), 2) as category_share_pct
	from fct_customer_category)
select
	segment,
    category,
    customer_cnt,
    order_cnt,
    gmv,
    category_share_pct
from ranked
where rn <= 5
order by segment, rn;


-- ================================================================
-- （2）品类偏好度指数 = (该用户群体该品类的GMV在该用户群体的所有品类的总GMV占比) / (该品类的GMV占整个平台总GMV的比例)
-- ================================================================

USE olist_analytics;

WITH segment_total AS (
    -- 每个分层的总 GMV
    SELECT segment, SUM(gmv) AS total_gmv
    FROM fct_customer_category
    GROUP BY segment
),
overall_category AS (
    -- 每个品类在全平台的 GMV 和占比
    SELECT
        category,
        SUM(gmv) AS overall_gmv,
        SUM(gmv) / (SELECT SUM(gmv) FROM fct_customer_category) AS overall_share
    FROM fct_customer_category
    GROUP BY category
)
SELECT
    cc.segment,
    cc.category,
    cc.gmv,
    ROUND(cc.gmv / st.total_gmv * 100, 2)        AS segment_share_pct,
    ROUND(oc.overall_share * 100, 2)             AS overall_share_pct,
    -- 偏好度指数
    ROUND(
        (cc.gmv / st.total_gmv) / oc.overall_share,
        2
    ) AS preference_index
FROM fct_customer_category cc
JOIN segment_total st    ON cc.segment  = st.segment
JOIN overall_category oc ON cc.category = oc.category
WHERE cc.gmv > 0
ORDER BY cc.segment, preference_index DESC;