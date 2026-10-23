-- order_payments 表格存在 payment_value=0 但 order_item表 price和freight_value都不为0 的情况；

-- 经检查，是同一笔订单分多次支付（payment_installments>1），各次支付的总额 = 商品价格 + 运费；


use olist_raw;

select
	o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    op.payment_type,
    op.payment_value,
    (select sum(oi.price + oi.freight_value)
     from order_items oi where oi.order_id = o.order_id) as order_total
from orders o
join order_payments op
on o.order_id = op.order_id
where o.order_id in 
	(select order_id from order_payments where payment_value=0)
order by o.order_id;
