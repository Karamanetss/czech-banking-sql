--=======================
-- Credit Risk Analysis
--=======================

-- BUSINESS QUESTIONS:
-- 1. Overall default rate. What percentage of loans end in default?
-- 2. Default rate by loan duration.Do longer loans default more often?
-- 3. Default rate by loan amount. Do larger loans default more often?
-- 4. Vintage analysis. Which year has highest default rate?
-- 5. Default rate by region. Which regions have highest default rate?
-- 6. Regional risk vs unemployment. Correlation with unemployment?
-- 7. Top 10 highest risk accounts.
-- 8. Default rate by card type.

-- ============================================================
-- 1. Overall default rate.
-- ============================================================

SELECT 
    COUNT(*) AS total_loans,
    SUM(is_default) AS total_defaults,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loan_clean;

-- ============================================================
-- 2. Default rate by loan duration.
-- ============================================================

SELECT 
    duration,
    COUNT(*) AS total_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loan_clean
GROUP BY duration
ORDER BY duration DESC;

-- Finding: No significant correlation between loan duration and default rate.
-- Default rates are similar across all durations (11-12%). 
-- Exception: 12-month loans show slightly lower default rate (8.4%).


-- ============================================================
-- 3. Default rate by loan amount.
-- ============================================================

WITH loan_grouping AS (
    SELECT 
        is_default,
        CASE 
            WHEN amount < 50000 THEN '1. under 50k'
            WHEN amount < 100000 THEN '2. under 100k'
            WHEN amount < 200000 THEN '3. under 200k'
            ELSE '4. over 200k'
        END AS amount_group
    FROM loan_clean
)
SELECT 
    amount_group,
    COUNT(*) AS total_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loan_grouping
GROUP BY amount_group
ORDER BY amount_group;

-- Finding: Strong correlation between loan amount and default rate.
-- Loans over 200k default almost 5x more than loans under 50k (18.92% vs 3.97%).
-- High-value loans represent significantly higher credit risk.

-- ============================================================
-- 4. Vintage analysis.
-- ============================================================

SELECT 
	EXTRACT(YEAR FROM loan_date) as loan_year, 
	COUNT(*) as total_loans, 
	ROUND(AVG(is_default) * 100, 2) AS default_rate_pct FROM loan_clean
GROUP BY loan_year
ORDER BY loan_year;

-- Finding: Default rates stable at 13-14% for 1994-1997 cohorts.
-- 1993 anomaly due to small sample (20 loans only).
-- 1998 low default rate likely due to loans still being active (dataset ends 1998).

--==============================================================
-- 5. Default rate by region.
--==============================================================

SELECT 
	region, 
	COUNT(*) as total_loans, 
	ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loan_clean l
JOIN account a ON l.account_id = a.account_id
JOIN district d ON a.district_id = d.district_id
GROUP BY region
ORDER BY default_rate_pct;

-- Finding: Significant regional variation in default rates (1.64% to 15.79%).
-- West Bohemia, North Moravia and South Bohemia show highest default rates (15%+).
-- Prague and North Bohemia show lowest default rates (under 9%).
-- Hypothesis: regional economic conditions may explain differences, we will find it out in the next question Q6.

--==============================================================
-- 6. Regional risk vs unemployment.
--==============================================================

SELECT 
    region, 
    COUNT(*) AS total_loans, 
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct,
    ROUND(AVG(d.unemployment_96), 2) AS avg_unemployment,
    ROUND(AVG(d.avg_salary), 0) AS avg_salary
FROM loan_clean l
JOIN account a ON l.account_id = a.account_id
JOIN district d ON a.district_id = d.district_id
GROUP BY region
ORDER BY default_rate_pct DESC;

-- Finding: No clear correlation between unemployment/salary and default rate.
-- North Bohemia has highest unemployment (6.52%) but lowest default rate (1.64%).
-- West Bohemia has low unemployment (2.65%) but highest default rate (15.79%).
-- Regional default differences likely driven by other factors
-- (loan portfolio composition, local industry, bank branch policies etc.).

--==============================================================
-- 7. Debt-to-income ratio. Who is overloaded with debt?
--==============================================================

SELECT 
    account_id,
    amount,
    payments,
    duration,
    loan_status
FROM loan_clean
WHERE is_default = 1 AND loan_status = 'Running - Default'
ORDER BY amount DESC
LIMIT 10;

-- Finding: Top 10 highest risk accounts all have loans of 48-60 months duration.
-- Largest active default: account 2335 with 541,200 outstanding.
-- Total exposure in top 10: approx. 4.3M in active defaults.

--==============================================================
-- 8. Default rate by card type.
--==============================================================

-- 8a. Detailed: default rate per card type
SELECT 
    COALESCE(c.card_type, 'No card') AS card_type,
    COUNT(*) AS total_loans,
    ROUND(AVG(l.is_default) * 100, 2) AS default_rate_pct
FROM loan_clean l
JOIN account a ON l.account_id = a.account_id
JOIN disp d ON d.account_id = a.account_id
LEFT JOIN card c ON c.disp_id = d.disp_id
GROUP BY c.card_type
ORDER BY default_rate_pct DESC;

-- Finding: Clients without a card default far more often (10.81%) than card holders (2.26-6.25%).
-- Card ownership correlates with lower credit risk.
-- Note: gold (16) and junior (21) samples are too small for separate conclusions.
-- Majority of loans (657 of 827) belong to clients without a card.


-- 8b. Grouped: card holders vs non-holders
SELECT 
    CASE 
        WHEN c.card_id IS NULL THEN 'No card'
        ELSE 'Has card'
    END AS card_status,
    COUNT(*) AS total_loans,
    ROUND(AVG(l.is_default) * 100, 2) AS default_rate_pct
FROM loan_clean l
JOIN account a ON l.account_id = a.account_id
JOIN disp d ON d.account_id = a.account_id
LEFT JOIN card c ON c.disp_id = d.disp_id
GROUP BY card_status
ORDER BY default_rate_pct DESC;

-- Finding: Clients without a card default roughly 5x more often than card holders.
-- Card types grouped together due to small per-type samples (see 8a).
-- Likely reflects that cards are issued to already-reliable clients, not that
-- cards reduce risk. Correlation worth investigating, not a causal lever.
