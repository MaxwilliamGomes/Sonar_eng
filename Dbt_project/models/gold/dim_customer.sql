{{ config(materialized='table') }}

WITH source_data AS (
    SELECT * FROM {{ source('public', 'customers') }}
),

versioned_customers AS (
    SELECT
        MD5(UPPER(TRIM(CAST(customer_id AS VARCHAR))) || '-' || CAST(created_at AS VARCHAR)) as customer_sk,
        customer_id as natural_customer_id,
        REPLACE(customer_name, ' (Atualizado)', '') as customer_name,
        COALESCE(segment, 'UNKNOWN') as segment,
        COALESCE(state, 'ND') as state,
        CAST(created_at AS TIMESTAMP) as valid_from,
        LEAD(CAST(created_at AS TIMESTAMP)) OVER (
            PARTITION BY customer_id 
            ORDER BY created_at ASC
        ) as valid_to
    FROM source_data
),

-- Criamos o registro "Fantasma" para linkar os órfãos
orphans AS (
    SELECT
        MD5('ORPHAN') as customer_sk,
        'ORPHAN' as natural_customer_id,
        'Nao Identificado' as customer_name,
        'UNKNOWN' as segment,
        'ND' as state,
        '1900-01-01'::timestamp as valid_from,
        NULL::timestamp as valid_to
)

SELECT
    *,
    CASE WHEN valid_to IS NULL THEN TRUE ELSE FALSE END as is_current
FROM versioned_customers

UNION ALL

SELECT
    *,
    TRUE as is_current
FROM orphans