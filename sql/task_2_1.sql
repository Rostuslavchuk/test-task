-- Dialect: PostgreSQL

WITH ranked_by_ingest AS (
  SELECT event_id, 
    user_id, 
    app_id, 
    event_name, 
    event_time,
    ingested_at, 
    country, 
    media_source, 
    campaign,
    revenue_usd, 
    is_test,
    ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY ingested_at DESC, event_time DESC) as rn
  FROM events_raw
  WHERE is_test = false
)

SELECT event_id, 
  user_id, 
  app_id, 
  event_name, 
  event_time,
  ingested_at, 
  country, 
  media_source, 
  campaign,
  revenue_usd, 
  is_test
FROM ranked_by_ingest
WHERE rn = 1;


