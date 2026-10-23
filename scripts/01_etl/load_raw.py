"""
将 Olist 原始 CSV 导入 MySQL 的 olist_raw 库。
前提：已执行 sql/01_raw/02_create_raw_tables.sql 建好所有表。
"""
import os
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# ---------- 1. 读取配置 ----------
load_dotenv()

DB_USER = os.getenv("MYSQL_USER", "root")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
DB_HOST = os.getenv("MYSQL_HOST", "127.0.0.1")
DB_PORT = os.getenv("MYSQL_PORT", "3306")
DB_NAME = os.getenv("MYSQL_RAW_DB", "olist_raw")

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4",
    echo=False,
)

# ---------- 2. 定义 CSV → 表名映射 ----------
BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DIR = BASE_DIR / "data" / "raw"

FILES = {
    "olist_customers_dataset.csv": "customers",
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "olist_geolocation_dataset.csv": "geolocation",
    "product_category_name_translation.csv": "product_category_name_translation",
}

# ---------- 3. 日期列（导入前转换，避免 MySQL 报错） ----------
DATE_COLS = {
    "orders": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "order_items": ["shipping_limit_date"],
    "order_reviews": ["review_creation_date", "review_answer_timestamp"],
}


def load_one(csv_name: str, table_name: str) -> None:
    csv_path = RAW_DIR / csv_name
    if not csv_path.exists():
        print(f"[跳过] 文件不存在: {csv_path}")
        return

    print(f"[读取] {csv_name} ...")
    # na_values：要识别为NA/NaN的其他字符串；
    # keep_default_na：解析数据时是否包括默认的NaN值。根据是否传入na_values，行为如下：
    # 如果keep_default_na为True，并且指定了na_value，则将na_value附加到用于解析的默认NaN值。
    # 如果keep_default_na为True，并且未指定na_value，则仅使用默认的NaN值进行解析。
    # 如果keep_default_na为False，并且指定了na_value，则仅使用指定的NaN值na_value进行解析。
    # 如果keep_default_na为False，并且未指定na_value，则不会将任何字符串解析为NaN。
    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False, na_values=[""])

    # 日期列转换为 datetime
    for col in DATE_COLS.get(table_name, []):
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    # 空字符串统一为 None，让 MySQL 存 NULL
    df = df.where(pd.notnull(df), None)

    print(f"[写入] {table_name} ({len(df)} 行) ...")
    df.to_sql(
        name=table_name,
        con=engine,
        if_exists="append",   # 表已建好，追加数据
        index=False,
        chunksize=5000       # 分批写入，避免内存爆
    )
    print(f"[完成] {table_name}\n")


def main():
    # 先清空已有数据（重复跑脚本时避免主键冲突）
    with engine.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))
        for table in FILES.values():
            conn.execute(text(f"TRUNCATE TABLE {table};"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))

    for csv_name, table_name in FILES.items():
        load_one(csv_name, table_name)

    print("全部导入完成。")


if __name__ == "__main__":
    main()
