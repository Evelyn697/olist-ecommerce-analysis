-- ============================================================
-- 脚本目的：构建订单事实表 fct_orders
--
-- 粒度：一行 = 一个订单（order_id 唯一）
-- 数据源：olist_raw.orders
-- 产出字段：原始字段 + 时间维度派生 + 履约时效派生 + 状态标记
-- ============================================================
use olist_analytics;

drop table if exists fct_orders;
create table fct_orders as
select
	-- ===== 原始字段（原样保留）=====
	order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    
    -- ===== 时间维度派生 =====
    -- DATE_FORMAT(日期, 格式)：把日期转成指定格式的字符串
    -- '%Y' = 4 位年，'%m' = 2 位月。结果是 '2017-05' 这样的字符串
    -- 用于按月分组统计
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as purchase_year_month,
    
    -- YEAR() 提取年份，MONTH() 提取月份
    YEAR(order_purchase_timestamp) AS purchase_year,
    MONTH(order_purchase_timestamp) AS purchase_month,
    
    -- DAYOFWEEK()：返回 1=周日, 2=周一, ..., 7=周六
    DAYOFWEEK(order_purchase_timestamp) AS purchase_weekday,
    
    -- HOUR()：提取小时（0-23），用于分析下单时段
    HOUR(order_purchase_timestamp) AS purchase_hour,
    
    -- ===== 履约时效派生 =====
    -- TIMESTAMPDIFF(单位, 开始时间, 结束时间)：计算两个时间的差
    -- 单位可以是 SECOND, MINUTE, HOUR, DAY, MONTH, YEAR
    -- 这里算从下单到审批经过了几小时。如果 order_approved_at 是 NULL，
    -- 结果自动为 NULL（不会报错）
    timestampdiff(HOUR, order_purchase_timestamp, order_approved_at) as approval_hours,
    
    -- DATEDIFF(结束日期, 开始日期)：返回两个日期的天数差（end - start）
    -- 注意参数顺序和 TIMESTAMPDIFF 相反，DATEDIFF 是"结束在前"
    datediff(order_delivered_customer_date, order_purchase_timestamp) as delivery_days,
    datediff(order_estimated_delivery_date, order_purchase_timestamp) as estimated_days,
    
    -- 实际送达 - 承诺送达：正数=晚了，负数=早了，0=正好
    -- 未送达的订单这一步结果是 NULL
    datediff(order_delivered_customer_date, order_estimated_delivery_date) AS delay_days,
    
    -- ===== 状态标记（0/1 便于求平均得到比率）=====
    -- CASE WHEN 条件 THEN 值1 ELSE 值2 END：SQL 的条件表达式
    -- 这里用三层判断：未送达=NULL，晚到=1，准时或提前=0
    case
		when order_delivered_customer_date is null then null
        when order_delivered_customer_date > order_estimated_delivery_date then 1
        else 0
	end as is_late,
    
    case when order_status ='delivered' then 1
		 else 0
	end as is_delivered,
    
    case when order_status = 'canceled' then 1
		 else 0
	end as is_canceled,
    
    -- 有效订单 = 排除取消和不可用，且订单送达时长不为负数；
    case
        when order_status not in ('canceled', 'unavailable') or datediff(order_delivered_customer_date, order_purchase_timestamp) < 0 then 1
        else 0
    end as is_valid_order
    
from olist_raw.orders;


SELECT COUNT(*) FROM fct_orders;                              -- 应 99441
SELECT COUNT(*) FROM fct_orders WHERE is_late = 1;            -- 晚到订单数 （7827）
SELECT COUNT(*) FROM fct_orders WHERE is_delivered = 1;       -- 已送达数（96478）
SELECT COUNT(*) FROM fct_orders WHERE is_canceled = 1;        -- 取消数（625）

-- 看下派生字段是否合理
SELECT 
    purchase_year_month,
    COUNT(*) AS orders,
    ROUND(AVG(is_late) * 100, 2) AS late_rate_pct
FROM fct_orders
WHERE is_delivered = 1
GROUP BY purchase_year_month
ORDER BY purchase_year_month;