{{ config(materialized='table') }}

WITH date_series AS (
    -- Gera uma série de datas de 2024 até 2026
    SELECT CAST(date_column AS DATE) as date_day
    FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2026-12-31')) as date_column
)

SELECT
    date_day as date_pk,
    EXTRACT(YEAR FROM date_day) as year,
    EXTRACT(MONTH FROM date_day) as month,
    EXTRACT(DAY FROM date_day) as day,
    FORMAT_DATE('%Y-%m', date_day) as year_month,
    EXTRACT(QUARTER FROM date_day) as quarter,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN TRUE ELSE FALSE END as is_weekend
FROM date_series