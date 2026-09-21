-- Dialect: PostgreSQL

WITH daily_revenue AS (
  SELECT 
    app_id,
    DATE(event_time) AS event_day,
    SUM(revenue_usd) AS daily_rev,
  FROM clean_events
  GROUP BY app_id, DATE(event_time)
)

SELECT
  app_id,
  event_day,
  daily_rev as daily_revenue
  SUM(daily_rev) OVER (PARTITION BY app_id ORDER BY event_day) AS running_total_revenue,
  AVG(daily_rev) OVER (
    PARTITION BY app_id ORDER BY event_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS moving_avg_7d,
  (daily_rev - LAG(daily_rev) OVER (PARTITION BY app_id ORDER BY event_day))  -- current - prev
  / NULLIF(LAG(daily_rev) OVER (PARTITION BY app_id ORDER BY event_day), 0) * 100.0 AS dod_change_pct
FROM daily_revenue;
