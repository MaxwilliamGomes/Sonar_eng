{{ config(materialized='table') }}

WITH source_data AS (
    SELECT * FROM {{ source('public', 'customers') }}
),

versioned_data AS (
    SELECT
        
        MD5(UPPER(TRIM(CAST(customer_id AS VARCHAR))) || '-' || CAST(created_at AS VARCHAR)) as customer_sk,
        customer_id as natural_customer_id,
        REPLACE(customer_name, ' (Atualizado)', '') as customer_name,
        COALESCE(segment, 'UNKNOWN') as segment,
        COALESCE(state, 'ND') as state,
        CAST(created_at AS DATE) as valid_from,
        
        -- Calcula o fim da validade usando a data do próximo registro
        LEAD(CAST(created_at AS DATE)) OVER (
            PARTITION BY customer_id 
            ORDER BY created_at ASC
        ) as valid_to
    FROM source_data
)

SELECT
    *,
    -- Flag para facilitar a identificação do registro atual no BI
    CASE WHEN valid_to IS NULL THEN TRUE ELSE FALSE END as is_current
FROM versioned_data