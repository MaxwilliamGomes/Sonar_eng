{{ config(materialized='table') }}

SELECT
    work_order_sk,            -- PK da Fato
    customer_sk,              -- FK para dim_customer (SK, não ID natural)
    natural_work_order_id as work_order_id,
    order_date,
    status,
    labor_hours,
    labor_cost
FROM {{ ref('silver_work_orders') }}