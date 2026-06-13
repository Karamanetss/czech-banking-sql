DROP TABLE IF EXISTS trans     CASCADE;
DROP TABLE IF EXISTS "order"   CASCADE;
DROP TABLE IF EXISTS loan      CASCADE;
DROP TABLE IF EXISTS card      CASCADE;
DROP TABLE IF EXISTS disp      CASCADE;
DROP TABLE IF EXISTS client    CASCADE;
DROP TABLE IF EXISTS account   CASCADE;
DROP TABLE IF EXISTS district  CASCADE;

CREATE TABLE district (
    district_id                 INT PRIMARY KEY,
    district_name               VARCHAR(25),
    region                      VARCHAR(25),
    population                  INT,
    municipalities_under_499    INT,
    municipalities_500_1999     INT,
    municipalities_2000_9999    INT,
    municipalities_over_10000   INT,
    cities                      INT,
    urban_ratio                 NUMERIC(5,2),
    avg_salary                  INT,
    unemployment_95             NUMERIC(5,2),  
    unemployment_96             NUMERIC(5,2),
    entrepreneurs_per_1000      INT,
    crimes_95                   INT,      
    crimes_96                   INT
);

CREATE TABLE account (
    account_id   INT PRIMARY KEY,
    district_id  INT,
    frequency    VARCHAR(30),  
    date_raw     CHAR(6)
);

CREATE TABLE client (
    client_id    INT PRIMARY KEY,
    birth_number VARCHAR(10),   
    district_id  INT
);

CREATE TABLE disp (
    disp_id    INT PRIMARY KEY,
    client_id  INT,
    account_id INT,
    disp_type  VARCHAR(20)      
);

CREATE TABLE card (
    card_id    INT PRIMARY KEY,
    disp_id    INT,
    card_type  VARCHAR(20),       
    issued     VARCHAR(20)        
);

CREATE TABLE loan (
    loan_id    INT PRIMARY KEY,
    account_id INT,
    date_raw   CHAR(6),
    amount     INT,
    duration   INT,       
    payments   NUMERIC(10,2),
    status     CHAR(1)         
);


CREATE TABLE "order" (
    order_id   INT PRIMARY KEY,
    account_id INT,
    bank_to    CHAR(2),
    account_to BIGINT,
    amount     NUMERIC(10,2),
    k_symbol   VARCHAR(20)
);

CREATE TABLE trans (
    trans_id   INT PRIMARY KEY,
    account_id INT,
    date_raw   CHAR(6),
    trans_type VARCHAR(10),     
    operation  VARCHAR(30),
    amount     NUMERIC(12,2),
    balance    NUMERIC(12,2),
    k_symbol   VARCHAR(20),
    bank       CHAR(2),       
    account    BIGINT        
);
