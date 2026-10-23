-- 查看当前已有库
show databases;
-- 创建olist_raw层，存放原始数据
create database if not exists olist_raw
	default character set utf8mb4
    default collate utf8mb4_unicode_520_ci;
-- 创建olist_analytics层，存放清洗后的数据
create database if not exists olist_analytics
	default character set utf8mb4
    default collate utf8mb4_unicode_520_ci;
show databases;