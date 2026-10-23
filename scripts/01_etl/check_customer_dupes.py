"""
检查 customers 表中，customer_id 和 customer_unique_id 是否为 一一对应关系。
"""
import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DIR = BASE_DIR / "data" / "raw"
PROCESSED_DIR = BASE_DIR / "data" / "processed"
df = pd.read_csv(RAW_DIR/"olist_customers_dataset.csv", dtype=str)

print("总行数:", len(df))              # 99441
print("唯一 customer_id 数:", df["customer_id"].nunique())     # 99441
print("唯一 customer_unique_id 数:", df["customer_unique_id"].nunique())       # 96096
print()

# 情况 A/B：customer_id 重复
# df.duplicated: 标记数据中的重复项。通过设置keep=False，df.duplicated()会返回一个布尔数组，所有重复项都会被标记为True。
dup_customer_id = df[df.duplicated("customer_id", keep=False)].sort_values("customer_id")
print("涉及重复 customer_id 的行数:", len(dup_customer_id))           # 0
print("重复的 customer_id 个数:", dup_customer_id["customer_id"].nunique())   # 0
print()

# 看重复 customer_id 是否对应不同 customer_unique_id
grouped = dup_customer_id.groupby("customer_id").agg(
    n_rows=("customer_unique_id", "size"),
    n_orders=("customer_unique_id", "nunique"),
    orders=("customer_unique_id", lambda x: list(x)),
)
print("重复 customer_id 的模式：")        # Empty DataFrame
print(grouped.head(20))
print()

# 情况 C：order_id 重复
dup_customer_unique_id = df[df.duplicated("customer_unique_id", keep=False)].sort_values("customer_unique_id")
print("涉及重复 customer_unique_id 的行数:", len(dup_customer_unique_id))                 # 6342
print("重复的 customer_unique_id 个数:", dup_customer_unique_id["customer_unique_id"].nunique())      # 2997
print()

# 检查 (review_id, order_id) 组合是否唯一
combo_dupes = df[df.duplicated(["customer_id", "customer_unique_id"], keep=False)]
print("(customer_id, customer_unique_id) 组合重复的行数:", len(combo_dupes))                       # 0
print("重复的组合数:", combo_dupes.groupby(["customer_id", "customer_unique_id"]).ngroups)        # 0
print()

# 保存明细供人工查看
dup_customer_unique_id.to_csv(PROCESSED_DIR / "olist_customers_dataset_dup_customer_unique_id_dup_detail.csv", index=False)
print("重复明细已保存到 data/processed/olist_customers_dataset_dup_customer_unique_id_dup_detail.csv")
