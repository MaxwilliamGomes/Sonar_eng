{{ config(materialized='table') }}

SELECT
    customer_sk,              -- PK da Dimensão
    natural_customer_id as customer_id,
    customer_name,
    segment,
    state,
    valid_from,
    valid_to,
    is_current                -- Flag para o BI filtrar apenas o estado atual, se desejar
FROM {{ ref('silver_customers') }}