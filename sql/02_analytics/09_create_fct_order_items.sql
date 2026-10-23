-- ============================================================
-- 脚本目的：构建订单项事实表 fct_order_items
--
-- 粒度：一行 = 一个订单项（一件商品）
--   - 同一订单买 3 件相同商品 → 3 行
--   - 同一订单买 3 种不同商品 → 3 行
--   这是 Olist 数据集的原始粒度，不做聚合。
--
-- 数据源：
--   raw.order_items  （主表）
--   raw.products     （关联品类）
--   raw.sellers      （关联卖家州）
--   dim_product_category_translation（关联英文品类名）
--
-- 用途：品类分析、卖家分析、运费分析、订单项级金额分析
-- ============================================================

USE olist_analytics;

DROP TABLE IF EXISTS fct_order_items;

CREATE TABLE fct_order_items AS
SELECT
    -- ===== 订单项标识 =====
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    -- ===== 订单项属性 =====
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,

    -- 订单项总金额
    oi.price + oi.freight_value AS item_total_value,

    -- 是否包邮：运费为 0 标记为 1
    CASE WHEN oi.freight_value = 0 THEN 1 ELSE 0 END AS is_free_shipping,

    -- ===== 商品品类（关联 products + 翻译表）=====
    p.product_category_name,
    -- COALESCE：如果翻译表里没有对应英文名（或 products 里品类为 NULL），
    --           兜底为 'unknown'，避免后续 GROUP BY 时漏掉这些行
    COALESCE(t.product_category_name_english, 'unknown') AS product_category_english,

    -- ===== 卖家州（关联 sellers）=====
    s.seller_state,
    
    -- ===== 是否为有效订单（关联 fct_orders）=====
    fo.is_valid_order as is_valid_order

FROM olist_raw.order_items oi
-- LEFT JOIN 保证：即使商品或卖家信息缺失，订单项本身不丢
LEFT JOIN olist_raw.products p
       ON oi.product_id = p.product_id
LEFT JOIN dim_product_category_translation t
       ON p.product_category_name = t.product_category_name
LEFT JOIN olist_raw.sellers s
       ON oi.seller_id = s.seller_id
LEFT JOIN olist_analytics.fct_orders fo
	   ON fo.order_id = oi.order_id;

USE olist_analytics;

CREATE INDEX idx_order_id   ON fct_order_items (order_id);
CREATE INDEX idx_product_id ON fct_order_items (product_id);
CREATE INDEX idx_seller_id  ON fct_order_items (seller_id);
CREATE INDEX idx_category   ON fct_order_items (product_category_english);


SELECT COUNT(*) FROM fct_order_items;                              -- 应 112650
SELECT COUNT(DISTINCT order_id) FROM fct_order_items;              -- 应 98666
SELECT COUNT(DISTINCT product_category_english) FROM fct_order_items; -- 应约 71-73


-- ==========================================================
-- 看下品类分布，确认 unknown 有多少行 -> 1603行
SELECT product_category_english, COUNT(*) AS cnt
FROM fct_order_items
GROUP BY product_category_english
ORDER BY cnt DESC;

-- 检查是否有 order_items 里的商品没匹配到 products  -> 1603，对应unknown;
SELECT COUNT(*) AS unmatched
FROM fct_order_items
WHERE product_category_name IS NULL;
