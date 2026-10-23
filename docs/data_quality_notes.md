# 数据质量问题记录



1\. order\_reviews 表的一对多关系：

场景A：同一则评价（review\_id）涉及不同的订单（order\_id），涉及重复review\_id 1603行，涉及789个review\_id；

场景C：同一笔订单（order\_id）有多则不同的评价（review\_id），涉及重复order\_id 1098行，涉及547个order\_id；

没有发现场景B：（review\_id, order\_id)同时重复的情况。

处理方式：

* raw 层不加主键，只加索引，忠实保存原始数据；Analytics层以（评价ID，订单ID）作为复合主键。
* analytics 层按 `order_id` 聚合，取平均评分，`review_comment_message` 取最新一条

影响：直接 JOIN `orders` 和 `order_reviews` 会导致行数膨胀，必须先聚合再 JOIN。



2\.  product 表的产品品类信息缺失问题

32,951 行，共610行缺少产品品类信息和照片数量信息，缺失率：1.85%

影响：影响品类排名分析

措施：后续标记为 unknown，分析品类时过滤掉未知品类。



3\. product\_category\_name\_translation 产品翻译信息缺失

pc\_gamer，portateis\_cozinha\_e\_preparadores\_de\_alimentos 产品类别缺少对应的英文名称

措施：手动添加对应的英文名称。



4\. （非质量问题，仅记录）order\_payments表存在 payment\_value=0的情况，经检查，是同一笔订单分多次支付（payment\_installments>1），

各次支付的总额 = 商品价格 + 运费；



