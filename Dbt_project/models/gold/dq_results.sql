{{ config(materialized='table', schema='gold') }}

WITH metrics AS (
    -- 1. Taxa de Nulos Críticos em dim_customer
    SELECT 
        'taxa_nulos_criticos' as check_name,
        'dim_customer' as table_name,
        CAST(COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS FLOAT) / NULLIF(COUNT(*), 0) as metric_value,
        0.005 as threshold
    FROM {{ ref('dim_customer') }}

    UNION ALL

    -- 2. Taxa de Duplicidade por Chave em fact_work_order (SCD2 deve ter SK única)
    SELECT 
        'taxa_duplicidade' as check_name,
        'fact_work_order' as table_name,
        1 - (CAST(COUNT(DISTINCT work_order_sk) AS FLOAT) / NULLIF(COUNT(*), 0)) as metric_value,
        0.001 as threshold
    FROM {{ ref('fact_work_order') }}

    UNION ALL

    -- 3. Taxa de Órfãos em fact_parts_sales
    SELECT 
        'taxa_orfaos' as check_name,
        'fact_parts_sales' as table_name,
        CAST(COUNT(CASE WHEN work_order_sk = MD5('ORPHAN') THEN 1 END) AS FLOAT) / NULLIF(COUNT(*), 0) as metric_value,
        0.002 as threshold
    FROM {{ ref('fact_parts_sales') }}
)

SELECT 
    check_name,
    table_name,
    ROUND(CAST(metric_value AS NUMERIC), 4) as metric_value,
    threshold,
    CASE WHEN metric_value <= threshold THEN 'PASS' ELSE 'FAIL' END as status,
    CASE 
        WHEN check_name = 'taxa_nulos_criticos' THEN 'Percentual de customer_id nulos'
        WHEN check_name = 'taxa_duplicidade' THEN 'Percentual de SKs duplicadas'
        WHEN check_name = 'taxa_orfaos' THEN 'Vendas vinculadas a chaves ORPHAN'
    END as details
FROM metrics