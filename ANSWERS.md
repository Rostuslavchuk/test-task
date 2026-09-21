task_2_1.sql
If we have exactly the same values in the ingested_at field, SQL may choose a record randomly. In this case, the result will not be deterministic. To avoid this, we need to add more fields for sorting. In this case, I added event_time.

task_2_2.sql
Yes, missing days matter significantly. The window function ROWS BETWEEN 6 PRECEDING counts physical rows in the result set, not calendar days. If an app has no events for two days, the function will reach back into the previous week to find 7 rows, distorting the 7-day timeframe. To fix this, I would generate a "date spine" (a table or CTE containing every continuous calendar day using generate_series or a calendar dimension) and LEFT JOIN the daily aggregated revenue to it. Missing days would be filled with a revenue of 0 using COALESCE(). Then, the window function would evaluate exactly 7 calendar days. Late-arriving rows are absorbed by the replay window.

task_2_3.sql
I used a FULL OUTER JOIN to merge revenue and cost data. Campaigns with cost but no revenue indicate tracked spend that either hasn't converted yet, failed to track properly (broken attribution), or was brand-awareness focused. Campaigns with revenue but no cost represent organic traffic, viral lift, late-arriving conversions attributed to closed campaigns, or incomplete cost ingestion from the ad network. Division by zero for ROAS is handled via a CASE statement, returning NULL when cost is zero, preventing query failure while accurately reflecting an undefined ROAS. Late-arriving rows are absorbed by the replay window.


Block 4: Data Modeling
4.1 
I would use the Star Schema architecture. It is very convenient for data analysts because they can get all the data they need with just one simple JOIN. The raw events would be in the central Fact table, and the details (like users, apps, and marketing campaigns) would be in the Dimension tables.

4.2
If a user changes their country, we cannot just overwrite the old value. If we do, all their past purchases will be counted for the new country, and historical reports will be broken.
To solve this, I would use a method called SCD Type 2. We don't update the old row; instead, we close it by setting a valid_to date, and we create a new row for this user with a valid_from date. This way, we keep the full history safe.

4.3
To a marketing manager: Think of idempotency like an elevator button. Whether you press it once or ten times, only one elevator arrives. In data, it means we can run the same pipeline script multiple times safely, and it will never create duplicate reports or mess up the final numbers.
To an engineer: A simple INSERT ... SELECT is dangerous because running it twice will just append the same data again, creating duplicates. To make it idempotent, we usually use an UPSERT logic (INSERT ... ON CONFLICT DO UPDATE) or a "Delete-Write" pattern (deleting the target day's partition before inserting the new batch).

4.4
My pipeline filters new incoming rows using ingested_at, so it will successfully pick up the late event on Thursday. It will then insert it into the target table with the original Monday event_time.

Block 5:
How to debug a sudden drop in revenue on a dashboard:**
If an analyst reports missing revenue, I would check the data step by step:
1. Check the source data:** I would check if we received the raw CSV files for yesterday. Maybe the third-party sender had a problem.
2. Check the pipeline logs:** I would check if the data cleaning job failed. I would also check the `quarantined_events` folder to see if good data was moved there by mistake.
3. Check the database:** I would run a simple SQL query to check the number of rows and total revenue for yesterday. If the numbers are correct, the pipeline is working correctly.
4. Check the dashboard:** If the database is correct, the problem may be in the dashboard. For example, it may use the wrong timezone or use `ingested_at` instead of `event_time`.
