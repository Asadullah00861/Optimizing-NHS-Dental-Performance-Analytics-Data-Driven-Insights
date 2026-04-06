-- ========================================
-- NHS UDA Project Analysis Script
-- ========================================

-- ========================================
-- Q1. Overall performance rate of NHS dental contractors by region
-- ========================================
SELECT 
    commissioner_name,
    SUM(uda_delivered) / NULLIF(SUM(uda_perf_target),0) * 100 AS performance_pct
FROM uda_contractor_raw
GROUP BY commissioner_name
ORDER BY performance_pct DESC;

-- ========================================
-- Q2. Regions with highest and lowest average performance (2025)
-- ========================================

-- Highest performing region
SELECT 
    commissioner_name,
    ROUND(SUM(uda_delivered) / NULLIF(SUM(uda_perf_target),0) * 100, 2) AS performance_pct
FROM uda_contractor_raw
WHERE EXTRACT(YEAR FROM year_month) = 2025
  AND uda_perf_target > 0
GROUP BY commissioner_name
ORDER BY performance_pct DESC
LIMIT 1;

-- Lowest performing region
SELECT 
    commissioner_name,
    ROUND(SUM(uda_delivered) / NULLIF(SUM(uda_perf_target),0) * 100, 2) AS performance_pct
FROM uda_contractor_raw
WHERE EXTRACT(YEAR FROM year_month) = 2025
  AND uda_perf_target > 0
GROUP BY commissioner_name
ORDER BY performance_pct ASC
LIMIT 1;

-- ========================================
-- Q3. Top 10 performing dental providers by performance %
-- ========================================
SELECT 
    provider_name,
    ROUND(SUM(uda_delivered)::NUMERIC / NULLIF(SUM(uda_perf_target),0) * 100, 2) AS performance_pct
FROM uda_contractor_raw
GROUP BY provider_name
HAVING SUM(uda_perf_target) > 0
ORDER BY performance_pct DESC
LIMIT 10;

-- ========================================
-- Q4. Percentage of providers underperforming (performance < 50%)
-- ========================================
WITH provider_perf AS (
    SELECT 
        provider_name,
        SUM(uda_delivered) / NULLIF(SUM(uda_perf_target),0) * 100 AS performance_pct
    FROM uda_contractor_raw
    GROUP BY provider_name
)
SELECT 
    ROUND(
        COUNT(*) FILTER (WHERE performance_pct < 50)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS underperforming_pct
FROM provider_perf;

-- ========================================
-- Q5. Top 5 regions delivering the highest total UDAs
-- ========================================
SELECT 
    commissioner_name,
    SUM(uda_delivered) AS total_udas
FROM uda_contractor_raw
GROUP BY commissioner_name
ORDER BY total_udas DESC
LIMIT 5;

-- ========================================
-- Q6. Top 5 providers generating highest revenue (UDA_FIN_VAL) per UDA
-- ========================================
SELECT 
    provider_name,
    SUM(uda_fin_val) AS total_financial_value,
    SUM(uda_delivered) AS total_udas,
    ROUND(SUM(uda_fin_val) / NULLIF(SUM(uda_delivered),0), 2) AS value_per_uda
FROM uda_contractor_raw
GROUP BY provider_name
ORDER BY value_per_uda DESC
LIMIT 5;

-- ========================================
-- Q7. Distribution of treatment types (Band 1, Band 2, Band 3)
-- ========================================
WITH treatment_totals AS (
    SELECT
        SUM(band_1_delivered) AS band_1,
        SUM(band_2a_delivered + band_2b_delivered + band_2c_delivered) AS band_2,
        SUM(band_3_delivered) AS band_3
    FROM uda_contractor_raw
)
SELECT
    'Band 1' AS band_type,
    band_1 AS total_delivered,
    ROUND(band_1 * 100.0 / (band_1 + band_2 + band_3), 2) AS pct
FROM treatment_totals
UNION ALL
SELECT
    'Band 2' AS band_type,
    band_2 AS total_delivered,
    ROUND(band_2 * 100.0 / (band_1 + band_2 + band_3), 2) AS pct
FROM treatment_totals
UNION ALL
SELECT
    'Band 3' AS band_type,
    band_3 AS total_delivered,
    ROUND(band_3 * 100.0 / (band_1 + band_2 + band_3), 2) AS pct
FROM treatment_totals;

-- ========================================
-- Q8. Provider productivity: UDAs per patient
-- ========================================
SELECT 
    provider_name,
    SUM(uda_delivered) AS total_udas,
    SUM(child_12m_count + adult_24m_count) AS total_patients,
    ROUND(SUM(uda_delivered) / NULLIF(SUM(child_12m_count + adult_24m_count),0), 2) AS uda_per_patient
FROM uda_contractor_raw
GROUP BY provider_name
ORDER BY uda_per_patient DESC
LIMIT 10;

-- ========================================
-- Q9. Top providers delivering most UDAs per patient while maintaining high performance (>=80%), with Band breakdown
-- ========================================
WITH provider_stats AS (
    SELECT
        provider_name,
        SUM(uda_delivered) AS total_udas,
        SUM(child_12m_count + adult_24m_count) AS total_patients,
        SUM(uda_delivered) / NULLIF(SUM(child_12m_count + adult_24m_count),0) AS uda_per_patient,
        ROUND(SUM(uda_delivered) / NULLIF(SUM(uda_perf_target),0) * 100, 2) AS performance_pct,
        SUM(band_1_delivered) AS band_1,
        SUM(band_2a_delivered + band_2b_delivered + band_2c_delivered) AS band_2,
        SUM(band_3_delivered) AS band_3
    FROM uda_contractor_raw
    GROUP BY provider_name
)
SELECT *
FROM provider_stats
WHERE performance_pct >= 80
ORDER BY uda_per_patient DESC
LIMIT 10;
