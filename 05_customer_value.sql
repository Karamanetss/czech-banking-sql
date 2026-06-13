--=======================
-- Customer Value Analysis
--=======================

-- BUSINESS QUESTIONS:
-- 1. Client distribution by region. Which regions have the most clients?
-- 2. Gender and age distribution. What is the demographic profile of clients?
-- 3. RFM segmentation. Who are the most valuable clients?
-- 4. Customer segments. Champions, At Risk, Lost, how is portfolio distributed?
-- 5. Cross-sell targets. Which clients have no card but active account?
-- 6. Dormant accounts. Which accounts have been inactive the longest?
-- 7. Top 10% clients by transaction volume. Who drives the most revenue?
-- 8. Revenue concentration. What share of total volume comes from the top 10% of accounts?

-- ============================================================
-- 1. Client distribution by region.
-- ============================================================

SELECT 
    region,
    COUNT(*) AS total_clients
FROM client_clean
GROUP BY region
ORDER BY total_clients DESC;

-- Finding: South Moravia has the highest number of clients (937), followed closely by North Moravia (920).
-- Surprisingly, Prague ranks only 4th despite being the capital city,
-- suggesting the bank has stronger presence in rural regions.

-- ============================================================
-- 2. Gender and age distribution.
-- ============================================================

-- 2a. Gender distribution

SELECT 
    gender,
    COUNT(*) AS total_clients,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM client_clean
GROUP BY gender;

-- 2b. Age distribution

SELECT 
	MIN(date_part('year', AGE('1998-12-31'::DATE, birth_date))) as min_age,
	MAX(date_part('year', AGE('1998-12-31'::DATE, birth_date))) as max_age, 
	ROUND(AVG(date_part('year', AGE('1998-12-31'::DATE, birth_date)))::NUMERIC, 1) AS avg_age
FROM client_clean;

-- Finding: Client base is slightly male dominated (50.74% male vs 49.26% female).
-- Average client age is 44.8 years as of 1998.
-- Youngest client is 11 years old, likely accounts opened by parents for children.

-- ============================================================
-- 3. RFM segmentation. Who are the most valuable clients?
-- ============================================================

WITH rfm_base AS (
    SELECT 
        account_id,
        '1998-12-31'::DATE - MAX(TO_DATE(date_raw, 'YYMMDD')) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary
    FROM trans
    GROUP BY account_id
),
rfm_scores AS (
    SELECT 
        account_id,
        recency_days,
        frequency,
        monetary,
        CASE 
            WHEN recency_days = 0 THEN 4
            WHEN recency_days <= 30 THEN 3
            WHEN recency_days <= 90 THEN 2
            ELSE 1
        END AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
)
SELECT 
    account_id,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE 
        WHEN (r_score + f_score + m_score) = 12 THEN 'Champion'
		WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal'
		WHEN (r_score + f_score + m_score) >= 7  THEN 'Regular'
		WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk'
		ELSE 'Lost'
    END AS segment
FROM rfm_scores
ORDER BY rfm_total DESC;

-- ============================================================
--4. Customer segments. Champions, At Risk, Lost, how is portfolio distributed?
-- ============================================================

WITH rfm_base AS (
    SELECT 
        account_id,
        '1998-12-31'::DATE - MAX(TO_DATE(date_raw, 'YYMMDD')) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary
    FROM trans
    GROUP BY account_id
),
rfm_scores AS (
    SELECT 
        account_id,
        recency_days,
        frequency,
        monetary,
        CASE 
            WHEN recency_days = 0 THEN 4
            WHEN recency_days <= 30 THEN 3
            WHEN recency_days <= 90 THEN 2
            ELSE 1
        END AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT 
	    account_id,
	    r_score,
	    f_score,
	    m_score,
	    (r_score + f_score + m_score) AS rfm_total,
    CASE 
        WHEN (r_score + f_score + m_score) = 12 THEN 'Champion'
		WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal'
		WHEN (r_score + f_score + m_score) >= 7  THEN 'Regular'
		WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk'
		ELSE 'Lost'
    END AS segment
FROM rfm_scores
)
SELECT 
    segment,
    COUNT(*) AS total_clients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM rfm_segments
GROUP BY segment
ORDER BY total_clients DESC;

-- Finding: The customer base is well-distributed across value segments.
-- Champions (11.84%) represent the bank's most valuable clients - high frequency,
-- high monetary value, recently active. These should be prioritized for retention.
-- Nearly half are Regular clients (44.96%)- the main target for upselling.
-- At Risk segment (14.62%) needs re-engagement before they churn.

-- ============================================================
-- 5. Cross-sell targets. Which clients have no card but active account?
-- ============================================================
SELECT 
    c.client_id,
    d.account_id,
    c.region,
    c.gender,
    COUNT(*) OVER() AS total_without_card
FROM client_clean c
JOIN disp d ON c.client_id = d.client_id
LEFT JOIN card ON d.disp_id = card.disp_id 
WHERE card.card_id IS NULL

-- Finding: 4,477 out of 5,369 clients (83%) do not have a credit card.
-- This represents a significant cross-sell opportunity for the bank

-- ============================================================
-- 6. Dormant accounts. Which accounts have been inactive the longest?
-- ============================================================
SELECT 
    account_id, 
    MAX(TO_DATE(date_raw, 'YYMMDD')) AS last_transaction,
    '1998-12-31'::DATE - MAX(TO_DATE(date_raw, 'YYMMDD')) AS days_inactive
FROM trans 
GROUP BY account_id
ORDER BY days_inactive DESC
LIMIT 10;

-- Finding: Top 10 most dormant accounts have been inactive for 334-858 days.
-- Account 799 has not had any transactions since August 1996 (858 days inactive).
-- These accounts represent potential churn risk and could benefit from
-- re-engagement campaigns to reactivate dormant clients.

-- ============================================================
-- 7. Top 10% clients by transaction volume. Who drives the most revenue?
-- ============================================================
SELECT * FROM (
	SELECT 
	    account_id,
	    SUM(amount) AS total_volume,
	    NTILE(10) OVER (ORDER BY SUM(amount) DESC) AS decile
	FROM trans
	GROUP BY account_id
) AS trans_rank
WHERE decile = 1
ORDER BY total_volume DESC;

-- Finding: Top 10% clients (450 accounts) generate significantly higher transaction volumes.
-- The most active account processed over 7.6M in total volume over 5 years.
-- These clients represent the bank's most valuable segment and should be prioritized for retention and premium service offerings.

-- ============================================================
-- 8. Revenue concentration. What share of total volume comes from the top 10% of accounts?
-- ============================================================

SELECT 
    ROUND(
        SUM(total_volume) FILTER (WHERE decile = 1) * 100.0 / SUM(total_volume),
        2
    ) AS top10_pct_share
FROM (
    SELECT 
        account_id,
        SUM(amount) AS total_volume,
        NTILE(10) OVER (ORDER BY SUM(amount) DESC) AS decile
    FROM trans
    GROUP BY account_id
) AS ranked;

-- Finding: Top 10% of accounts generate 32.11% of total transaction volume.
-- Concentration is moderate, lower than typical Pareto 80/20 distribution.
-- This suggests a relatively balanced client base without extreme dependency
-- on a small group of high-volume accounts.
