"""
情况 A：同一 review_id 对应不同 order_id（一条评价被错误挂到多个订单）
情况 B：同一 review_id 对应同一 order_id（完全重复的行，重复导入）
情况 C：同一 order_id 对应不同 review_id（一个订单有多条评价）
"""

import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DIR = BASE_DIR / "data" / "raw"
PROCESSED_DIR = BASE_DIR / "data" / "processed"
df = pd.read_csv(RAW_DIR/"olist_order_reviews_dataset.csv", dtype=str)

print("总行数:", len(df))              # 99224
print("唯一 review_id 数:", df["review_id"].nunique())     # 98410
print("唯一 order_id 数:", df["order_id"].nunique())       # 98673
print()

# 情况 A/B：review_id 重复
# df.duplicated: 标记数据中的重复项。通过设置keep=False，df.duplicated()会返回一个布尔数组，所有重复项都会被标记为True。
dup_review = df[df.duplicated("review_id", keep=False)].sort_values("review_id")
print("涉及重复 review_id 的行数:", len(dup_review))           # 1603
print("重复的 review_id 个数:", dup_review["review_id"].nunique())   # 789
print()

# 看重复 review_id 是否对应不同 order_id
grouped = dup_review.groupby("review_id").agg(
    n_rows=("order_id", "size"),
    n_orders=("order_id", "nunique"),
    orders=("order_id", lambda x: list(x)),
)
print("重复 review_id 的模式：")
print(grouped.head(20))
print()

"""
重复 review_id 的模式：
                                  n_rows  ...                                             orders
review_id                                 ...                                                   
00130cbe1f9d422698c812ed8ded1919       2  ...  [dfcdfc43867d1c1381bfaf62d6b9c195, 04a28263e08...
0115633a9c298b6a98bcbe4eee75345f       2  ...  [78a4201f58af3463bdab842eea4bc801, 0c9850b2c17...
"""

# 情况 C：order_id 重复
dup_order = df[df.duplicated("order_id", keep=False)].sort_values("order_id")
print("涉及重复 order_id 的行数:", len(dup_order))                 # 1098
print("重复的 order_id 个数:", dup_order["order_id"].nunique())      # 547
print()

# 检查 (review_id, order_id) 组合是否唯一
combo_dupes = df[df.duplicated(["review_id", "order_id"], keep=False)]
print("(review_id, order_id) 组合重复的行数:", len(combo_dupes))                       # 0
print("重复的组合数:", combo_dupes.groupby(["review_id", "order_id"]).ngroups)        # 0
print()


# 保存明细供人工查看
dup_review.to_csv(PROCESSED_DIR / "order_reviews_dataset_review_dup_detail.csv", index=False)
print("重复明细已保存到 data/processed/order_reviews_dataset_review_dup_detail.csv")

dup_order.to_csv(PROCESSED_DIR / "order_reviews_dataset_order_dup_detail.csv", index=False)
print("重复明细已保存到 data/processed/order_reviews_dataset_order_dup_detail.csv")
