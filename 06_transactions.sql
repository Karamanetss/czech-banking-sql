
--=======================
-- Transaction Analysis
--=======================

-- BUSINESS QUESTIONS:
-- 1. Monthly cash flow. How do inflows (PRIJEM) and outflows (VYDAJ) evolve over time?
-- 2. Seasonality. Which months have the highest transaction volume?
-- 3. Monthly active accounts over time. How many unique accounts were active each month?
-- 4. Running balance per account. How does balance accumulate over time?
-- 5. Anomaly detection. Which transactions exceed mean + 2 standard deviations?
-- 6. Deposit-to-withdrawal ratio. Which accounts spend more than they receive?

-- ============================================================
-- 1. Monthly cash flow.
-- ============================================================

SELECT *, total_in - total_out AS net_flow FROM ( 
	SELECT 
		DATE_TRUNC('month', TO_DATE(date_raw, 'YYMMDD'))::DATE AS month_trans, 
		SUM(amount) FILTER (WHERE trans_type = 'PRIJEM') AS total_in,
		SUM(amount) FILTER (WHERE trans_type = 'VYDAJ') AS total_out
	FROM trans
	GROUP BY month_trans
) AS monthly_flow;

-- Finding: Transaction volume grew consistently from 1993 to 1998.
-- January shows negative net flow every year, likely large loan disbursements or standing order payments processed at year start.
-- December and June consistently show highest total volume, possible bonus or seasonal effect.

-- ============================================================
-- 2. Seasonality. Which months have the highest transaction volume?
-- ============================================================

SELECT EXTRACT(MONTH from month_trans) AS extracted_month, ROUND(AVG(total_in - total_out), 1) AS avg_net FROM ( 
	SELECT 
		DATE_TRUNC('month', TO_DATE(date_raw, 'YYMMDD'))::DATE AS month_trans, 
		SUM(amount) FILTER (WHERE trans_type = 'PRIJEM') AS total_in,
		SUM(amount) FILTER (WHERE trans_type = 'VYDAJ') AS total_out
	FROM trans
	GROUP BY month_trans
) AS monthly_flow
GROUP BY extracted_month
ORDER BY avg_net DESC;

-- Finding: January and June consistently show negative net flow.
-- January likely driven by large loan disbursements or standing orders at year start.
-- June dip possibly related to summer vacation spending patterns.
-- February and December show strongest positive net flow February likely reflects post-holiday recovery, 
--December may reflect year-end bonuses.
-- Note: these are hypotheses based on patterns, exact causes would require additional data.

-- ============================================================
-- 3. Monthly active accounts over time. 
-- ============================================================

SELECT 
	DATE_TRUNC('month', TO_DATE(date_raw, 'YYMMDD'))::DATE AS month_trans, 
	COUNT(DISTINCT account_id) AS active_accounts 
FROM trans
GROUP BY month_trans;

-- Finding: The number of active accounts grew steadily from 96 in January 1993
-- to about 4,480 by the end of 1997. After that the growth stopped and stayed
-- flat around 4,480,the customer base reached its limit.
-- This means the bank should shift focus from attracting new clients
-- to keeping and developing the existing ones.

-- ============================================================
-- 4. Balance volatility per account. Which accounts have the most unstable balance over time?
-- ============================================================

SELECT 
	account_id, ROUND(AVG(balance), 2) AS avg_balance, 
	ROUND(STDDEV(balance), 2) AS stdv_balance, 
	COUNT(*) AS transaction_count
FROM trans
GROUP BY account_id 
ORDER BY stdv_balance DESC;

-- -- Finding: Balance stability varies a lot between accounts.
-- The most stable accounts keep their balance almost flat, around 2,000 deviation on a 14,000 average balance.
-- The most volatile accounts swing heavily, around 37,000 deviation on a 57,000 average balance.
-- Accounts with high volatility have unpredictable cash flow
-- and could be monitored more closely when making credit decisions.

-- ============================================================
-- 5. Anomaly detection. Which transactions exceed mean + 2 standard deviations?
-- ============================================================

SELECT 
    t.account_id,
    TO_DATE(t.date_raw, 'YYMMDD') AS trans_date,
    t.amount,
    stats.avg_amount,
    stats.threshold
FROM trans t
JOIN (
    SELECT 
        account_id,
        ROUND(AVG(amount), 2) AS avg_amount,
        ROUND(AVG(amount) + 2 * STDDEV(amount), 2) AS threshold
    FROM trans
    GROUP BY account_id
) AS stats ON t.account_id = stats.account_id
WHERE t.amount > stats.threshold
ORDER BY t.amount DESC;

-- Finding: Many anomalies are actually recurring large payments.
-- Account 4514 for example shows a regular 73,800 transaction every June and December1994-1998),
-- account 11079 and 472 show similar patterns etc..
-- These are not fraud but predictable semi-annual obligations 
-- (likely insurance, loan repayments, or rent).

-- ============================================================
-- 6. Deposit-to-withdrawal ratio. Which accounts spend more than they receive?
-- ============================================================

SELECT 
    account_id,
    SUM(amount) FILTER (WHERE trans_type = 'PRIJEM') AS total_in,
    SUM(amount) FILTER (WHERE trans_type = 'VYDAJ') AS total_out,
    ROUND(
        SUM(amount) FILTER (WHERE trans_type = 'PRIJEM') / 
        SUM(amount) FILTER (WHERE trans_type = 'VYDAJ'),
        2
    ) AS in_out_ratio
FROM trans
GROUP BY account_id
ORDER BY in_out_ratio ASC;

-- Finding: Most accounts receive more money than they spend (ratio above 1.0).
-- Account 2892 is the most extreme saver, receives 28 times more than it withdraws.
-- A small group of accounts spends more than it receives (ratio below 1.0).
-- Account 4059 is the most at risk with ratio 0.80, spending 20% more than it earns.
-- These accounts should be watched closely as they may struggle with future payments.
