# Czech Banking Data — SQL Analysis

SQL analysis of a real Czech bank's data (1993-1998, PKDD'99 dataset).
Credit risk, customer behaviour and transaction patterns in PostgreSQL.
A portfolio project demonstrating CTEs, window functions, views and RFM segmentation.

## The data

Anonymized data from a real Czech bank: 8 tables, just over a million transactions,
4,500 accounts, 682 loans across 77 districts.

## Key findings

- **Loan size drives risk far more than loan term.** Loans above 200k default
  almost 5x more often than loans under 50k (approx. 19% vs 4%), while duration barely
  changes the default rate.

- **Card ownership separates good and bad borrowers.** Clients without a card
  default around 5x more often than card holders (approx. 11% vs 2%) though most
  clients have no card, so this is a correlation worth investigating, not proof.

- **Transactions are strongly seasonal.** Volume jumps 30-40% every June and
  December and drops by a similar amount in February, driven largely by
  recurring semi-annual payments.

- **The customer base hit a ceiling.** Active accounts grew steadily until late
  1997, then flattened around 4,480, the bank effectively stopped acquiring
  new customers.

## How to run

1. Download the dataset from the source link below and unzip the CSVs.
2. In `02_load_tables.sql`, replace the file paths (`D:/Studying/banking_analytics/...`) with the path to your CSVs.
3. Run the files in order (01 -> 07) in pgAdmin or psql.

Files 01–03 build the schema, load data and create the views / 04–07 contain the analysis.

Source: https://relational.fel.cvut.cz/dataset/Financial

## Files

- `01_create_tables.sql` — schema for all 8 tables
- `02_load_tables.sql` — loading the CSVs
- `03_data_prep.sql` — null checks, date conversion, the views used everywhere
- `04_credit_risk.sql` — default rates by amount, duration, region, card type
- `05_customer_value.sql` — RFM segmentation, cross-sell targets, dormant accounts
- `06_transactions.sql` — cash flow, seasonality, anomaly detection
- `07_advanced.sql` — window-function heavy queries

Run in order. Each file has the business questions and my findings as comments inside.


## Tools

PostgreSQL 18, written in pgAdmin.
