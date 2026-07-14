# Pipeline Design Notes

## Watermark column choice per table
- **orders → order_date**: represents when the transaction happened, a natural incremental signal.
- **loans → loan_date**: same reasoning, marks when the loan record was created.
- **reviews → created_at**: timestamp of when the review was submitted.
- **customers → joined_on**: account creation date acts as a reasonable proxy for "when this row entered our system."
- **books → no reliable watermark exists.** `published_on` is a business attribute (when the book was originally published), not a signal of when the row arrived in our system — some books have historical publish dates going back decades, which caused newly-generated rows to be silently skipped on the first load when filtered against a `2000-01-01` watermark. Books is treated as a small, slowly-changing reference table and is fully refreshed (`TRUNCATE` + reload) on every run instead of using a watermark filter.

## Trade-off in Silver quality rules
For `silver_orders`, `silver_loans`, and `silver_reviews`, rows with an invalid `customer_id` or `book_id` foreign key are rejected outright (logged to `silver_rejected_rows`) rather than loaded with a NULL reference. This keeps every row in Silver fully joinable and trustworthy for downstream Gold aggregation, at the cost of losing a small number of rows that might otherwise have been salvageable (e.g. a valid order with a mistyped book_id that could theoretically be corrected). Given the assignment's <5% rejection-rate healthy threshold, strict rejection was chosen over attempting a fuzzy-match repair, since repair logic adds complexity without a defined correctness guarantee.

## Hardest KPI: gold_kpi_return_compliance
This was the hardest to get right — not because of SQL complexity, but interpretation. The definition is "% of loans returned on or before due_date," which raises a denominator question: should loans still out (`return_date IS NULL`) count against the rate?
- Counting all loans (including not-yet-returned) as the denominator gave ~60%.
- Restricting to only completed loans (`return_date IS NOT NULL`) gave ~69.9%.

Either interpretation lands below the 75% target. Checking the dataset generation logic confirmed this is a property of the underlying data (on-time return probability is capped around 69-70% by design across all membership tiers), not a query bug. The final view uses the completed-loans-only denominator as the more defensible definition of "compliance," and correctly reports **FAIL** — the pipeline's job is to report the true KPI value, not to force a PASS.