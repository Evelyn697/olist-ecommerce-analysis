-- 给olist_analytics各表添加索引，解决视图查阅耗时长、与sql server断连的问题。

USE olist_analytics;

-- 给 dim_customer_id_map 加索引
CREATE INDEX idx_customer_id ON dim_customer_id_map (customer_id);
CREATE INDEX idx_customer_unique_id ON dim_customer_id_map (customer_unique_id);

-- 给 fct_orders 加索引
CREATE INDEX idx_order_id ON fct_orders (order_id);
CREATE INDEX idx_customer_id ON fct_orders (customer_id);

-- 给 fct_order_summary 加索引
CREATE INDEX idx_order_id ON fct_order_summary (order_id);

-- 给 fct_order_reviews 加索引
CREATE INDEX idx_order_id ON fct_order_reviews (order_id);

-- 给 dim_customers 加索引
CREATE INDEX idx_customer_unique_id ON dim_customers (customer_unique_id);

-- 给 fct_customer_rfm 加索引
CREATE INDEX idx_customer_unique_id ON fct_customer_rfm (customer_unique_id);