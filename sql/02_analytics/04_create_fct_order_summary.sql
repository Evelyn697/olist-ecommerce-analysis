-- ============================================================
-- 脚本目的：构建订单金额汇总表 fct_order_summary
--
-- 粒度：一行 = 一个订单
-- 数据源：olist_raw.order_items
--
-- 背景知识（重要）：
--   order_items 是"每件商品一行"的粒度。同一订单买 3 件商品就有 3 行。
--   所以做订单级金额分析必须先 GROUP BY order_id 聚合。
--
--   另外，order_items 只覆盖 98666 个订单（orders 有 99441 个），
--   差额 775 个是取消/未生成明细的订单。这些订单在 fct_order_summary中不存在，后续 JOIN 时要用 LEFT JOIN 并 COALESCE 处理。
-- ============================================================
use olist_analytics;

drop table if exists fct_order_summary;

create table fct_order_summary as
select
	order_id,
    -- 一笔订单包含多少件商品
    count(*) as item_count,
    -- 一笔订单包含多少种不同的商品
    count(distinct product_id) as product_count,
    -- 一笔订单涉及多少商家
    count(distinct seller_id) as seller_count,
    -- SUM 商品价格合计（不含运费）
    sum(price) as product_revenue,
    -- 每笔订单运费合计
    sum(freight_value) as freight_revenue,
    -- 每笔订单总金额
    sum(price+freight_value) as order_total_value,
    -- 当前订单里每件商品平均价格（不是客单价！客单价要用 SUM/订单数）
    avg(price) as avg_item_price
from olist_raw.order_items
group by order_id;

select
	count(*),			-- 98666
    round(sum(order_total_value), 2) as GMV,   -- GMV：15843553.24
    ROUND(SUM(order_total_value) / COUNT(DISTINCT order_id), 2) as AOV     -- 客单价AOV：160.58
from fct_order_summary;