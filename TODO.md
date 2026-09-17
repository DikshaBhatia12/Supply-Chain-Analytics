# 📝 TODO — Build This Project From Scratch (Beginner Guide)

This file is written for someone who has never touched this project before.
No prior context needed — just follow the steps in order.

---

## 1. What Is This Project, In Simple Words?

A company ships orders to customers all over the world. Some orders arrive
late, some arrive incomplete, some never arrive at all. Nobody had a clear
picture of **how bad the problem actually was** or **where it was worst**.

This project answers that using real shipping data:
- Cleans up a messy spreadsheet of 180,000+ orders
- Loads it into a proper database
- Builds a dashboard that shows, at a glance: which shipping method is
  worst, which regions have the most problems, and whether things are
  getting better or staying the same over time

---

## 2. How We Did It (Simple Version)

Think of it as 4 steps, each one feeding the next:

1. **Excel** — First look at the raw data. Check what's missing, what looks
   wrong, get a feel for the numbers.
2. **Python** — Clean the data properly (fix formatting, calculate things
   like "was this order late?"), and save a clean version.
3. **MySQL (a database)** — Load the clean data in, organize it into
   proper tables, and write queries that calculate the key numbers.
4. **Power BI** — Build an interactive dashboard on top of the database so
   anyone can click around and explore the numbers visually.

## 3. What We Found (Simple Version)

- Only about **41 out of every 100 orders** arrive on time. That's bad —
  most companies aim for 85+ out of 100.
- **First Class shipping** (the "premium" option) is actually the
  **worst** performer — it misses its promised delivery date on
  **every single order**, in every region.
- **Standard Class** (the cheapest option) is actually the **most
  reliable** one.
- This isn't a one-time bad month — it's been like this for **3 years
  straight**, meaning it's a real structural problem, not bad luck.

---

## 4. ✅ WHAT TO DO — Step-by-Step Guide

Go through these in order. Don't skip ahead — each step needs the one
before it.

### ☐ Step 1: Install the tools you need

- [ ] Install **Python** (3.8 or newer) — [python.org](https://www.python.org/downloads/)
- [ ] Install **MySQL** (8.0 or newer) — [dev.mysql.com](https://dev.mysql.com/downloads/mysql/)
- [ ] Install **Power BI Desktop** (free) — [powerbi.microsoft.com](https://powerbi.microsoft.com/desktop/)
- [ ] Install the **MySQL Connector/NET** driver (Power BI needs this to
      talk to MySQL) — search "MySQL Connector NET download" and install it

### ☐ Step 2: Get the raw data

- [ ] Go to the [Kaggle dataset page](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)
- [ ] Download the CSV file
- [ ] Rename it to exactly: `DataCoSupplyChainDataset.csv`
- [ ] Put it inside the project's `data/` folder

### ☐ Step 3: Clean the data with Python

- [ ] Open a terminal in the project folder
- [ ] Run: `pip install -r python/requirements.txt`
- [ ] Open the notebook: `python/Supply chain - Data Cleaning and EDA.ipynb`
- [ ] Run every cell from top to bottom (in Jupyter: "Run All")
- [ ] Check that a new file appeared: `data/supplychain_clean.csv`

### ☐ Step 4: Set up MySQL

- [ ] Open a terminal
- [ ] Run this once (lets MySQL load files from your computer):
  ```sql
  SET GLOBAL local_infile = 1;
  ```
- [ ] Open `sql/03_bulk_insert.sql` in a text editor and change this line:
  ```
  LOAD DATA LOCAL INFILE '/path/to/supplychain_clean.csv'
  ```
  to point at the real location of the file from Step 3

### ☐ Step 5: Build the database (run these in order — don't skip any)

- [ ] `mysql -u root -p --local-infile=1 < sql/01_create_database.sql`
- [ ] `mysql -u root -p --local-infile=1 < sql/02_staging_table.sql`
- [ ] `mysql -u root -p --local-infile=1 supplychaindb < sql/03_bulk_insert.sql`
- [ ] `mysql -u root -p --local-infile=1 supplychaindb < sql/04_dimension_tables.sql`
- [ ] `mysql -u root -p --local-infile=1 supplychaindb < sql/05_fact_table.sql`
- [ ] `mysql -u root -p --local-infile=1 supplychaindb < sql/06_validation.sql`
- [ ] `mysql -u root -p --local-infile=1 supplychaindb < sql/07_kpi_views.sql`
- [ ] `mysql -u root -p --local-infile=1 supplychaindb < sql/08_view_verification.sql`

*(It'll ask for your MySQL password each time — that's normal. If you set
no password when installing MySQL, drop the `-p` flag.)*

- [ ] Check the last step printed 6 view names with no errors — that means
      everything built correctly

### ☐ Step 6: Connect the dashboard

- [ ] Open `power_bi/Supply_Chain_Dashboard.pbix` in Power BI Desktop
- [ ] Go to **Home → Transform data → Data source settings**
- [ ] Click **Change Source**
- [ ] Enter Server: `localhost`, Database: `supplychaindb`
- [ ] Click **Refresh** on the Home tab

### ☐ Step 7: Check it worked

- [ ] Look at Page 1 — you should see numbers like OTD ~40.9%, Revenue ~$36.8M
- [ ] Click through all 4 pages — slicers/filters should work when clicked
- [ ] If Page 4 (Trend Analysis) shows an error, check **Model view** for a
      table called `DIM_Month` — it should rebuild itself automatically,
      but this is the one part worth double-checking by hand

---

## 5. If Something Breaks

| Problem | What it usually means |
|---|---|
| `Loading local data is disabled` | You skipped the `SET GLOBAL local_infile = 1;` step |
| `Access denied` when running mysql commands | Wrong password, or you need the `-p` flag |
| A SQL script errors out partway | You ran them out of order — always 01 → 08 |
| Power BI won't show "MySQL database" as an option | The MySQL Connector/NET driver isn't installed |
| Numbers look completely different from the README | Make sure Step 2's CSV is the real, complete Kaggle file — not a partial download |

---

That's the whole thing. Once Step 7 checks out, you've built the entire
project yourself, from a raw spreadsheet to a working dashboard.
