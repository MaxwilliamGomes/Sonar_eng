{{ config(materialized='table') }}

WITH sales_source AS (
    SELECT * FROM {{ source('public', 'parts_sales') }}
),

work_orders AS (
    SELECT * FROM {{ ref('silver_work_orders') }}
)

SELECT
    -- SK única da venda
    MD5(UPPER(TRIM(CAST(s.sale_id AS VARCHAR))) || '-' || CAST(s.updated_at AS VARCHAR)) as sale_sk,
    s.sale_id as natural_sale_id,

    -- Busca a SK da Work Order vigente no momento da venda (Point-in-Time Join)
    COALESCE(wo.work_order_sk, MD5('ORPHAN')) as work_order_sk,
    
    s.sku,
    CAST(s.quantity AS INT) as quantity,
    CAST(s.unit_price AS NUMERIC) as unit_price,
    ROUND(CAST(s.quantity * s.unit_price AS NUMERIC), 2) as total_price,
    CAST(s.sale_date AS DATE) as sale_date,
    CAST(s.updated_at AS TIMESTAMP) as updated_at
FROM sales_source s
LEFT JOIN work_orders wo
    ON s.work_order_id = wo.natural_work_order_id
    AND CAST(s.sale_date AS TIMESTAMP) >= wo.valid_from 
    AND (CAST(s.sale_date AS TIMESTAMP) < wo.valid_to OR wo.valid_to IS NULL)


