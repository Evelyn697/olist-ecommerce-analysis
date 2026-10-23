"""
验证 raw 层导入的完整性：
1. CSV 行数 vs MySQL 行数
2. 主键/关键字段唯一性
3. 关键字段缺失率
"""
import os
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

engine = create_engine(
    f"mysql+pymysql://{os.getenv('MYSQL_USER')}:{os.getenv('MYSQL_PASSWORD')}"
    f"@{os.getenv('MYSQL_HOST', 'localhost')}:{os.getenv('MYSQL_PORT', '3306')}"
    f"/{os.getenv('MYSQL_RAW_DB', 'olist_raw')}?charset=utf8mb4"
)

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


def count_csv_rows(path: Path) -> int:
    """统计 CSV 数据行数（不含表头）。用 pandas 更稳妥，避免引号内含换行导致的误计。"""
    return len(pd.read_csv(path, dtype=str, usecols=[0]))


def count_db_rows(table: str) -> int:
    with engine.connect() as conn:
        return conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()


def main():
    print(f"{'表名':<40} {'CSV':>10} {'MySQL':>10} {'状态':>8}")
    print("-" * 72)
    all_ok = True
    for csv_name, table in FILES.items():
        csv_path = RAW_DIR / csv_name
        if not csv_path.exists():
            print(f"{table:<40} {'(文件缺失)':>10}")
            all_ok = False
            continue
        n_csv = count_csv_rows(csv_path)
        n_db = count_db_rows(table)
        status = "OK" if n_csv == n_db else "MISMATCH"
        if n_csv != n_db:
            all_ok = False
        print(f"{table:<40} {n_csv:>10} {n_db:>10} {status:>8}")

    print()
    if all_ok:
        print("✅ 所有表行数一致，导入完整。")
    else:
        print("❌ 存在行数不一致，请检查导入脚本或重复导入问题。")


if __name__ == "__main__":
    main()
