-- Data prep

-- 1. NULL CHECKS

-- account
SELECT * FROM account
WHERE account_id IS NULL
    OR district_id IS NULL
    OR frequency IS NULL
    OR date_raw IS NULL;

-- client
SELECT * FROM client
WHERE client_id IS NULL
    OR birth_number IS NULL
    OR district_id IS NULL;

-- disp
SELECT * FROM disp
WHERE disp_id IS NULL
    OR client_id IS NULL
    OR account_id IS NULL
    OR disp_type IS NULL;

-- card
SELECT * FROM card
WHERE card_id IS NULL
    OR disp_id IS NULL
    OR card_type IS NULL
    OR issued IS NULL;

-- loan
SELECT * FROM loan
WHERE loan_id IS NULL
    OR account_id IS NULL
    OR date_raw IS NULL
    OR amount IS NULL
    OR duration IS NULL
    OR payments IS NULL
    OR status IS NULL;

-- order
SELECT * FROM "order"
WHERE order_id IS NULL
    OR account_id IS NULL
    OR bank_to IS NULL
    OR account_to IS NULL
    OR amount IS NULL
    OR k_symbol IS NULL;

-- district
SELECT * FROM district
WHERE district_id IS NULL
    OR district_name IS NULL
    OR region IS NULL
    OR population IS NULL
    OR municipalities_under_499 IS NULL
    OR municipalities_500_1999 IS NULL
    OR municipalities_2000_9999 IS NULL
    OR municipalities_over_10000 IS NULL
    OR cities IS NULL
    OR urban_ratio IS NULL
    OR avg_salary IS NULL
    OR unemployment_95 IS NULL
    OR unemployment_96 IS NULL
    OR entrepreneurs_per_1000 IS NULL
    OR crimes_95 IS NULL
    OR crimes_96 IS NULL;

-- trans
SELECT * FROM trans
WHERE trans_id IS NULL
    OR account_id IS NULL
    OR amount IS NULL
    OR balance IS NULL;


-- 2. VIEW CLIENT 
DROP VIEW IF EXISTS client_clean;
--
CREATE OR REPLACE VIEW client_clean AS 
SELECT 
	c.client_id,
    c.district_id,
	c.birth_number,
    d.district_name,
    d.region,
	CASE
    	WHEN SUBSTRING(birth_number, 3, 2)::INT > 50
    	THEN TO_DATE(
		'19' || SUBSTRING(birth_number, 1, 2) ||
		LPAD((SUBSTRING(birth_number, 3, 2)::INT - 50)::TEXT, 2, '0') || 
		SUBSTRING(birth_number, 5, 2), 'YYYYMMDD')
    	ELSE TO_DATE('19' || SUBSTRING(birth_number, 1, 6), 'YYYYMMDD')
	END AS birth_date,
	CASE 
		WHEN SUBSTRING(birth_number, 3, 2)::INT > 50 THEN 'female' ELSE 'male' 
	END AS gender 
FROM client c
JOIN district d ON c.district_id = d.district_id;


--3. VIEW LOAN
DROP VIEW IF EXISTS loan_clean;
--
CREATE OR REPLACE VIEW loan_clean AS
SELECT 
    loan_id,
    account_id,
    TO_DATE(date_raw, 'YYMMDD') AS loan_date,
    amount,
    duration,
    payments,
    status,
    CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END AS is_default,
    CASE status
        WHEN 'A' THEN 'Closed - Good'
        WHEN 'B' THEN 'Closed - Default'
        WHEN 'C' THEN 'Running - Good'
        WHEN 'D' THEN 'Running - Default'
    END AS loan_status
FROM loan;

