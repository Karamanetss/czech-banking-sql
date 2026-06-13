-- district 
COPY district
FROM 'D:/Studying/banking_analytics/district.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250', NULL '?');

-- account
COPY account (account_id, district_id, frequency, date_raw)
FROM 'D:/Studying/banking_analytics/account.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');

-- client
COPY client (client_id, birth_number, district_id)
FROM 'D:/Studying/banking_analytics/client.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');

-- disp
COPY disp (disp_id, client_id, account_id, disp_type)
FROM 'D:/Studying/banking_analytics/disp.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');

-- card
COPY card (card_id, disp_id, card_type, issued)
FROM 'D:/Studying/banking_analytics/card.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');

-- loan
COPY loan (loan_id, account_id, date_raw, amount, duration, payments, status)
FROM 'D:/Studying/banking_analytics/loan.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');

-- order
COPY "order" (order_id, account_id, bank_to, account_to, amount, k_symbol)
FROM 'D:/Studying/banking_analytics/order.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');

-- trans
COPY trans (trans_id, account_id, date_raw, trans_type, operation, amount, balance, k_symbol, bank, account)
FROM 'D:/Studying/banking_analytics/trans.csv'
WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1250');
