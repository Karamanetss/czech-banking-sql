# Czech Banking Data — SQL Analysis

SQL analysis of a real Czech bank's data from 1993-1998 (the PKDD'99 dataset).
Credit risk, customer behavior and transaction patterns, done in PostgreSQL.

## The data

Anonymized data from a real Czech bank: 8 tables, just over a million transactions,
4,500 accounts, 682 loans across 77 districts.

Source: https://relational.fel.cvut.cz/dataset/Financial

## Files

- `01_create_tables.sql` — schema for all 8 tables
- `02_load_data.sql` — loading the CSVs
- `03_data_prep.sql` — null checks, date conversion, the views used everywhere
- `04_credit_risk.sql` — default rates by amount, duration, region, card type
- `05_customer_value.sql` — RFM segmentation, cross-sell targets, dormant accounts
- `06_transactions.sql` — cash flow, seasonality, anomaly detection
- `07_advanced.sql` — window-function heavy queries

Run in order. Each file has the business questions and my findings as comments inside.

## Tools

PostgreSQL 18, written in pgAdmin.
