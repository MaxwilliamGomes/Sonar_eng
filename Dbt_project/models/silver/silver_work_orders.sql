{{ config(materialized='table') }}

WITH wo_source AS (
    SELECT * FROM {{ source('public', 'work_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('silver_customers') }}
),

versioned_wo AS (
    SELECT
        -- SK única para cada versão da Ordem de Serviço
        MD5(UPPER(TRIM(CAST(wo.work_order_id AS VARCHAR))) || '-' || CAST(wo.updated_at AS VARCHAR)) as work_order_sk,
        wo.work_order_id as natural_work_order_id,
        
        -- Busca a SK do cliente vigente na data da ordem (Point-in-Time Join)
        COALESCE(c.customer_sk, MD5('ORPHAN')) as customer_sk,
        
        CAST(wo.order_date AS DATE) as order_date,
        wo.status,
        CAST(wo.labor_hours AS FLOAT) as labor_hours,
        CAST(wo.labor_cost AS NUMERIC) as labor_cost,
        CAST(wo.updated_at AS TIMESTAMP) as valid_from,
        LEAD(CAST(wo.updated_at AS TIMESTAMP)) OVER (
            PARTITION BY wo.work_order_id 
            ORDER BY wo.updated_at ASC
        ) as valid_to
    FROM wo_source wo
    LEFT JOIN customers c
        ON wo.customer_id = c.natural_customer_id
        AND CAST(wo.order_date AS TIMESTAMP) >= c.valid_from 
        AND (CAST(wo.order_date AS TIMESTAMP) < c.valid_to OR c.valid_to IS NULL)
)

SELECT * FROM versioned_wo

