-- ================================================================
-- 建表脚本
-- 目标：构建品类维度 × 月份的延迟率事实表 fct_delivery_category
-- 粒度：一行 = (product_category_english, purchase_year_month)
-- 用途：M3 用户评价与物流分析 | 分析不同品类的延迟情况
-- 注意事项：如果一个订单包含多个品类，且该订单晚到了，那么这个订单里的所有品类都会计入“晚到”。
-- 			 所以计算品类订单数时，必须用 COUNT(DISTINCT order_id)
-- ================================================================

use olist_analytics;

drop table if exists fct_delivery_category;

create table fct_delivery_category as
select
	i.product_category_english,
    o.purchase_year_month,
    -- 该品类在该月的总订单数（去重，因为一个订单可能买多个同类商品）
    count(distinct o.order_id) as total_orders,
    -- 该品类在该月的晚到订单数
    count(distinct case when o.is_late = 1 then o.order_id end) as late_orders,
    -- 该品类在该月的延迟率
    round(
        count(distinct case when o.is_late = 1 then o.order_id end) * 100.0 
        / count(distinct o.order_id), 
        2
    ) as late_rate_pct
from fct_orders o
join fct_order_items i
on o.order_id = i.order_id
where o.is_valid_order = 1 
	and o.is_delivered = 1 
    and o.purchase_year_month between '2017-01' and '2018-08'
    and i.product_category_english != 'unknown'
group by i.product_category_english, o.purchase_year_month;

-- 添加索引
CREATE INDEX idx_category ON fct_delivery_category (product_category_english);
CREATE INDEX idx_month ON fct_delivery_category (purchase_year_month);

-- 验证代码：看下整体有多少行，以及平均延迟率是否接近 8.13%   -> 1221, 6.97
SELECT COUNT(*), ROUND(AVG(late_rate_pct), 2) FROM fct_delivery_category; 
