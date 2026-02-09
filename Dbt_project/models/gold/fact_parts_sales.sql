{{ config(materialized='table') }}

SELECT
    sale_sk,                  -- PK da Fato
    work_order_sk,            -- FK para fact_work_order (ou dim_work_order se preferir)
    natural_sale_id as sale_id,
    sku,
    quantity,
    unit_price,
    total_price,
    sale_date
FROM {{ ref('silver_parts_sales') }}

