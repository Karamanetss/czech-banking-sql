--=======================
-- Advanced SQL Analysis
--=======================

-- BUSINESS QUESTIONS:
-- 1. Account ranking by balance within each region. Who are the top clients per region?
-- 2. Account balance compared to regional average? 
-- 3. Month-over-month transaction growth. How fast is the bank growing each month?
-- 4. Loan ranking within each duration group. Which loans are largest in each category?
-- 5. Percentile rank of accounts by total balance. Where does each account stand?

-- ============================================================
-- 1. Account ranking by balance within each region. Who are the top client
-- ============================================================


WITH account_balance AS (
	SELECT 
		t.account_id, 
		ROUND(AVG(t.balance), 2) avg_balance, 
		c.region 
	FROM trans t
	JOIN account a ON t.account_id = a.account_id 
	JOIN client_clean c ON c.district_id = a.district_id
	GROUP BY t.account_id, c.region
) 
SELECT * FROM (
    SELECT 
        account_id,
        avg_balance,
        region,
        RANK() OVER (PARTITION BY region ORDER BY avg_balance DESC) AS region_rank
    FROM account_balance
) AS ranked
WHERE region_rank <= 10;

-- Finding: This query finds the top 10 accounts with the highest average balance
-- in each region, using RANK(). 
-- The top balances are similar across all regions (between 68k and 81k),
-- so no single region clearly has wealthier clients than the others.

-- ============================================================
-- 2. Account balance compared to regional average? 
-- ============================================================

WITH account_balance AS (
	SELECT 
		t.account_id, 
		ROUND(AVG(t.balance), 2) avg_balance, 
		c.region 
	FROM trans t
	JOIN account a ON t.account_id = a.account_id 
	JOIN client_clean c ON c.district_id = a.district_id
	GROUP BY t.account_id, c.region
) 
SELECT 
	account_id,
    region,
    avg_balance,
	ROUND(AVG(avg_balance) OVER (PARTITION BY region), 2) AS region_avg,
	ROUND(avg_balance - AVG(avg_balance) OVER (PARTITION BY region), 2) AS diff
FROM account_balance;

-- Finding: This query compares each account's balance to the average in its region
-- The results show that balances vary widely within every region
-- some accounts sit far above their regional average, others far below.
-- This helps the bank identify its wealthiest and poorest clients
-- relative to their local market, not just overall.

-- ============================================================
-- 3. Month-over-month transaction growth. How fast is the bank growing each month?
-- ============================================================

WITH monthly AS (
    SELECT 
        DATE_TRUNC('month', TO_DATE(date_raw, 'YYMMDD'))::DATE AS trans_month,
        SUM(amount) AS total_volume
    FROM trans
    GROUP BY trans_month
) 
SELECT 
    trans_month,
    total_volume,
    LAG(total_volume) OVER (ORDER BY trans_month) AS prev_volume,
    ROUND(
        (total_volume - LAG(total_volume) OVER (ORDER BY trans_month)) * 100.0 / 
        LAG(total_volume) OVER (ORDER BY trans_month),
        2
    ) AS growth_pct
FROM monthly
ORDER BY trans_month;

-- Finding: Transaction volume shows strong seasonal patterns repeating every year.
-- June and December consistently spike (+28% to +43%), 
-- while February and July consistently drop (-23% to -33%).
-- These regular cycles likely reflect semi-annual payments (June/December)
-- and post-peak corrections (February/July).
-- The pattern is highly predictable, useful for forecasting and cash planning.

-- ============================================================
-- 4. Loan ranking within each duration group. Which loans are largest in each category?
-- ============================================================

SELECT * FROM (
    SELECT 
        loan_id,
        duration,
        amount,
        RANK() OVER (PARTITION BY duration ORDER BY amount DESC) AS rank_in_duration
    FROM loan_clean
) AS ranked
WHERE rank_in_duration <= 3;

-- Finding: As expected, larger loans come with longer terms —
-- maximum amounts grow from 116k (12 months) to 590k (60 months).

-- ============================================================
-- 5. Percentile rank of accounts by total balance. Where does each account stand?
-- ============================================================

WITH account_balance AS (
    SELECT 
        account_id,
        ROUND(AVG(balance), 2) AS avg_balance
    FROM trans
    GROUP BY account_id
)
SELECT 
    account_id,
    avg_balance,
    ROUND(PERCENT_RANK() OVER (ORDER BY avg_balance)::NUMERIC, 4) AS percentile
FROM account_balance
ORDER BY avg_balance DESC
LIMIT 100;

-- Finding: This query gives each account a percentile rank by average balance,
-- showing where it stands among all accounts.
-- Account 8212 is right at the top (percentile 1.0) with the highest balance.
-- Percentiles are easier to read than raw numbers,
-- the bank can instantly see which accounts are in the top 1%, top 10%, or at the bottom.
-- This is useful for offering different service levels to different client tiers.
