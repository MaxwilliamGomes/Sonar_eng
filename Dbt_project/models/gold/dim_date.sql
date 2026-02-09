{{ config(materialized='table') }}

WITH date_series AS (
    -- Gera uma série de datas para PostgreSQL
    SELECT CAST(d AS DATE) as date_day
    FROM generate_series(
        '2024-01-01'::timestamp,
        '2026-12-31'::timestamp,
        '1 day'::interval
    ) as d
)

SELECT
    date_day as date_pk,
    EXTRACT(YEAR FROM date_day) as year,
    EXTRACT(MONTH FROM date_day) as month,
    EXTRACT(DAY FROM date_day) as day,
    -- No Postgres usamos TO_CHAR em vez de FORMAT_DATE
    TO_CHAR(date_day, 'YYYY-MM') as year_month,
    EXTRACT(QUARTER FROM date_day) as quarter,
    -- No Postgres, DOW (Day of Week) retorna 0 para Domingo e 6 para Sábado
    CASE WHEN EXTRACT(DOW FROM date_day) IN (0, 6) THEN TRUE ELSE FALSE END as is_weekend
FROM date_series