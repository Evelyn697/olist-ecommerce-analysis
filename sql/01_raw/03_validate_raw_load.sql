use olist_raw;

select 'customers' as tbl, count(*) as cnt from customers
union
	select 'geolocation' as tbl, count(*) as cnt from geolocation
union
	select 'order_items' as tbl, count(*) as cnt from order_items
union
	select 'order_payments' as tbl, count(*) as cnt from order_payments
union
	select 'order_reviews' as tbl, count(*) as cnt from order_reviews
union
	select 'orders' as tbl, count(*) as cnt from orders
union
	select 'product_category_name_translation' as tbl, count(*) as cnt from product_category_name_translation
union
	select 'products' as tbl, count(*) as cnt from products
union
	select 'sellers' as tbl, count(*) as cnt from sellers