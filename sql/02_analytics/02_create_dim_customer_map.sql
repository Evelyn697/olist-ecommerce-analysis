USE olist_analytics;

CREATE TABLE dim_customer_id_map AS
SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
FROM olist_raw.customers;