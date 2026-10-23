-- ============================================================
-- 脚本目的：把 raw.order_reviews 聚合到 order_id 粒度
--
-- 背景：
--   之前诊断出两个问题：
--   - 情况 A：789 个 review_id 关联了多个 order_id
--   - 情况 C：547 个 order_id 有多条评价
--   直接在订单级 JOIN reviews 会导致行数膨胀。
--
-- 解决方式：按 order_id 聚合，一条订单一行。
-- ============================================================

use olist_analytics;

drop table if exists fct_order_reviews;

create table fct_order_reviews as 
select
	order_id,
    
    -- 该订单收到几条评价
    count(*) as review_count,
    
    -- 平均评分（一单多评时最有代表性）
    avg(review_score) as review_score_avg,
    
    -- 最低分和最高分
    min(review_score) as review_score_min,
    max(review_score) as review_score_max,
    
    -- 最近一次评价时间
    max(review_answer_timestamp) as last_review_date,
    
        -- 取最近一条评论文本
    -- GROUP_CONCAT(列 ORDER BY ... SEPARATOR '|||')：
    --   把多行的值拼成一个字符串，按指定顺序，用 '|||' 分隔
    --   分隔符用 '|||' 而不是默认的 ','，因为评论内容里可能有逗号
    -- SUBSTRING_INDEX(字符串, '|||', 1)：
    --   取用 '|||' 分隔后的第 1 段
    -- 组合起来 = 按时间倒序排列后取第一条评论
    SUBSTRING_INDEX(
        GROUP_CONCAT(review_comment_message
                     ORDER BY review_creation_date DESC
                     SEPARATOR '|||'),
        '|||', 1
    ) AS last_comment_message
    
from olist_raw.order_reviews
group by order_id;

-- 验证
SELECT COUNT(*) FROM fct_order_reviews;                          --  98673
SELECT COUNT(*) FROM fct_order_reviews WHERE review_count > 1;   --  547
SELECT ROUND(AVG(review_score_avg), 2) FROM fct_order_reviews;   --  4.09

