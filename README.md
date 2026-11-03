# E-Commerce-Data-Integrity-
An investigation of a four-table synthetic e-commerce dataset (customers, orders, order items, returns) for data quality and integrity problems. The same investigation is done twice, once in **SQL Server (T-SQL)** and once in **Python (pandas)**, so the two approaches can be compared.
# E-commerce Data Integrity Investigation

An investigation of a four-table synthetic e-commerce dataset (customers, orders, order items, returns) for data quality and integrity problems. The same investigation is done twice, once in **SQL Server (T-SQL)** and once in **Python (pandas)**, so the two approaches can be compared.

## Summary of findings

| # | Issue | Table | Rows affected | How it was handled |
|---|-------|-------|---------------|--------------------|
| 1 | Missing `customer_id` | orders | 25 | Set to `0` as an "unknown customer" placeholder so the rows are kept; documented rather than deleted |
| 2 | Duplicate orders (exact duplicate rows) | orders | 5 | Removed, keeping one row per `order_id` |
| 3 | Orphaned returns (`order_id` has no matching order) | returns | 4 (return IDs 91-94) | Isolated into a separate table/DataFrame for review; excluded from joins |
| 4 | Return dated before the order date | returns / orders | 42 of 90 matched returns | Flagged, not corrected. The correct date cannot be known from this data |
| 5 | Inconsistent `region` values (casing, "SE"/"SW" abbreviations) | customers | Standardized to 5 regions | Standardized to Northeast, Southeast, Midwest, Southwest, West |
| 6 | Dates stored as text | orders, customers, returns | all rows | Converted to date type in pandas |
| 7 | Data model gap: returns cannot be linked to specific order items | returns / order_items | n/a | See "Limitation" below |

No missing values or duplicates were found in `customers`, `order_items` or `returns`.

### Limitation: "most returned product" cannot be answered reliably

`returns` links to `orders`, but not to `order_items`. An order with several items therefore cannot say *which* item was returned. Joining returns to order items on `order_id` counts every item in a returned order, which overstates every product. I report this as a data model finding with a recommendation (add `order_item_id` to `returns`) instead of presenting the misleading ranking as a result.

## Not yet investigated

- Negative `quantity` values in `order_items` (8 rows)
- Whether `return_reason_desc` is consistent with `return_type`

## Files

| File | What it is |
|------|------------|
| `ecomm.sql` | T-SQL investigation: null checks, duplicate checks, cleanup, orphan and date checks |
| `ecomm2.ipynb` | The same investigation in pandas |
| `ecommerce_data.xlsx` | The dataset, one table per sheet |
| `data_dictionary.md` | Column descriptions and notes on the data |

## How to run

**SQL Server:** Load the four tables into a database, then run `ecomm.sql` in SSMS section by section. Each section ends with a comment stating the result.

**Python:** Requires Python 3 with `pandas` and `numpy`. Edit the file paths in the second notebook cell to point to your copy of the four CSV files, then run the notebook top to bottom.

## Tools

SQL Server / SSMS (CTEs, `ROW_NUMBER()`, anti-joins, dynamic SQL with `STRING_AGG`), Python 3, pandas, Jupyter, Excel.

## About the data

All data is synthetic and contains no real customer information. It was generated with the help of an AI assistant (Claude) for practice. The data-quality problems in it were planted on purpose, and the investigation, queries, analysis and decisions are my own.

## Decisions worth noting

- **Nulls were kept, not deleted.** Deleting 25 orders would remove real sales from any revenue totals. Setting `customer_id` to `0` keeps them while marking them clearly as unattributed.
- **Flag vs. fix.** Return dates before order dates were flagged but not changed, since guessing the correct date would be inventing data.
- **Duplicates were removed with `ROW_NUMBER()`** partitioned by `order_id`, keeping the first row.
