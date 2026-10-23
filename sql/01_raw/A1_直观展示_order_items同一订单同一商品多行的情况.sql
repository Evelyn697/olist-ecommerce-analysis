-- [直观展示] 同一订单同一商品多行的情况
-- WHERE用于分组前的行级数据过滤，HAVING用于分组后的聚合结果过滤。
use olist_raw;

select
	order_id,
    product_id,
    COUNT(*) AS item_count,
    GROUP_CONCAT(order_item_id ORDER BY order_item_id) AS item_ids,
    MAX(price) AS price
from order_items
group by order_id, product_id
having COUNT(*) > 1
order by item_count desc
limit 10;